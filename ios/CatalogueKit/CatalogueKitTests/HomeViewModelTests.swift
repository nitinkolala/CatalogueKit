import XCTest
@testable import CatalogueKit

@MainActor
final class HomeViewModelTests: XCTestCase {
    private struct FixedUseCase: GetFeaturedProductsUseCase {
        let result: Result<[Product], Error>
        func execute(forceRefresh: Bool) async throws -> [Product] { try result.get() }
    }

    func testLoadedStateWhenProductsArrive() async {
        let products = [TestData.product(id: 1)]
        let viewModel = HomeViewModel(getFeaturedProducts: FixedUseCase(result: .success(products)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(products))
    }

    func testEmptyStateWhenNoProducts() async {
        let viewModel = HomeViewModel(getFeaturedProducts: FixedUseCase(result: .success([])))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testFailedStateWhenUseCaseThrows() async {
        let viewModel = HomeViewModel(getFeaturedProducts: FixedUseCase(result: .failure(StubError.offline)))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    func testRefreshKeepsLoadedProductsWhenItFails() async {
        let products = [TestData.product(id: 1)]
        let viewModel = HomeViewModel(getFeaturedProducts: FixedUseCase(result: .success(products)))
        await viewModel.load()

        let failing = HomeViewModel(getFeaturedProducts: FixedUseCase(result: .failure(StubError.offline)))
        await failing.load()
        XCTAssertEqual(failing.state, .failed)

        await viewModel.load(forceRefresh: true)
        XCTAssertEqual(viewModel.state, .loaded(products))
    }
}
