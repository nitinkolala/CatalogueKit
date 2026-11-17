import SwiftUI

struct CategoryView: View {
    @State private var viewModel: CategoryViewModel
    @State private var search: ProductSearchViewModel
    @FocusState private var searchFocused: Bool
    private let imageLoader: ImageLoader

    init(viewModel: CategoryViewModel, search: ProductSearchViewModel, imageLoader: ImageLoader) {
        _viewModel = State(initialValue: viewModel)
        _search = State(initialValue: search)
        self.imageLoader = imageLoader
    }

    var body: some View {
        Group {
            if search.isActive {
                SearchResultsView(search: search, imageLoader: imageLoader, onScroll: { searchFocused = false })
            } else {
                content
            }
        }
        .navigationTitle(viewModel.category.displayName)
        .searchable(
            text: $search.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.searchPrompt
        )
        .searchFocused($searchFocused)
        .onSubmit(of: .search) {
            search.submit()
            searchFocused = false
        }
        .textInputAutocapitalization(.never)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let page):
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Home.sectionSpacing) {
                    if !page.topRated.isEmpty {
                        productSection(title: L10n.categoryTopRated, products: page.topRated)
                    }
                    if !page.more.isEmpty {
                        productSection(title: L10n.categoryMore, products: page.more)
                    }
                }
                .padding(Constants.Home.gridSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
        case .empty:
            message(L10n.categoryEmpty, showsRetry: false)
        case .failed:
            message(L10n.categoryLoadFailed, showsRetry: true)
        }
    }

    private func productSection(title: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
            Text(title)
                .font(.title3.bold())
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.Home.gridMinimumWidth), spacing: Constants.Home.gridSpacing)],
                spacing: Constants.Home.gridSpacing
            ) {
                ForEach(products) { product in
                    NavigationLink(value: AppRoute.product(product)) {
                        ProductCardView(product: product, imageLoader: imageLoader)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func message(_ text: String, showsRetry: Bool) -> some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Text(text)
                .multilineTextAlignment(.center)
            if showsRetry {
                Button(L10n.homeRetry) {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
