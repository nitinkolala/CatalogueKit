import XCTest
@testable import CatalogueKit

@MainActor
final class HomeViewModelTests: XCTestCase {
    private struct FixedUseCase: GetFeaturedProductsUseCase {
        let result: Result<[Product], Error>
        func execute(forceRefresh: Bool) async throws -> FeaturedProducts {
            FeaturedProducts(items: try result.get(), isStale: false)
        }
    }

    /// A featured use case whose result can change between loads, to simulate a refresh that fails.
    private final class ScriptedFeaturedUseCase: GetFeaturedProductsUseCase, @unchecked Sendable {
        var result: Result<[Product], Error>
        var isStale = false
        init(_ result: Result<[Product], Error>) { self.result = result }
        func execute(forceRefresh: Bool) async throws -> FeaturedProducts {
            FeaturedProducts(items: try result.get(), isStale: isStale)
        }
    }

    private struct FixedCategoriesUseCase: GetCategoriesUseCase {
        let result: Result<[ProductCategory], Error>
        func execute() async throws -> [ProductCategory] { try result.get() }
    }

    private func viewModel(
        products: Result<[Product], Error> = .success([]),
        categories: Result<[ProductCategory], Error> = .success([])
    ) -> HomeViewModel {
        HomeViewModel(
            getFeaturedProducts: FixedUseCase(result: products),
            getCategories: FixedCategoriesUseCase(result: categories)
        )
    }

    func testLoadedStateWhenProductsArrive() async {
        let products = [TestData.product(id: 1)]
        let viewModel = viewModel(products: .success(products))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(products))
    }

    func testEmptyStateWhenNoProducts() async {
        let viewModel = viewModel(products: .success([]))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testFailedStateWhenUseCaseThrows() async {
        let viewModel = viewModel(products: .failure(StubError.offline))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    func testRefreshKeepsLoadedProductsWhenItFails() async {
        let products = [TestData.product(id: 1)]
        let viewModel = viewModel(products: .success(products))
        await viewModel.load()

        let failing = self.viewModel(products: .failure(StubError.offline))
        await failing.load()
        XCTAssertEqual(failing.state, .failed)

        await viewModel.load(forceRefresh: true)
        XCTAssertEqual(viewModel.state, .loaded(products))
    }

    func testCategoriesLoadInBackendOrder() async {
        let categories = [ProductCategory(name: "jewelery"), ProductCategory(name: "electronics")]
        let viewModel = viewModel(categories: .success(categories))

        await viewModel.load()

        XCTAssertEqual(viewModel.categories, .loaded(categories))
    }

    func testCategoriesHiddenWhenBackendReturnsNone() async {
        let viewModel = viewModel(categories: .success([]))

        await viewModel.load()

        XCTAssertEqual(viewModel.categories, .hidden)
    }

    func testSavedListServedWhileOfflineIsFlaggedStale() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        featured.isStale = true
        let viewModel = HomeViewModel(
            getFeaturedProducts: featured,
            getCategories: FixedCategoriesUseCase(result: .success([]))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))
        XCTAssertTrue(viewModel.featuredIsStale)
    }

    func testCategoriesShowRetryWhenRequestFails() async {
        let viewModel = viewModel(
            products: .success([TestData.product(id: 1)]),
            categories: .failure(StubError.offline)
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.categories, .failed)
        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))
    }

    func testRefreshFailureKeepsSavedProductsAndFlagsThemStale() async {
        let products = [TestData.product(id: 1)]
        let featured = ScriptedFeaturedUseCase(.success(products))
        let viewModel = HomeViewModel(
            getFeaturedProducts: featured,
            getCategories: FixedCategoriesUseCase(result: .success([]))
        )
        await viewModel.load()
        XCTAssertFalse(viewModel.featuredIsStale)

        featured.result = .failure(StubError.offline)
        await viewModel.load(forceRefresh: true)
        XCTAssertEqual(viewModel.state, .loaded(products))
        XCTAssertTrue(viewModel.featuredIsStale)

        featured.result = .success(products)
        await viewModel.load(forceRefresh: true)
        XCTAssertFalse(viewModel.featuredIsStale)
    }
}
