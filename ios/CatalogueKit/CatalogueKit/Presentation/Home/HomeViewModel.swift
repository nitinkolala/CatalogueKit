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

    private(set) var state: State = .idle
    private let getFeaturedProducts: GetFeaturedProductsUseCase

    init(getFeaturedProducts: GetFeaturedProductsUseCase) {
        self.getFeaturedProducts = getFeaturedProducts
    }

    /// Loads the featured list. A refresh keeps the current list on screen until new data arrives,
    /// and keeps it if the refresh fails.
    func load(forceRefresh: Bool = false) async {
        let isShowingProducts: Bool
        if case .loaded = state { isShowingProducts = true } else { isShowingProducts = false }
        if !isShowingProducts { state = .loading }

        do {
            let products = try await getFeaturedProducts.execute(forceRefresh: forceRefresh)
            state = products.isEmpty ? .empty : .loaded(products)
        } catch {
            if !isShowingProducts { state = .failed }
        }
    }
}
