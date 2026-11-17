import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var path: [Product] = []
    private let imageLoader: ImageLoader

    init(viewModel: HomeViewModel, imageLoader: ImageLoader) {
        _viewModel = State(initialValue: viewModel)
        self.imageLoader = imageLoader
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(L10n.homeTitle)
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product, imageLoader: imageLoader)
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let products):
            productGrid(products)
        case .empty:
            message(L10n.homeEmpty, showsRetry: false)
        case .failed:
            message(L10n.homeLoadFailed, showsRetry: true)
        }
    }

    private func productGrid(_ products: [Product]) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.Home.gridMinimumWidth), spacing: Constants.Home.gridSpacing)],
                spacing: Constants.Home.gridSpacing
            ) {
                ForEach(products) { product in
                    NavigationLink(value: product) {
                        ProductCardView(product: product, imageLoader: imageLoader)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Constants.Home.gridSpacing)
        }
        .refreshable { await viewModel.load(forceRefresh: true) }
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
    }
}
