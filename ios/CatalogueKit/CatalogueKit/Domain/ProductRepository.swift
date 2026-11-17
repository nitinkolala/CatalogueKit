import Foundation

/// Where the app gets products from. The implementation decides caching and the network source.
nonisolated protocol ProductRepository: Sendable {
    /// `forceRefresh` skips any cached copy and asks the backend.
    func featuredProducts(forceRefresh: Bool) async throws -> [Product]
}

nonisolated extension ProductRepository {
    func featuredProducts() async throws -> [Product] {
        try await featuredProducts(forceRefresh: false)
    }
}
