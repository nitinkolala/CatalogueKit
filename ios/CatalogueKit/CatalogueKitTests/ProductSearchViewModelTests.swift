import XCTest
@testable import CatalogueKit

/// Builds a page of products. Not main-actor isolated, so search handlers can call it off the main actor.
nonisolated func makePage(_ ids: [Int], total: Int? = nil, hasMore: Bool = false) -> ProductPage {
    let items = ids.map { id in
        Product(
            id: id,
            title: "Product \(id)",
            price: 10,
            description: "Description \(id)",
            category: "category",
            imageURL: URL(string: "https://img.test/\(id).jpg")!,
            available: true,
            rating: Product.Rating(rate: 4, count: 10)
        )
    }
    return ProductPage(items: items, total: total ?? ids.count, hasMore: hasMore)
}

@MainActor
final class ProductSearchViewModelTests: XCTestCase {
    /// Records each request and answers from a handler.
    actor FakeSearch: SearchProductsUseCase {
        private(set) var requests: [ProductSearchRequest] = []
        private let handler: @Sendable (ProductSearchRequest) async throws -> ProductPage

        init(handler: @escaping @Sendable (ProductSearchRequest) async throws -> ProductPage) {
            self.handler = handler
        }

        func execute(_ request: ProductSearchRequest) async throws -> ProductPage {
            requests.append(request)
            return try await handler(request)
        }

        var requestCount: Int { requests.count }
    }

    final class StubRecents: RecentSearchesStore, @unchecked Sendable {
        var stored: [String]

        init(_ initial: [String] = []) {
            stored = initial
        }

        func load() -> [String] { stored }
        func save(_ terms: [String]) { stored = terms }
    }

    /// Connectivity that never comes back. Used to check the offline state stays put.
    struct NeverOnline: ConnectivityMonitor {
        func waitUntilOnline() async {
            try? await Task.sleep(for: .seconds(3600))
        }
    }

    /// Connectivity that is always available. Used to check an offline search runs again straight away.
    struct AlwaysOnline: ConnectivityMonitor {
        func waitUntilOnline() async {}
    }

    @MainActor
    final class Announcements {
        var messages: [String] = []
    }

    private let fixedDate = Date(timeIntervalSince1970: 0)

    private func makeViewModel(
        search: FakeSearch,
        recents: StubRecents = StubRecents(),
        connectivity: ConnectivityMonitor = NeverOnline(),
        scope: ProductCategory? = nil,
        announcements: Announcements? = nil,
        now: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> ProductSearchViewModel {
        let log = announcements ?? Announcements()
        return ProductSearchViewModel(
            scope: scope,
            search: search,
            recents: recents,
            connectivity: connectivity,
            debounce: .milliseconds(20),
            pageSize: 20,
            announce: { message in log.messages.append(message) },
            now: now
        )
    }

    /// Polls until `condition` is true, failing the test if it never is.
    private func waitFor(_ condition: @escaping () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<300 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }

    private func settle() async {
        try? await Task.sleep(for: .milliseconds(120))
    }

    // MARK: - Typing and debounce

    func testShortQuerySendsNoRequest() async {
        let search = FakeSearch { _ in makePage([]) }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "a"
        await settle()

        let count = await search.requestCount
        XCTAssertEqual(count, 0)
        XCTAssertEqual(viewModel.phase, .idle)
    }

    func testBurstOfKeystrokesSendsOneRequestForTheLatestText() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "g"
        viewModel.query = "ga"
        viewModel.query = "gam"
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        let queries = await search.requests.map(\.query)
        XCTAssertEqual(queries, ["game"])
    }

    func testTrimmedSameQueryDoesNotSendAgain() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search)
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        viewModel.query = "game  "
        await settle()

        let count = await search.requestCount
        XCTAssertEqual(count, 1)
    }

    func testQueryIsCappedAtOneHundredCharacters() {
        let viewModel = makeViewModel(search: FakeSearch { _ in makePage([]) })

        viewModel.query = String(repeating: "a", count: 150)

        XCTAssertEqual(viewModel.query.count, Constants.Search.maxLength)
    }

    func testRequestsAreTrimmed() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "  game  "
        await waitFor { viewModel.phase == .results }

        let queries = await search.requests.map(\.query)
        XCTAssertEqual(queries, ["game"])
    }

    // MARK: - Results and states

    func testResultsAndNoMatchesStates() async {
        let search = FakeSearch { request in
            request.query == "game" ? makePage([1, 2]) : makePage([])
        }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }
        XCTAssertEqual(viewModel.items.map(\.id), [1, 2])
        XCTAssertEqual(viewModel.total, 2)

        viewModel.query = "zzz"
        await waitFor { viewModel.phase == .noMatches("zzz") }
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testClearingTextReturnsToIdle() async {
        let viewModel = makeViewModel(search: FakeSearch { _ in makePage([1]) })
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        viewModel.query = ""

        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(viewModel.total, 0)
        XCTAssertFalse(viewModel.isActive)
    }

    func testScopedSearchOnlySearchesThatCategory() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search, scope: ProductCategory(name: "jewelery"))

        viewModel.query = "ring"
        await waitFor { viewModel.phase == .results }

        let categories = await search.requests.map(\.category)
        XCTAssertEqual(categories, [ProductCategory(name: "jewelery")])
    }

    func testHomeSearchIsNotScoped() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "ring"
        await waitFor { viewModel.phase == .results }

        let categories = await search.requests.map(\.category)
        XCTAssertEqual(categories, [nil])
    }

    // MARK: - Failures and offline

    func testFailureKeepsTypedTextAndRetryRecovers() async {
        let calls = CallCounter()
        let search = FakeSearch { _ in
            let call = calls.value
            calls.increment()
            if call == 0 { throw SearchError.service }
            return makePage([7])
        }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "game"
        await waitFor { viewModel.phase == .failed(.service) }
        XCTAssertEqual(viewModel.query, "game")

        viewModel.retry()
        await waitFor { viewModel.phase == .results }
        XCTAssertEqual(viewModel.items.map(\.id), [7])
    }

    func testOfflineShowsOfflineStateAndKeepsText() async {
        let search = FakeSearch { _ in throw SearchError.offline }
        let viewModel = makeViewModel(search: search, connectivity: NeverOnline())

        viewModel.query = "game"
        await waitFor { viewModel.phase == .failed(.offline) }
        await settle()

        XCTAssertEqual(viewModel.query, "game")
        let count = await search.requestCount
        XCTAssertEqual(count, 1, "Nothing runs again until the connection returns")
    }

    func testOfflineSearchRunsAgainWhenConnectionReturns() async {
        let calls = CallCounter()
        let search = FakeSearch { _ in
            let call = calls.value
            calls.increment()
            if call == 0 { throw SearchError.offline }
            return makePage([3])
        }
        let viewModel = makeViewModel(search: search, connectivity: AlwaysOnline())

        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        let count = await search.requestCount
        XCTAssertEqual(count, 2)
        XCTAssertEqual(viewModel.items.map(\.id), [3])
    }

    // MARK: - Cancellation and stale responses

    func testStaleResponseForAnOldQueryIsDiscarded() async {
        let search = FakeSearch { request in
            if request.query == "slow" {
                // Ignores cancellation on purpose, so only the query check can discard this answer.
                try? await Task.sleep(for: .milliseconds(150))
                return makePage([100])
            }
            return makePage([200])
        }
        let viewModel = makeViewModel(search: search)

        viewModel.query = "slow"
        await waitFor { viewModel.phase == .searching }
        viewModel.query = "fast"
        await waitFor { viewModel.phase == .results }
        try? await Task.sleep(for: .milliseconds(250))

        XCTAssertEqual(viewModel.items.map(\.id), [200])
        XCTAssertEqual(viewModel.phase, .results)
    }

    // MARK: - Paging

    func testNextPageIsAppendedWhenLastResultAppears() async {
        let search = FakeSearch { request in
            if request.offset == 0 {
                return makePage(Array(1...20), total: 25, hasMore: true)
            }
            return makePage(Array(21...25), total: 25, hasMore: false)
        }
        let viewModel = makeViewModel(search: search)
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        viewModel.loadMoreIfNeeded(after: viewModel.items[19])
        await waitFor { viewModel.items.count == 25 }

        let offsets = await search.requests.map(\.offset)
        XCTAssertEqual(offsets, [0, 20])
    }

    func testNoNextPageWhenAnEarlierResultAppears() async {
        let search = FakeSearch { _ in makePage(Array(1...20), total: 25, hasMore: true) }
        let viewModel = makeViewModel(search: search)
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        viewModel.loadMoreIfNeeded(after: viewModel.items[3])
        await settle()

        let count = await search.requestCount
        XCTAssertEqual(count, 1)
    }

    // MARK: - Recent searches

    func testSubmitRemembersTheSearch() async {
        let recents = StubRecents()
        let viewModel = makeViewModel(search: FakeSearch { _ in makePage([1]) }, recents: recents)
        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }

        viewModel.submit()

        XCTAssertEqual(viewModel.recentSearches, ["game"])
        XCTAssertEqual(recents.stored, ["game"])
    }

    func testSubmitIgnoresTooShortText() {
        let recents = StubRecents()
        let viewModel = makeViewModel(search: FakeSearch { _ in makePage([]) }, recents: recents)
        viewModel.query = "a"

        viewModel.submit()

        XCTAssertTrue(viewModel.recentSearches.isEmpty)
        XCTAssertTrue(recents.stored.isEmpty)
    }

    func testSelectingARecentSearchRunsIt() async {
        let search = FakeSearch { _ in makePage([1]) }
        let viewModel = makeViewModel(search: search, recents: StubRecents(["gaming"]))

        viewModel.selectRecent("gaming")
        await waitFor { viewModel.phase == .results }

        XCTAssertEqual(viewModel.query, "gaming")
        let queries = await search.requests.map(\.query)
        XCTAssertEqual(queries, ["gaming"])
    }

    func testClearingRecentSearchesEmptiesTheList() {
        let recents = StubRecents(["gaming", "lamp"])
        let viewModel = makeViewModel(search: FakeSearch { _ in makePage([]) }, recents: recents)

        viewModel.clearRecentSearches()

        XCTAssertTrue(viewModel.recentSearches.isEmpty)
        XCTAssertTrue(recents.stored.isEmpty)
    }

    // MARK: - Announcements

    func testResultCountIsAnnouncedOnceWithinTheThrottleWindow() async {
        let announcements = Announcements()
        let search = FakeSearch { _ in makePage([1, 2]) }
        let viewModel = makeViewModel(search: search, announcements: announcements, now: { self.fixedDate })

        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }
        viewModel.query = "gamer"
        await waitFor { viewModel.items.count == 2 && viewModel.phase == .results }
        await settle()

        XCTAssertEqual(announcements.messages, ["2 results"])
    }

    func testEachResultChangeAnnouncesAfterTheThrottleWindow() async {
        let announcements = Announcements()
        var clock = fixedDate
        let search = FakeSearch { _ in makePage([1, 2]) }
        let viewModel = makeViewModel(search: search, announcements: announcements, now: { clock })

        viewModel.query = "game"
        await waitFor { viewModel.phase == .results }
        clock = clock.addingTimeInterval(Constants.Search.announcementThrottle + 1)
        viewModel.query = "gamer"
        await settle()
        await waitFor { announcements.messages.count == 2 }

        XCTAssertEqual(announcements.messages, ["2 results", "2 results"])
    }
}
