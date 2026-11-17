import XCTest
@testable import CatalogueKit

final class RemoteProductSearchRepositoryTests: XCTestCase {
    private let baseURL = URL(string: "https://api.test")!

    private func repository(handler: @escaping @Sendable (URL) throws -> Data) -> RemoteProductSearchRepository {
        let remote = RemoteProductDataSource(client: StubHTTPClient(handler: handler), baseURL: baseURL)
        return RemoteProductSearchRepository(remote: remote)
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

    private func request(query: String, category: ProductCategory? = nil) -> ProductSearchRequest {
        ProductSearchRequest(query: query, category: category, offset: 0, limit: 20)
    }

    func testQueryIsPercentEncodedSoSymbolsAccentsAndEmojiSurvive() async throws {
        let captured = CallCounter()
        let repository = repository { url in
            captured.increment()
            XCTAssertTrue(
                url.absoluteString.contains("q=caf%C3%A9%20%26%20%F0%9F%8D%8E"),
                url.absoluteString
            )
            return Data(#"{"items":[],"total":0,"hasMore":false}"#.utf8)
        }

        _ = try await repository.search(request(query: "café & 🍎"))

        XCTAssertEqual(captured.value, 1)
    }

    func testPlusSignIsEscapedSoTheServerDoesNotReadItAsASpace() async throws {
        let repository = repository { url in
            XCTAssertTrue(url.absoluteString.contains("q=a%2Bb"), url.absoluteString)
            return Data(#"{"items":[],"total":0,"hasMore":false}"#.utf8)
        }

        _ = try await repository.search(request(query: "a+b"))
    }

    func testPagingAndCategoryAreSentAsParameters() async throws {
        let repository = repository { url in
            XCTAssertTrue(url.absoluteString.contains("offset=20"), url.absoluteString)
            XCTAssertTrue(url.absoluteString.contains("limit=20"), url.absoluteString)
            XCTAssertTrue(url.absoluteString.contains("category=women%20clothing"), url.absoluteString)
            return Data(#"{"items":[],"total":0,"hasMore":false}"#.utf8)
        }

        _ = try await repository.search(
            ProductSearchRequest(
                query: "dress",
                category: ProductCategory(name: "women clothing"),
                offset: 20,
                limit: 20
            )
        )
    }

    func testResponseDecodesIntoAPage() async throws {
        let first = TestData.product(id: 1)
        let body = try JSONSerialization.data(withJSONObject: [
            "items": [wireItem(first)],
            "total": 3,
            "hasMore": true,
        ])
        let repository = repository { _ in body }

        let page = try await repository.search(request(query: "game"))

        XCTAssertEqual(page.items, [first])
        XCTAssertEqual(page.total, 3)
        XCTAssertTrue(page.hasMore)
    }

    func testNoNetworkMapsToOffline() async {
        let repository = repository { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await repository.search(request(query: "game"))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? SearchError, .offline)
        }
    }

    func testConnectionLostMapsToOffline() async {
        let repository = repository { _ in throw URLError(.networkConnectionLost) }

        do {
            _ = try await repository.search(request(query: "game"))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? SearchError, .offline)
        }
    }

    func testServerProblemMapsToService() async {
        let repository = repository { _ in throw HTTPError.unexpectedStatus(500) }

        do {
            _ = try await repository.search(request(query: "game"))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? SearchError, .service)
        }
    }

    func testCancelledRequestIsNotReportedAsAFailure() async {
        let repository = repository { _ in throw URLError(.cancelled) }

        do {
            _ = try await repository.search(request(query: "game"))
            XCTFail("Expected an error")
        } catch {
            XCTAssertTrue(error is CancellationError, "A cancelled search must not show a failure")
        }
    }
}
