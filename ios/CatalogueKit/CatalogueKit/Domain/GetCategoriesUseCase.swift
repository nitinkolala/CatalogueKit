import Foundation

nonisolated protocol GetCategoriesUseCase: Sendable {
    func execute() async throws -> [ProductCategory]
}

/// Returns every category the backend reports, in backend order.
nonisolated struct DefaultGetCategoriesUseCase: GetCategoriesUseCase {
    let repository: CategoryRepository

    func execute() async throws -> [ProductCategory] {
        try await repository.categories()
    }
}
