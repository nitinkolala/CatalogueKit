import Foundation

nonisolated protocol GetFeaturedProductsUseCase: Sendable {
    func execute(forceRefresh: Bool) async throws -> [Product]
}

nonisolated extension GetFeaturedProductsUseCase {
    func execute() async throws -> [Product] {
        try await execute(forceRefresh: false)
    }
}

/// Returns the products to show on Home, capped at the Home featured count.
nonisolated struct DefaultGetFeaturedProductsUseCase: GetFeaturedProductsUseCase {
    let repository: ProductRepository

    func execute(forceRefresh: Bool) async throws -> [Product] {
        let products = try await repository.featuredProducts(forceRefresh: forceRefresh)
        return Array(products.prefix(Constants.Home.featuredCount))
    }
}
