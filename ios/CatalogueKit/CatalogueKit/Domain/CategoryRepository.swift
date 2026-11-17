import Foundation

/// Where the app gets categories and category products from.
nonisolated protocol CategoryRepository: Sendable {
    /// Categories in the order the backend sends them.
    func categories() async throws -> [ProductCategory]
    func products(in category: ProductCategory) async throws -> CategoryProducts
}
