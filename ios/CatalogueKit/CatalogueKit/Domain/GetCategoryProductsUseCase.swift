import Foundation

nonisolated protocol GetCategoryProductsUseCase: Sendable {
    func execute(_ category: ProductCategory) async throws -> CategoryProducts
}

/// Returns a category's top-rated products followed by the rest.
nonisolated struct DefaultGetCategoryProductsUseCase: GetCategoryProductsUseCase {
    let repository: CategoryRepository

    func execute(_ category: ProductCategory) async throws -> CategoryProducts {
        try await repository.products(in: category)
    }
}
