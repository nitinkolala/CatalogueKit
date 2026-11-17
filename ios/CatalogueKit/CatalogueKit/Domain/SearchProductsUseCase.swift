import Foundation

nonisolated protocol SearchProductsUseCase: Sendable {
    func execute(_ request: ProductSearchRequest) async throws -> ProductPage
}

/// Runs one page of a product search through the repository.
nonisolated struct DefaultSearchProductsUseCase: SearchProductsUseCase {
    let repository: ProductSearchRepository

    func execute(_ request: ProductSearchRequest) async throws -> ProductPage {
        try await repository.search(request)
    }
}
