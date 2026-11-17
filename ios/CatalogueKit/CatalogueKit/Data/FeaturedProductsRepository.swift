import Foundation

/// Cache-first repository. Serves a fresh cached list when one exists, otherwise fetches from the backend.
/// If the backend is unreachable, it falls back to the last saved list, even if it is stale.
nonisolated struct FeaturedProductsRepository: ProductRepository {
    let remote: RemoteProductDataSource
    let cache: ProductsDiskCache
    let timeToLive: TimeInterval
    let now: @Sendable () -> Date

    init(
        remote: RemoteProductDataSource,
        cache: ProductsDiskCache,
        timeToLive: TimeInterval = Constants.Cache.featuredTTL,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.cache = cache
        self.timeToLive = timeToLive
        self.now = now
    }

    func featuredProducts(forceRefresh: Bool) async throws -> FeaturedProducts {
        let current = now()
        if !forceRefresh,
           let cached = await cache.load(),
           current.timeIntervalSince(cached.savedAt) < timeToLive {
            return FeaturedProducts(items: cached.products, isStale: false)
        }
        do {
            let fresh = try await remote.featuredProducts()
            await cache.save(fresh, at: current)
            return FeaturedProducts(items: fresh, isStale: false)
        } catch {
            if let stale = await cache.load() {
                return FeaturedProducts(items: stale.products, isStale: true)
            }
            throw error
        }
    }
}
