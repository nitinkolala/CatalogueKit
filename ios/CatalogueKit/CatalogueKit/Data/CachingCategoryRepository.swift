import Foundation

/// Cache-first wrapper around a category repository, with the same rules as the featured list:
/// a fresh saved copy is served without a network call, and when the backend fails the last saved copy is served,
/// even if it is stale. If nothing is saved and the backend fails, the error is thrown.
nonisolated struct CachingCategoryRepository: CategoryRepository {
    let remote: CategoryRepository
    let categoriesCache: KeyedDiskCache<[ProductCategory]>
    let productsCache: KeyedDiskCache<CategoryProducts>
    let timeToLive: TimeInterval
    let now: @Sendable () -> Date

    /// Key for the one saved category list.
    private static let allCategoriesKey = "all"

    init(
        remote: CategoryRepository,
        categoriesCache: KeyedDiskCache<[ProductCategory]>,
        productsCache: KeyedDiskCache<CategoryProducts>,
        timeToLive: TimeInterval = Constants.Cache.categoryTTL,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.categoriesCache = categoriesCache
        self.productsCache = productsCache
        self.timeToLive = timeToLive
        self.now = now
    }

    func categories() async throws -> [ProductCategory] {
        try await cachedOrFetch(
            cache: categoriesCache,
            key: Self.allCategoriesKey
        ) {
            try await remote.categories()
        }
    }

    func products(in category: ProductCategory) async throws -> CategoryProducts {
        try await cachedOrFetch(
            cache: productsCache,
            key: category.name
        ) {
            try await remote.products(in: category)
        }
    }

    private func cachedOrFetch<Value: Codable & Sendable>(
        cache: KeyedDiskCache<Value>,
        key: String,
        fetch: () async throws -> Value
    ) async throws -> Value {
        let current = now()
        if let saved = await cache.load(key: key),
           current.timeIntervalSince(saved.savedAt) < timeToLive {
            return saved.value
        }
        do {
            let fresh = try await fetch()
            await cache.save(fresh, key: key, at: current)
            return fresh
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let stale = await cache.load(key: key) {
                return stale.value
            }
            throw error
        }
    }
}
