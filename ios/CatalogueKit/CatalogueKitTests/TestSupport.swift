import Foundation
@testable import CatalogueKit

enum TestData {
    static func product(id: Int, rate: Double = 4.0) -> Product {
        Product(
            id: id,
            title: "Product \(id)",
            price: 10,
            description: "Description \(id)",
            category: "category",
            imageURL: URL(string: "https://img.test/\(id).jpg")!,
            available: true,
            rating: Product.Rating(rate: rate, count: 10)
        )
    }

    /// Encodes products in the backend's wire format (`imageUrl`, nested `rating`).
    static func wireBody(_ products: [Product]) throws -> Data {
        let items: [[String: Any]] = products.map {
            [
                "id": $0.id,
                "title": $0.title,
                "price": $0.price,
                "description": $0.description,
                "category": $0.category,
                "imageUrl": $0.imageURL.absoluteString,
                "rating": ["rate": $0.rating.rate, "count": $0.rating.count],
            ]
        }
        return try JSONSerialization.data(withJSONObject: ["items": items])
    }

    static func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "featured.json")
    }
}

final class StubProductRepository: ProductRepository, @unchecked Sendable {
    var result: Result<[Product], Error>
    private(set) var callCount = 0

    init(result: Result<[Product], Error>) {
        self.result = result
    }

    func featuredProducts(forceRefresh: Bool) async throws -> [Product] {
        callCount += 1
        return try result.get()
    }
}

struct StubHTTPClient: HTTPClient {
    let handler: @Sendable (URL) throws -> Data

    func data(from url: URL) async throws -> Data {
        try handler(url)
    }
}

enum StubError: Error { case offline }

/// Thread-safe counter for stubs that run off the main actor.
final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() { value += 1 }
}
