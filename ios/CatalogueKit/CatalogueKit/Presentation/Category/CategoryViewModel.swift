import Observation

@MainActor
@Observable
final class CategoryViewModel {
    enum State: Equatable {
        case loading
        case loaded(CategoryProducts)
        case empty
        case failed
    }

    private(set) var state: State = .loading
    let category: ProductCategory
    private let getCategoryProducts: GetCategoryProductsUseCase
    private var hasLoaded = false
    private var isLoading = false

    init(category: ProductCategory, getCategoryProducts: GetCategoryProductsUseCase) {
        self.category = category
        self.getCategoryProducts = getCategoryProducts
    }

    /// Called when the page appears. Loads the first time, and again only if the last load failed or was
    /// interrupted. Coming back from a product page keeps what is on screen.
    func loadIfNeeded() async {
        guard !hasLoaded, !isLoading else { return }
        await load()
    }

    /// Loads the category's products. Used for the first load and for Retry.
    func load() async {
        isLoading = true
        defer { isLoading = false }

        let previous = state
        state = .loading
        do {
            let page = try await getCategoryProducts.execute(category)
            let isEmpty = page.topRated.isEmpty && page.more.isEmpty
            state = isEmpty ? .empty : .loaded(page)
            hasLoaded = true
        } catch is CancellationError {
            // The page left before the products arrived. Put back what was there so the next appearance loads again.
            state = previous
        } catch {
            state = .failed
        }
    }
}
