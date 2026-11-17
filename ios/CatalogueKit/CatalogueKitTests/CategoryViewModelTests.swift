import XCTest
@testable import CatalogueKit

@MainActor
final class CategoryViewModelTests: XCTestCase {
    private struct FixedCategoryProductsUseCase: GetCategoryProductsUseCase {
        let result: Result<CategoryProducts, Error>
        func execute(_ category: ProductCategory) async throws -> CategoryProducts { try result.get() }
    }

    private let category = ProductCategory(name: "electronics")

    func testLoadedStateShowsTopRatedThenMore() async {
        let page = CategoryProducts(topRated: [TestData.product(id: 1)], more: [TestData.product(id: 2)])
        let viewModel = CategoryViewModel(
            category: category,
            getCategoryProducts: FixedCategoryProductsUseCase(result: .success(page))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(page))
    }

    func testEmptyStateWhenCategoryHasNoProducts() async {
        let viewModel = CategoryViewModel(
            category: category,
            getCategoryProducts: FixedCategoryProductsUseCase(result: .success(CategoryProducts(topRated: [], more: [])))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testFailedStateWhenRequestThrows() async {
        let viewModel = CategoryViewModel(
            category: category,
            getCategoryProducts: FixedCategoryProductsUseCase(result: .failure(StubError.offline))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    // MARK: - Loading on appearance

    /// Counts calls and answers from a result the test can change between calls.
    private final class CountingCategoryProductsUseCase: GetCategoryProductsUseCase, @unchecked Sendable {
        var result: Result<CategoryProducts, Error>
        private(set) var calls = 0

        init(result: Result<CategoryProducts, Error>) {
            self.result = result
        }

        func execute(_ category: ProductCategory) async throws -> CategoryProducts {
            calls += 1
            return try result.get()
        }
    }

    func testAppearingAgainAfterALoadDoesNotReload() async {
        let page = CategoryProducts(topRated: [TestData.product(id: 1)], more: [])
        let useCase = CountingCategoryProductsUseCase(result: .success(page))
        let viewModel = CategoryViewModel(category: category, getCategoryProducts: useCase)

        await viewModel.loadIfNeeded()
        // Back from a product page.
        await viewModel.loadIfNeeded()

        XCTAssertEqual(useCase.calls, 1)
        XCTAssertEqual(viewModel.state, .loaded(page))
    }

    func testAppearingAgainAfterAFailureLoadsAgain() async {
        let page = CategoryProducts(topRated: [TestData.product(id: 1)], more: [])
        let useCase = CountingCategoryProductsUseCase(result: .failure(StubError.offline))
        let viewModel = CategoryViewModel(category: category, getCategoryProducts: useCase)

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .failed)

        useCase.result = .success(page)
        await viewModel.loadIfNeeded()

        XCTAssertEqual(useCase.calls, 2)
        XCTAssertEqual(viewModel.state, .loaded(page))
    }

    func testRetryStillLoadsAfterASuccessfulLoad() async {
        let useCase = CountingCategoryProductsUseCase(result: .success(CategoryProducts(topRated: [], more: [])))
        let viewModel = CategoryViewModel(category: category, getCategoryProducts: useCase)

        await viewModel.loadIfNeeded()
        await viewModel.load()

        XCTAssertEqual(useCase.calls, 2, "An explicit load always asks again")
    }

    func testCancelledLoadPutsBackThePreviousStateAndLoadsAgainNextTime() async {
        let page = CategoryProducts(topRated: [TestData.product(id: 1)], more: [])
        let useCase = CountingCategoryProductsUseCase(result: .failure(CancellationError()))
        let viewModel = CategoryViewModel(category: category, getCategoryProducts: useCase)

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loading, "A cancelled load is not shown as a failure")

        useCase.result = .success(page)
        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded(page))
    }
}
