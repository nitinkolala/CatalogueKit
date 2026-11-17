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
        private(set) var calls = 0
        init(_ result: Result<[Product], Error>) { self.result = result }
        func execute(forceRefresh: Bool) async throws -> FeaturedProducts {
            calls += 1
            return FeaturedProducts(items: try result.get(), isStale: isStale)
        }
    }

    /// A clock the tests move forward by hand.
    private final class FakeClock {
        var now = Date(timeIntervalSince1970: 1_000_000)
    }

    private func homeViewModel(
        featured: ScriptedFeaturedUseCase,
        clock: FakeClock
    ) -> HomeViewModel {
        HomeViewModel(
            getFeaturedProducts: featured,
            getCategories: FixedCategoriesUseCase(result: .success([])),
            now: { clock.now }
        )
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

    func testFirstAppearanceLoads() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        let viewModel = homeViewModel(featured: featured, clock: FakeClock())

        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 1)
        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))
    }

    func testReappearingWithinADayDoesNotReload() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)
        await viewModel.loadIfNeeded()

        clock.now.addTimeInterval(Constants.Home.refreshInterval - 1)
        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 1)
    }

    func testReloadsOnceADayHasPassed() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)
        await viewModel.loadIfNeeded()

        clock.now.addTimeInterval(Constants.Home.refreshInterval)
        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 2)
    }

    func testFailedLoadIsRetriedOnNextAppearance() async {
        let featured = ScriptedFeaturedUseCase(.failure(StubError.offline))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .failed)

        featured.result = .success([TestData.product(id: 1)])
        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 2)
        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))
    }

    func testPullToRefreshAlwaysFetchesEvenWithinADay() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)
        await viewModel.loadIfNeeded()

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(featured.calls, 2)
    }

    func testFailedRefreshDoesNotResetTheDailyClock() async {
        let featured = ScriptedFeaturedUseCase(.success([TestData.product(id: 1)]))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)
        await viewModel.loadIfNeeded()

        clock.now.addTimeInterval(Constants.Home.refreshInterval / 2)
        featured.result = .failure(StubError.offline)
        await viewModel.load(forceRefresh: true)
        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))

        clock.now.addTimeInterval(Constants.Home.refreshInterval / 2)
        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 3)
    }

    /// Products that finish loading after the task was cancelled. It cancels its own task, then answers.
    private struct SelfCancellingFeaturedUseCase: GetFeaturedProductsUseCase {
        let items: [Product]
        func execute(forceRefresh: Bool) async throws -> FeaturedProducts {
            withUnsafeCurrentTask { $0?.cancel() }
            return FeaturedProducts(items: items, isStale: false)
        }
    }

    private final class CountingCategoriesUseCase: GetCategoriesUseCase, @unchecked Sendable {
        private(set) var calls = 0
        func execute() async throws -> [ProductCategory] {
            calls += 1
            return [ProductCategory(name: "jewelery")]
        }
    }

    func testCancelledFirstLoadReturnsToIdleAndLoadsAgainOnNextAppearance() async {
        let featured = ScriptedFeaturedUseCase(.failure(CancellationError()))
        let clock = FakeClock()
        let viewModel = homeViewModel(featured: featured, clock: clock)

        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .idle, "A cancelled load must not show the failed state")

        featured.result = .success([TestData.product(id: 1)])
        await viewModel.loadIfNeeded()

        XCTAssertEqual(featured.calls, 2)
        XCTAssertEqual(viewModel.state, .loaded([TestData.product(id: 1)]))
    }

    func testCancelledRefreshKeepsProductsWithoutStaleNotice() async {
        let products = [TestData.product(id: 1)]
        let featured = ScriptedFeaturedUseCase(.success(products))
        let viewModel = homeViewModel(featured: featured, clock: FakeClock())
        await viewModel.load()

        featured.result = .failure(CancellationError())
        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.state, .loaded(products))
        XCTAssertFalse(viewModel.featuredIsStale, "Cancelling is not a failed refresh, so no notice")
    }

    func testCancelledLoadStopsBeforeCategoriesAreRequested() async {
        let categories = CountingCategoriesUseCase()
        let viewModel = HomeViewModel(
            getFeaturedProducts: SelfCancellingFeaturedUseCase(items: [TestData.product(id: 1)]),
            getCategories: categories
        )

        await Task { await viewModel.load() }.value

        XCTAssertEqual(categories.calls, 0)
        XCTAssertEqual(viewModel.categories, .loading)
    }

    func testCancelledCategoriesRequestRestoresThePreviousState() async {
        let categories = ScriptedCategoriesUseCase(.failure(StubError.offline))
        let viewModel = HomeViewModel(
            getFeaturedProducts: FixedUseCase(result: .success([TestData.product(id: 1)])),
            getCategories: categories
        )
        await viewModel.load()
        XCTAssertEqual(viewModel.categories, .failed)

        categories.result = .failure(CancellationError())
        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.categories, .failed, "A cancelled retry must keep the retry option, not spin forever")
    }

    private final class ScriptedCategoriesUseCase: GetCategoriesUseCase, @unchecked Sendable {
        var result: Result<[ProductCategory], Error>
        init(_ result: Result<[ProductCategory], Error>) { self.result = result }
        func execute() async throws -> [ProductCategory] { try result.get() }
    }
}
