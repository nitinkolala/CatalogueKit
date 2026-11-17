import Foundation

/// Wire format of `GET /products/search` on the backend. Extra fields such as `offset` and `limit` are ignored.
nonisolated struct ProductPageDTO: Decodable, Sendable {
    let items: [ProductDTO]
    let total: Int
    let hasMore: Bool

    func toDomain() throws -> ProductPage {
        ProductPage(
            items: try items.map { try $0.toDomain() },
            total: total,
            hasMore: hasMore
        )
    }
}
