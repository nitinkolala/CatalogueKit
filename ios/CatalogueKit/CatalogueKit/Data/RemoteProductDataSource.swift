import Foundation

/// Calls the catalogue backend. Knows the endpoint paths and wire format only.
nonisolated struct RemoteProductDataSource: Sendable {
    enum Path {
        static let featured = "products/featured"
        static let categories = "products/categories"
        static let search = "products/search"
    }

    let client: HTTPClient
    let baseURL: URL

    func featuredProducts() async throws -> [Product] {
        let data = try await client.data(from: baseURL.appending(path: Path.featured))
        let list = try JSONDecoder().decode(ProductListDTO.self, from: data)
        return try list.items.map { try $0.toDomain() }
    }

    func categories() async throws -> [ProductCategory] {
        let data = try await client.data(from: baseURL.appending(path: Path.categories))
        let list = try JSONDecoder().decode(CategoryListDTO.self, from: data)
        return list.items.map { ProductCategory(name: $0) }
    }

    /// Builds the query string by hand so `+`, `&` and `=` in the text are escaped too.
    /// `URLComponents` leaves `+` alone, and a server reads that as a space.
    func searchProducts(_ request: ProductSearchRequest) async throws -> ProductPage {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&="))
        func encode(_ value: String) -> String {
            value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        }
        var parameters = [
            "q=\(encode(request.query))",
            "offset=\(request.offset)",
            "limit=\(request.limit)",
        ]
        if let category = request.category {
            parameters.append("category=\(encode(category.name))")
        }
        let endpoint = baseURL.appending(path: Path.search).absoluteString
        guard let url = URL(string: "\(endpoint)?\(parameters.joined(separator: "&"))") else {
            throw HTTPError.invalidResponse
        }
        let data = try await client.data(from: url)
        let page = try JSONDecoder().decode(ProductPageDTO.self, from: data)
        return try page.toDomain()
    }

    func categoryProducts(_ category: ProductCategory) async throws -> CategoryProducts {
        let url = baseURL.appending(path: Path.categories).appending(path: category.name)
        let data = try await client.data(from: url)
        let page = try JSONDecoder().decode(CategoryProductsDTO.self, from: data)
        return try page.toDomain()
    }
}
