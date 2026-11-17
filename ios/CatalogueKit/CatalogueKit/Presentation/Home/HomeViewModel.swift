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

    /// The Categories section. It is hidden when there are no categories or the request fails.
    enum CategoriesState: Equatable {
        case loading
        case loaded([ProductCategory])
        case hidden
    }

    private(set) var state: State = .idle
    private(set) var categories: CategoriesState = .loading
    private let getFeaturedProducts: GetFeaturedProductsUseCase
    private let getCategories: GetCategoriesUseCase

    init(getFeaturedProducts: GetFeaturedProductsUseCase, getCategories: GetCategoriesUseCase) {
        self.getFeaturedProducts = getFeaturedProducts
        self.getCategories = getCategories
    }

    /// Reloads the featured list and the categories. A refresh keeps what is on screen until new data arrives,
    /// and keeps it if the refresh fails.
    func load(forceRefresh: Bool = false) async {
        await loadFeatured(forceRefresh: forceRefresh)
        await loadCategories()
    }

    private func loadFeatured(forceRefresh: Bool) async {
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

    private func loadCategories() async {
        let isShowingCategories: Bool
        if case .loaded = categories { isShowingCategories = true } else { isShowingCategories = false }
        if !isShowingCategories { categories = .loading }

        do {
            let list = try await getCategories.execute()
            categories = list.isEmpty ? .hidden : .loaded(list)
        } catch {
            if !isShowingCategories { categories = .hidden }
        }
    }
}
