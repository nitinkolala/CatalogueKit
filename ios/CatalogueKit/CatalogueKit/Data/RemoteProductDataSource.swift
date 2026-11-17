import Foundation

/// Calls the catalogue backend. Knows the endpoint paths and wire format only.
nonisolated struct RemoteProductDataSource: Sendable {
    enum Path {
        static let featured = "products/featured"
    }

    let client: HTTPClient
    let baseURL: URL

    func featuredProducts() async throws -> [Product] {
        let data = try await client.data(from: baseURL.appending(path: Path.featured))
        let list = try JSONDecoder().decode(ProductListDTO.self, from: data)
        return try list.items.map { try $0.toDomain() }
    }
}
