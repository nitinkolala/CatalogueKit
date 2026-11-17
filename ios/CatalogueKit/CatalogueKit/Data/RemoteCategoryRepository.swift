import Foundation

/// Category repository backed by the catalogue backend. Each call asks the backend;
/// `CachingCategoryRepository` wraps it to add the saved copy.
nonisolated struct RemoteCategoryRepository: CategoryRepository {
    let remote: RemoteProductDataSource

    func categories() async throws -> [ProductCategory] {
        try await remote.categories()
    }

    func products(in category: ProductCategory) async throws -> CategoryProducts {
        try await remote.categoryProducts(category)
    }
}
