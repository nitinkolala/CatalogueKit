import Foundation

/// Featured products plus whether they are the last saved copy, served because the backend could not be reached.
nonisolated struct FeaturedProducts: Equatable, Sendable {
    let items: [Product]
    let isStale: Bool
}

/// Where the app gets products from. The implementation decides caching and the network source.
nonisolated protocol ProductRepository: Sendable {
    /// `forceRefresh` skips any cached copy and asks the backend.
    func featuredProducts(forceRefresh: Bool) async throws -> FeaturedProducts
}

nonisolated extension ProductRepository {
    func featuredProducts() async throws -> FeaturedProducts {
        try await featuredProducts(forceRefresh: false)
    }
}
