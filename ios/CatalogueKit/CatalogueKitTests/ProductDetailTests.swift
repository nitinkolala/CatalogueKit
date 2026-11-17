import XCTest
@testable import CatalogueKit

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    /// Answers each load from a handler, so one test can fail first and then succeed.
    struct FakeDetail: GetProductDetailUseCase {
        let handler: @Sendable (Int) async throws -> Product

        func execute(id: Int) async throws -> Product {
            try await handler(id)
        }
    }

    private let seed = TestData.product(id: 5, rate: 4.2)

    private func makeViewModel(_ handler: @escaping @Sendable (Int) async throws -> Product) -> ProductDetailViewModel {
        ProductDetailViewModel(product: seed, getProductDetail: FakeDetail(handler: handler))
    }

    func testStartsWithTheTappedProductOnScreen() {
        let viewModel = makeViewModel { _ in self.seed }

        XCTAssertEqual(viewModel.product, seed)
        XCTAssertEqual(viewModel.phase, .loaded)
    }

    func testReloadReplacesTheProductWithTheLatestCopy() async {
        let latest = TestData.product(id: 5, rate: 4.9)
        let viewModel = makeViewModel { _ in latest }

        await viewModel.load()

        XCTAssertEqual(viewModel.product, latest)
        XCTAssertEqual(viewModel.phase, .loaded)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testNotFoundClearsTheProductAndSaysSo() async {
        let viewModel = makeViewModel { _ in throw ProductLoadError.notFound }

        await viewModel.load()

        XCTAssertNil(viewModel.product)
        XCTAssertEqual(viewModel.phase, .notFound)
    }

    func testOfflineKeepsTheContentOnScreen() async {
        let viewModel = makeViewModel { _ in throw ProductLoadError.offline }

        await viewModel.load()

        XCTAssertEqual(viewModel.product, seed)
        XCTAssertEqual(viewModel.phase, .failed(.offline))
    }

    func testServiceErrorKeepsTheContentOnScreen() async {
        let viewModel = makeViewModel { _ in throw ProductLoadError.service }

        await viewModel.load()

        XCTAssertEqual(viewModel.product, seed)
        XCTAssertEqual(viewModel.phase, .failed(.service))
    }

    func testRetryAfterAFailureRecovers() async {
        let calls = CallCounter()
        let latest = TestData.product(id: 5, rate: 4.9)
        let viewModel = makeViewModel { _ in
            let call = calls.value
            calls.increment()
            if call == 0 { throw ProductLoadError.offline }
            return latest
        }

        await viewModel.load()
        XCTAssertEqual(viewModel.phase, .failed(.offline))

        await viewModel.load()
        XCTAssertEqual(viewModel.phase, .loaded)
        XCTAssertEqual(viewModel.product, latest)
    }

    // MARK: - Loading on appearance

    func testAppearingAgainAfterARefreshDoesNotReload() async {
        let calls = CallCounter()
        let viewModel = makeViewModel { _ in
            calls.increment()
            return self.seed
        }

        await viewModel.loadIfNeeded()
        // Back from the Enquiry form.
        await viewModel.loadIfNeeded()

        XCTAssertEqual(calls.value, 1)
    }

    func testAppearingAgainAfterAFailureLoadsAgain() async {
        let calls = CallCounter()
        let latest = TestData.product(id: 5, rate: 4.9)
        let viewModel = makeViewModel { _ in
            let call = calls.value
            calls.increment()
            if call == 0 { throw ProductLoadError.offline }
            return latest
        }

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(calls.value, 2)
        XCTAssertEqual(viewModel.product, latest)
    }

    func testNotFoundIsNotLoadedAgainOnAppearance() async {
        let calls = CallCounter()
        let viewModel = makeViewModel { _ in
            calls.increment()
            throw ProductLoadError.notFound
        }

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(calls.value, 1)
        XCTAssertEqual(viewModel.phase, .notFound)
    }

    func testPullToRefreshStillLoadsAfterARefresh() async {
        let calls = CallCounter()
        let viewModel = makeViewModel { _ in
            calls.increment()
            return self.seed
        }

        await viewModel.loadIfNeeded()
        await viewModel.load()

        XCTAssertEqual(calls.value, 2, "Pull to refresh and Retry always ask again")
    }
}

final class StockStatusTests: XCTestCase {
    func testAvailableProductIsInStock() {
        XCTAssertEqual(StockStatus(available: true), .inStock)
    }

    func testUnavailableProductIsOutOfStock() {
        XCTAssertEqual(StockStatus(available: false), .outOfStock)
    }
}

final class DescriptionLengthTests: XCTestCase {
    func testShortDescriptionIsNotCollapsed() {
        XCTAssertFalse(DescriptionLength.isLong("A short description."))
    }

    func testExactlyTheLimitIsNotCollapsed() {
        let text = String(repeating: "a", count: Constants.ProductPage.descriptionCollapseLength)
        XCTAssertFalse(DescriptionLength.isLong(text))
    }

    func testOneCharacterOverTheLimitIsCollapsed() {
        let text = String(repeating: "a", count: Constants.ProductPage.descriptionCollapseLength + 1)
        XCTAssertTrue(DescriptionLength.isLong(text))
    }
}

final class RemoteProductDetailRepositoryTests: XCTestCase {
    private let baseURL = URL(string: "https://api.test")!

    private func repository(_ handler: @escaping @Sendable (URL) throws -> Data) -> RemoteProductDetailRepository {
        let remote = RemoteProductDataSource(client: StubHTTPClient(handler: handler), baseURL: baseURL)
        return RemoteProductDetailRepository(remote: remote)
    }

    func testDecodesTheProductFromTheItemEnvelope() async throws {
        let product = TestData.product(id: 9)
        let body = try JSONSerialization.data(withJSONObject: [
            "item": [
                "id": product.id,
                "title": product.title,
                "price": product.price,
                "description": product.description,
                "category": product.category,
                "imageUrl": product.imageURL.absoluteString,
                "available": product.available,
                "rating": ["rate": product.rating.rate, "count": product.rating.count],
            ],
        ])
        let repository = repository { url in
            XCTAssertEqual(url, self.baseURL.appending(path: "products/9"))
            return body
        }

        let loaded = try await repository.product(id: 9)

        XCTAssertEqual(loaded, product)
    }

    func testMissingProductMapsToNotFound() async {
        let repository = repository { _ in throw HTTPError.unexpectedStatus(404) }

        do {
            _ = try await repository.product(id: 9)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ProductLoadError, .notFound)
        }
    }

    func testNoNetworkMapsToOffline() async {
        let repository = repository { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await repository.product(id: 9)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ProductLoadError, .offline)
        }
    }

    func testServerErrorMapsToService() async {
        let repository = repository { _ in throw HTTPError.unexpectedStatus(500) }

        do {
            _ = try await repository.product(id: 9)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ProductLoadError, .service)
        }
    }
}
