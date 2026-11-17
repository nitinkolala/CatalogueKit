import Foundation

/// Wire format of `GET /products/categories` on the backend.
nonisolated struct CategoryListDTO: Decodable, Sendable {
    let items: [String]
}

/// Wire format of `GET /products/categories/:name` on the backend.
nonisolated struct CategoryProductsDTO: Decodable, Sendable {
    let topRated: [ProductDTO]
    let more: [ProductDTO]

    func toDomain() throws -> CategoryProducts {
        CategoryProducts(
            topRated: try topRated.map { try $0.toDomain() },
            more: try more.map { try $0.toDomain() }
        )
    }
}
