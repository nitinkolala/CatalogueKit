import SwiftUI

/// The results area of a search: results, the loading indicator, the no-match message, and the failure message with retry.
struct SearchResultsView: View {
    let search: ProductSearchViewModel
    let imageLoader: ImageLoader
    /// Called when the customer starts scrolling the results. The screen uses it to close the keyboard.
    var onScroll: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
                content
            }
            .padding(Constants.Home.gridSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .onScrollPhaseChange { _, newPhase in
            if newPhase == .interacting {
                onScroll()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch search.phase {
        case .idle:
            EmptyView()
        case .searching where search.items.isEmpty:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .searching, .results:
            resultsList
        case .noMatches(let term):
            noMatches(term)
        case .failed(let error):
            failure(error)
        }
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
            if search.phase == .searching {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            Text(L10n.searchResultCount(search.total))
                .font(.footnote)
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.Home.gridMinimumWidth), spacing: Constants.Home.gridSpacing)],
                spacing: Constants.Home.gridSpacing
            ) {
                ForEach(search.items) { product in
                    NavigationLink(value: AppRoute.product(product)) {
                        ProductCardView(product: product, imageLoader: imageLoader)
                    }
                    .buttonStyle(.plain)
                    .onAppear { search.loadMoreIfNeeded(after: product) }
                }
            }
            if search.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func noMatches(_ term: String) -> some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Text(L10n.searchNoMatches(term))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(L10n.searchNoMatchesHint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.Home.sectionSpacing)
    }

    private func failure(_ error: SearchError) -> some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Text(error == .offline ? L10n.searchOffline : L10n.searchFailed)
                .multilineTextAlignment(.center)
            Button(L10n.homeRetry) {
                search.retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.Home.sectionSpacing)
    }
}
