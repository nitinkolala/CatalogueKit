import XCTest
@testable import CatalogueKit

final class GetFeaturedProductsUseCaseTests: XCTestCase {
    func testKeepsTheOrderTheBackendSends() async throws {
        let repository = StubProductRepository(result: .success([4, 2, 9, 1, 7].map { TestData.product(id: $0) }))
        let useCase = DefaultGetFeaturedProductsUseCase(repository: repository)

        let products = try await useCase.execute()

        XCTAssertEqual(products.items.map(\.id), [4, 2, 9, 1, 7])
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
