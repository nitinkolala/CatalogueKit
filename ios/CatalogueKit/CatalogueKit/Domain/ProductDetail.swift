import Foundation

/// Why a product could not be loaded, in terms the product page can explain.
nonisolated enum ProductLoadError: Error, Equatable, Sendable {
    case offline
    case notFound
    case service
}

/// Where a single product comes from. The implementation decides the network source.
nonisolated protocol ProductDetailRepository: Sendable {
    func product(id: Int) async throws -> Product
}

nonisolated protocol GetProductDetailUseCase: Sendable {
    func execute(id: Int) async throws -> Product
}

/// Loads the latest copy of one product through the repository.
nonisolated struct DefaultGetProductDetailUseCase: GetProductDetailUseCase {
    let repository: ProductDetailRepository

    func execute(id: Int) async throws -> Product {
        try await repository.product(id: id)
    }
}

/// Stock status shown on the product page. The label always includes text, not just colour.
nonisolated enum StockStatus: Equatable, Sendable {
    case inStock
    case outOfStock

    init(available: Bool) {
        self = available ? .inStock : .outOfStock
    }
}
