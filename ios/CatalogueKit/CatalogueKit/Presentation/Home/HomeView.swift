import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var search: ProductSearchViewModel
    @State private var path: [AppRoute] = []
    @FocusState private var searchFocused: Bool
    private let imageLoader: ImageLoader
    private let makeCategoryViewModel: (ProductCategory) -> CategoryViewModel
    private let makeCategorySearchViewModel: (ProductCategory) -> ProductSearchViewModel
    private let makeProductDetailViewModel: (Product) -> ProductDetailViewModel
    private let makeEnquiryViewModel: (Product) -> EnquiryViewModel

    init(
        viewModel: HomeViewModel,
        search: ProductSearchViewModel,
        imageLoader: ImageLoader,
        makeCategoryViewModel: @escaping (ProductCategory) -> CategoryViewModel,
        makeCategorySearchViewModel: @escaping (ProductCategory) -> ProductSearchViewModel,
        makeProductDetailViewModel: @escaping (Product) -> ProductDetailViewModel,
        makeEnquiryViewModel: @escaping (Product) -> EnquiryViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        _search = State(initialValue: search)
        self.imageLoader = imageLoader
        self.makeCategoryViewModel = makeCategoryViewModel
        self.makeCategorySearchViewModel = makeCategorySearchViewModel
        self.makeProductDetailViewModel = makeProductDetailViewModel
        self.makeEnquiryViewModel = makeEnquiryViewModel
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeContentView(
                viewModel: viewModel,
                search: search,
                imageLoader: imageLoader,
                dismissSearchKeyboard: { searchFocused = false }
            )
                .navigationTitle(L10n.homeTitle)
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
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .product(let product):
            ProductDetailView(
                viewModel: makeProductDetailViewModel(product),
                imageLoader: imageLoader
            )
        case .enquiry(let product):
            EnquiryView(viewModel: makeEnquiryViewModel(product))
        case .category(let category):
            CategoryView(
                viewModel: makeCategoryViewModel(category),
                search: makeCategorySearchViewModel(category),
                imageLoader: imageLoader
            )
        }
    }
}

/// The Home content under the search field. Shows results while searching, recent searches while the field is
/// open but empty, and the featured and category sections otherwise.
private struct HomeContentView: View {
    @Environment(\.isSearching) private var isSearching
    let viewModel: HomeViewModel
    let search: ProductSearchViewModel
    let imageLoader: ImageLoader
    let dismissSearchKeyboard: () -> Void

    var body: some View {
        if search.isActive {
            SearchResultsView(search: search, imageLoader: imageLoader, onScroll: dismissSearchKeyboard)
        } else if isSearching {
            RecentSearchesView(search: search)
        } else {
            homeScroll
        }
    }

    private var homeScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Home.sectionSpacing) {
                featuredContent
                CategoriesSectionView(state: viewModel.categories) {
                    Task { await viewModel.load(forceRefresh: true) }
                }
            }
            .padding(Constants.Home.gridSpacing)
        }
        .refreshable { await viewModel.load(forceRefresh: true) }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var featuredContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .loaded(let products):
            VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
                FeaturedRowView(products: products, imageLoader: imageLoader)
                if viewModel.featuredIsStale {
                    HStack(spacing: Constants.Home.gridSpacing / 2) {
                        Text(L10n.homeFeaturedStale)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button(L10n.homeRetry) {
                            Task { await viewModel.load(forceRefresh: true) }
                        }
                        .frame(minHeight: Constants.Layout.minTouchTarget)
                    }
                }
            }
        case .empty:
            message(L10n.homeEmpty, showsRetry: false)
        case .failed:
            message(L10n.homeLoadFailed, showsRetry: true)
        }
    }

    private func message(_ text: String, showsRetry: Bool) -> some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Text(text)
                .multilineTextAlignment(.center)
            if showsRetry {
                Button(L10n.homeRetry) {
                    Task { await viewModel.load(forceRefresh: true) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity)
    }
}
