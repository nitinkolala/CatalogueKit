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

    init(category: ProductCategory, getCategoryProducts: GetCategoryProductsUseCase) {
        self.category = category
        self.getCategoryProducts = getCategoryProducts
    }

    func load() async {
        state = .loading
        do {
            let page = try await getCategoryProducts.execute(category)
            let isEmpty = page.topRated.isEmpty && page.more.isEmpty
            state = isEmpty ? .empty : .loaded(page)
        } catch {
            state = .failed
        }
    }
}
