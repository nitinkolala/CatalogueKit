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
}
