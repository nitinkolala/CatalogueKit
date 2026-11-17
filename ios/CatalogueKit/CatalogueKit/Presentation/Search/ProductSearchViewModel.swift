import Foundation
import Observation
import SwiftUI

/// Drives search on one screen. Home searches the whole catalogue; a Category page searches only its category.
///
/// Typing updates `query` at once. A request starts after a quiet period (debounce). A new query cancels
/// the pending or in-flight request, and a response is only shown if it still matches the active query.
@MainActor
@Observable
final class ProductSearchViewModel {
    enum Phase: Equatable {
        /// Fewer than the minimum characters: the screen shows its default view.
        case idle
        case searching
        case results
        case noMatches(String)
        case failed(SearchError)
    }

    var query: String = "" {
        didSet { queryDidChange() }
    }

    private(set) var phase: Phase = .idle
    private(set) var items: [Product] = []
    private(set) var total = 0
    private(set) var isLoadingMore = false
    private(set) var recentSearches: [String]

    /// Nil on Home (whole catalogue). Set to a category on a Category page.
    let scope: ProductCategory?

    private let search: SearchProductsUseCase
    private let recents: RecentSearchesStore
    private let connectivity: ConnectivityMonitor
    private let debounce: Duration
    private let pageSize: Int
    private let announce: @MainActor (String) -> Void
    private let now: () -> Date

    private var hasMore = false
    private var activeQuery: String?
    private var lastSearched: String?
    private var lastAnnouncement: Date?
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    init(
        scope: ProductCategory?,
        search: SearchProductsUseCase,
        recents: RecentSearchesStore,
        connectivity: ConnectivityMonitor,
        debounce: Duration = Constants.Search.debounce,
        pageSize: Int = Constants.Search.pageSize,
        announce: @escaping @MainActor (String) -> Void = { message in
            AccessibilityNotification.Announcement(message).post()
        },
        now: @escaping () -> Date = Date.init
    ) {
        self.scope = scope
        self.search = search
        self.recents = recents
        self.connectivity = connectivity
        self.debounce = debounce
        self.pageSize = pageSize
        self.announce = announce
        self.now = now
        self.recentSearches = recents.load()
    }

    /// True when results or a failure replace the screen's default view.
    var isActive: Bool { phase != .idle }

    /// The query with leading and trailing spaces removed.
    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Typing

    private func queryDidChange() {
        if query.count > Constants.Search.maxLength {
            query = String(query.prefix(Constants.Search.maxLength))
            return
        }
        scheduleSearch()
    }

    private func scheduleSearch() {
        let term = trimmedQuery
        guard term.count >= Constants.Search.minLength else {
            cancelPending()
            resetResults()
            return
        }
        // Same text as the last search (for example, a trailing space was typed): keep what is on screen.
        guard term != lastSearched else { return }

        cancelPending()
        searchTask = Task { [debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self.run(term)
        }
    }

    /// Runs the search again after a failure. The typed text is unchanged.
    func retry() {
        let term = trimmedQuery
        guard term.count >= Constants.Search.minLength else { return }
        cancelPending()
        lastSearched = nil
        searchTask = Task { await self.run(term) }
    }

    /// Cancels every pending or in-flight request. Nothing is shown afterwards for the cancelled queries.
    private func cancelPending() {
        searchTask?.cancel()
        loadMoreTask?.cancel()
        reconnectTask?.cancel()
        searchTask = nil
        loadMoreTask = nil
        reconnectTask = nil
    }

    private func resetResults() {
        lastSearched = nil
        activeQuery = nil
        items = []
        total = 0
        hasMore = false
        isLoadingMore = false
        phase = .idle
    }

    // MARK: - Running a search

    private func run(_ term: String) async {
        activeQuery = term
        lastSearched = term
        isLoadingMore = false
        phase = .searching

        do {
            let page = try await search.execute(
                ProductSearchRequest(query: term, category: scope, offset: 0, limit: pageSize)
            )
            guard !Task.isCancelled, activeQuery == term else { return }
            items = page.items
            total = page.total
            hasMore = page.hasMore
            phase = page.items.isEmpty ? .noMatches(term) : .results
            announceResults()
        } catch {
            guard !Task.isCancelled, activeQuery == term else { return }
            let failure = (error as? SearchError) ?? .service
            items = []
            total = 0
            hasMore = false
            lastSearched = nil
            phase = .failed(failure)
            if failure == .offline {
                waitForConnectionAndRetry(term)
            }
        }
    }

    /// When the device goes offline, run the same search again once the connection returns.
    private func waitForConnectionAndRetry(_ term: String) {
        reconnectTask = Task { [connectivity] in
            await connectivity.waitUntilOnline()
            guard !Task.isCancelled, self.trimmedQuery == term else { return }
            await self.run(term)
        }
    }

    // MARK: - Paging

    /// Call when a result appears. Loads the next page when the last result on screen is the one that appeared.
    func loadMoreIfNeeded(after product: Product) {
        guard phase == .results, hasMore, !isLoadingMore, items.last?.id == product.id else { return }
        loadMoreTask?.cancel()
        loadMoreTask = Task { await self.loadMore() }
    }

    private func loadMore() async {
        guard let term = activeQuery else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await search.execute(
                ProductSearchRequest(query: term, category: scope, offset: items.count, limit: pageSize)
            )
            guard !Task.isCancelled, activeQuery == term else { return }
            let known = Set(items.map(\.id))
            items += page.items.filter { !known.contains($0.id) }
            hasMore = page.hasMore
            total = page.total
        } catch {
            // Keep the results already on screen. Loading the next page is tried again when the last result appears.
        }
    }

    // MARK: - Announcements

    /// Announces the result count, at most once per throttle interval, so each keystroke does not speak.
    private func announceResults() {
        let current = now()
        if let last = lastAnnouncement,
           current.timeIntervalSince(last) < Constants.Search.announcementThrottle {
            return
        }
        lastAnnouncement = current
        announce(L10n.searchResultCount(total))
    }

    // MARK: - Recent searches

    /// Remembers the typed text when the customer submits it with the Search key.
    func submit() {
        let term = trimmedQuery
        guard term.count >= Constants.Search.minLength else { return }
        recentSearches = RecentSearches.adding(term, to: recentSearches, limit: Constants.Search.recentLimit)
        recents.save(recentSearches)
    }

    /// Fills the field with a recent search. The search then runs as if it had been typed.
    func selectRecent(_ term: String) {
        query = term
    }

    func clearRecentSearches() {
        recentSearches = []
        recents.save([])
    }
}
