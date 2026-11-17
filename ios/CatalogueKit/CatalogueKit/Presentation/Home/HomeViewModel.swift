import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Product])
        case empty
        case failed
    }

    /// The Categories section. It is hidden when the backend returns no categories. If the request fails,
    /// it shows a message with a retry.
    enum CategoriesState: Equatable {
        case loading
        case loaded([ProductCategory])
        case hidden
        case failed
    }

    private(set) var state: State = .idle
    private(set) var categories: CategoriesState = .loading
    /// True when a refresh failed and the featured products on screen are the last ones loaded.
    private(set) var featuredIsStale = false
    /// When both sections last loaded from the backend. Nil until the first complete load.
    private(set) var lastRefreshedAt: Date?
    private var isLoading = false
    private let getFeaturedProducts: GetFeaturedProductsUseCase
    private let getCategories: GetCategoriesUseCase
    private let now: () -> Date

    init(
        getFeaturedProducts: GetFeaturedProductsUseCase,
        getCategories: GetCategoriesUseCase,
        now: @escaping () -> Date = { Date() }
    ) {
        self.getFeaturedProducts = getFeaturedProducts
        self.getCategories = getCategories
        self.now = now
    }

    /// Called when the Home screen appears. Loads on first use, after a failure, or once the last complete
    /// refresh is older than `Constants.Home.refreshInterval`. Appearing again inside that window does nothing.
    func loadIfNeeded() async {
        guard !isLoading, needsLoad else { return }
        await load()
    }

    /// Reloads the featured list and the categories. A refresh keeps what is on screen until new data arrives,
    /// and keeps it if the refresh fails.
    func load(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let featuredOK = await loadFeatured(forceRefresh: forceRefresh)
        // The screen left while the featured list was loading: skip the categories request.
        guard !Task.isCancelled else { return }
        let categoriesOK = await loadCategories()
        if featuredOK && categoriesOK {
            lastRefreshedAt = now()
        }
    }

    private var needsLoad: Bool {
        switch state {
        case .idle, .failed: return true
        case .loading, .loaded, .empty: break
        }
        if case .failed = categories { return true }
        guard let lastRefreshedAt else { return true }
        return now().timeIntervalSince(lastRefreshedAt) >= Constants.Home.refreshInterval
    }

    /// Returns true only when the backend answered. A stale result served from the cache counts as a failure.
    /// A cancelled load puts back what was on screen before it started, so the next appearance loads again.
    private func loadFeatured(forceRefresh: Bool) async -> Bool {
        let previous = state
        let isShowingProducts: Bool
        if case .loaded = state { isShowingProducts = true } else { isShowingProducts = false }
        if !isShowingProducts { state = .loading }

        do {
            let result = try await getFeaturedProducts.execute(forceRefresh: forceRefresh)
            state = result.items.isEmpty ? .empty : .loaded(result.items)
            featuredIsStale = result.isStale
            return !result.isStale
        } catch is CancellationError {
            state = previous
            return false
        } catch {
            if isShowingProducts {
                featuredIsStale = true
            } else {
                state = .failed
            }
            return false
        }
    }

    private func loadCategories() async -> Bool {
        let previous = categories
        let isShowingCategories: Bool
        if case .loaded = categories { isShowingCategories = true } else { isShowingCategories = false }
        if !isShowingCategories { categories = .loading }

        do {
            let list = try await getCategories.execute()
            categories = list.isEmpty ? .hidden : .loaded(list)
            return true
        } catch is CancellationError {
            categories = previous
            return false
        } catch {
            if !isShowingCategories { categories = .failed }
            return false
        }
    }
}
