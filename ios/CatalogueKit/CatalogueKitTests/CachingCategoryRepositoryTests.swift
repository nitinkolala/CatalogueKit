import XCTest
@testable import CatalogueKit

final class CachingCategoryRepositoryTests: XCTestCase {
    private let electronics = ProductCategory(name: "electronics")
    private let jewellery = ProductCategory(name: "jewelery")

    private func makeRepository(
        remote: FakeCategoryRepository,
        directory: URL = TestData.tempFile().deletingLastPathComponent(),
        now: @escaping @Sendable () -> Date,
        ttl: TimeInterval = 300
    ) -> CachingCategoryRepository {
        CachingCategoryRepository(
            remote: remote,
            categoriesCache: KeyedDiskCache(fileURL: directory.appending(path: "categories.json")),
            productsCache: KeyedDiskCache(fileURL: directory.appending(path: "category-products.json")),
            timeToLive: ttl,
            now: now
        )
    }

    private func products(_ ids: [Int]) -> CategoryProducts {
        CategoryProducts(topRated: ids.map { TestData.product(id: $0) }, more: [])
    }

    // MARK: - Categories

    func testFetchesCategoriesWhenNothingIsSaved() async throws {
        let remote = FakeCategoryRepository()
        remote.categoriesResult = .success([electronics, jewellery])
        let repository = makeRepository(remote: remote, now: { Date(timeIntervalSince1970: 0) })

        let result = try await repository.categories()

        XCTAssertEqual(result, [electronics, jewellery])
        XCTAssertEqual(remote.categoryCalls, 1)
    }

    func testServesFreshCategoriesWithoutCallingBackend() async throws {
        let remote = FakeCategoryRepository()
        remote.categoriesResult = .success([electronics])
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let repository = makeRepository(remote: remote, now: { clock.now })

        _ = try await repository.categories()
        clock.now = Date(timeIntervalSince1970: 60)
        let second = try await repository.categories()

        XCTAssertEqual(second, [electronics])
        XCTAssertEqual(remote.categoryCalls, 1)
    }

    func testRefetchesCategoriesAfterTimeToLive() async throws {
        let remote = FakeCategoryRepository()
        remote.categoriesResult = .success([electronics])
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let repository = makeRepository(remote: remote, now: { clock.now })

        _ = try await repository.categories()
        remote.categoriesResult = .success([electronics, jewellery])
        clock.now = Date(timeIntervalSince1970: 301)
        let result = try await repository.categories()

        XCTAssertEqual(result, [electronics, jewellery])
        XCTAssertEqual(remote.categoryCalls, 2)
    }

    func testServesSavedCategoriesWhenBackendFails() async throws {
        let remote = FakeCategoryRepository()
        remote.categoriesResult = .success([electronics])
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let directory = TestData.tempFile().deletingLastPathComponent()
        let repository = makeRepository(remote: remote, directory: directory, now: { clock.now })

        _ = try await repository.categories()
        remote.categoriesResult = .failure(StubError.offline)
        clock.now = Date(timeIntervalSince1970: 3_600)
        let result = try await repository.categories()

        XCTAssertEqual(result, [electronics], "The saved list is served when the backend is down, even after it expired")
    }

    func testThrowsWhenBackendFailsAndNothingIsSaved() async {
        let remote = FakeCategoryRepository()
        remote.categoriesResult = .failure(StubError.offline)
        let repository = makeRepository(remote: remote, now: { Date(timeIntervalSince1970: 0) })

        do {
            _ = try await repository.categories()
            XCTFail("Expected an error when there is nothing saved")
        } catch {
            XCTAssertEqual(error as? StubError, .offline)
        }
    }

    func testSavedCategoriesSurviveANewRepositoryInstance() async throws {
        let directory = TestData.tempFile().deletingLastPathComponent()
        let first = FakeCategoryRepository()
        first.categoriesResult = .success([electronics])
        _ = try await makeRepository(remote: first, directory: directory, now: { Date(timeIntervalSince1970: 0) })
            .categories()

        // A new instance reads the file from disk, as after an app restart.
        let second = FakeCategoryRepository()
        second.categoriesResult = .failure(StubError.offline)
        let result = try await makeRepository(remote: second, directory: directory, now: { Date(timeIntervalSince1970: 3_600) })
            .categories()

        XCTAssertEqual(result, [electronics])
        XCTAssertEqual(second.categoryCalls, 1, "The backend was asked, failed, and the file was used")
    }

    // MARK: - Category products

    func testServesFreshCategoryProductsWithoutCallingBackend() async throws {
        let remote = FakeCategoryRepository()
        remote.productsResult = .success(products([1, 2]))
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let repository = makeRepository(remote: remote, now: { clock.now })

        _ = try await repository.products(in: electronics)
        clock.now = Date(timeIntervalSince1970: 60)
        let second = try await repository.products(in: electronics)

        XCTAssertEqual(second, products([1, 2]))
        XCTAssertEqual(remote.productCalls, ["electronics"])
    }

    func testCategoryProductsAreSavedSeparatelyPerCategory() async throws {
        let remote = FakeCategoryRepository()
        let repository = makeRepository(remote: remote, now: { Date(timeIntervalSince1970: 0) })

        remote.productsResult = .success(products([1]))
        _ = try await repository.products(in: electronics)
        remote.productsResult = .success(products([9]))
        let jewelleryResult = try await repository.products(in: jewellery)
        remote.productsResult = .failure(StubError.offline)
        let electronicsResult = try await repository.products(in: electronics)

        XCTAssertEqual(jewelleryResult, products([9]))
        XCTAssertEqual(electronicsResult, products([1]), "Electronics is served from its own saved copy")
    }

    func testServesSavedCategoryProductsWhenBackendFails() async throws {
        let remote = FakeCategoryRepository()
        remote.productsResult = .success(products([1]))
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let repository = makeRepository(remote: remote, now: { clock.now })

        _ = try await repository.products(in: electronics)
        remote.productsResult = .failure(StubError.offline)
        clock.now = Date(timeIntervalSince1970: 3_600)
        let result = try await repository.products(in: electronics)

        XCTAssertEqual(result, products([1]))
    }

    func testThrowsForCategoryProductsWhenBackendFailsAndNothingIsSaved() async {
        let remote = FakeCategoryRepository()
        remote.productsResult = .failure(StubError.offline)
        let repository = makeRepository(remote: remote, now: { Date(timeIntervalSince1970: 0) })

        do {
            _ = try await repository.products(in: electronics)
            XCTFail("Expected an error when there is nothing saved")
        } catch {
            XCTAssertEqual(error as? StubError, .offline)
        }
    }
}

/// Test double for the category repository. Results are set per test; calls are counted.
final class FakeCategoryRepository: CategoryRepository, @unchecked Sendable {
    var categoriesResult: Result<[ProductCategory], Error> = .success([])
    var productsResult: Result<CategoryProducts, Error> = .success(CategoryProducts(topRated: [], more: []))
    private(set) var categoryCalls = 0
    private(set) var productCalls: [String] = []

    func categories() async throws -> [ProductCategory] {
        categoryCalls += 1
        return try categoriesResult.get()
    }

    func products(in category: ProductCategory) async throws -> CategoryProducts {
        productCalls.append(category.name)
        return try productsResult.get()
    }
}
