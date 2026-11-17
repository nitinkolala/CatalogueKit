import Foundation

/// Category repository backed by the catalogue backend. No local cache yet; each call asks the backend.
nonisolated struct RemoteCategoryRepository: CategoryRepository {
    let remote: RemoteProductDataSource

    func categories() async throws -> [ProductCategory] {
        try await remote.categories()
    }

    func products(in category: ProductCategory) async throws -> CategoryProducts {
        try await remote.categoryProducts(category)
    }
}
