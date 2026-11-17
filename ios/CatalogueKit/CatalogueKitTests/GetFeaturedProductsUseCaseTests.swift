import XCTest
@testable import CatalogueKit

final class GetFeaturedProductsUseCaseTests: XCTestCase {
    func testReturnsOnlyTheFeaturedCount() async throws {
        let repository = StubProductRepository(result: .success((1...8).map { TestData.product(id: $0) }))
        let useCase = DefaultGetFeaturedProductsUseCase(repository: repository)

        let products = try await useCase.execute()

        XCTAssertEqual(products.count, Constants.Home.featuredCount)
        XCTAssertEqual(products.map(\.id), [1, 2, 3, 4, 5])
    }

    func testPropagatesRepositoryErrors() async {
        let repository = StubProductRepository(result: .failure(StubError.offline))
        let useCase = DefaultGetFeaturedProductsUseCase(repository: repository)

        do {
            _ = try await useCase.execute()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? StubError, .offline)
        }
    }
}
