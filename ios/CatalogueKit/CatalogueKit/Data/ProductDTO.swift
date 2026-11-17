import Foundation

/// Wire format of `GET /products/featured` and `GET /products` on the backend.
nonisolated struct ProductListDTO: Decodable, Sendable {
    let items: [ProductDTO]
}

nonisolated struct ProductDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let imageUrl: String
    /// Missing from older payloads; treated as available.
    let available: Bool?
    let rating: RatingDTO

    nonisolated struct RatingDTO: Decodable, Sendable {
        let rate: Double
        let count: Int
    }

    func toDomain() throws -> Product {
        guard let url = URL(string: imageUrl) else {
            throw ProductMappingError.invalidImageURL(imageUrl)
        }
        return Product(
            id: id,
            title: title,
            price: price,
            description: description,
            category: category,
            imageURL: url,
            available: available ?? true,
            rating: Product.Rating(rate: rating.rate, count: rating.count)
        )
    }
}

nonisolated enum ProductMappingError: Error, Equatable {
    case invalidImageURL(String)
}
