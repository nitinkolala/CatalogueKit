import XCTest
@testable import CatalogueKit

final class RemoteCategoryRepositoryTests: XCTestCase {
    private let baseURL = URL(string: "https://api.test")!

    private func repository(handler: @escaping @Sendable (URL) throws -> Data) -> RemoteCategoryRepository {
        let remote = RemoteProductDataSource(client: StubHTTPClient(handler: handler), baseURL: baseURL)
        return RemoteCategoryRepository(remote: remote)
    }

    private func wireItem(_ product: Product) -> [String: Any] {
        [
            "id": product.id,
            "title": product.title,
            "price": product.price,
            "description": product.description,
            "category": product.category,
            "imageUrl": product.imageURL.absoluteString,
            "available": product.available,
            "rating": ["rate": product.rating.rate, "count": product.rating.count],
        ]
    }

    func testCategoriesDecodeInBackendOrder() async throws {
        let repository = repository { url in
            XCTAssertEqual(url, self.baseURL.appending(path: "products/categories"))
            return Data(#"{"items":["jewelery","electronics"]}"#.utf8)
        }

        let categories = try await repository.categories()

        XCTAssertEqual(categories.map(\.name), ["jewelery", "electronics"])
    }

    func testCategoryProductsDecodeTopRatedAndMore() async throws {
        let top = TestData.product(id: 1, rate: 4.9)
        let rest = TestData.product(id: 2, rate: 3.1)
        let body = try JSONSerialization.data(withJSONObject: [
            "topRated": [wireItem(top)],
            "more": [wireItem(rest)],
        ])
        let repository = repository { _ in body }

        let page = try await repository.products(in: ProductCategory(name: "electronics"))

        XCTAssertEqual(page.topRated, [top])
        XCTAssertEqual(page.more, [rest])
    }

    func testCategoryNameIsEncodedInTheRequestPath() async throws {
        let requested = CallCounter()
        let body = Data(#"{"topRated":[],"more":[]}"#.utf8)
        let repository = repository { url in
            requested.increment()
            XCTAssertTrue(url.absoluteString.hasSuffix("products/categories/men's%20clothing"), url.absoluteString)
            return body
        }

        _ = try await repository.products(in: ProductCategory(name: "men's clothing"))

        XCTAssertEqual(requested.value, 1)
    }
}
