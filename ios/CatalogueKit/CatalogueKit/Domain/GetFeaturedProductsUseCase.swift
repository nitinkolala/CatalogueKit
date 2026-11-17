import Foundation

nonisolated protocol GetFeaturedProductsUseCase: Sendable {
    func execute(forceRefresh: Bool) async throws -> FeaturedProducts
}

nonisolated extension GetFeaturedProductsUseCase {
    func execute() async throws -> FeaturedProducts {
        try await execute(forceRefresh: false)
    }
}

/// Returns the products to show on Home, in the order the backend sends them. The backend decides how many
/// (FEATURED_COUNT), so the count is not repeated in the app.
nonisolated struct DefaultGetFeaturedProductsUseCase: GetFeaturedProductsUseCase {
    let repository: ProductRepository

    func execute(forceRefresh: Bool) async throws -> FeaturedProducts {
        try await repository.featuredProducts(forceRefresh: forceRefresh)
    }
}
