import SwiftUI

/// Shown on Home when the search field is open but the text is too short to search.
struct RecentSearchesView: View {
    let search: ProductSearchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
                if search.recentSearches.isEmpty {
                    Text(L10n.searchHint)
                        .foregroundStyle(.secondary)
                } else {
                    header
                    ForEach(search.recentSearches, id: \.self) { term in
                        Button {
                            search.selectRecent(term)
                        } label: {
                            HStack(spacing: Constants.Home.gridSpacing / 2) {
                                Image(systemName: Constants.Search.recentIconName)
                                    .foregroundStyle(.secondary)
                                Text(term)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: Constants.Search.touchTarget, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Constants.Home.gridSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        HStack {
            Text(L10n.searchRecentTitle)
                .font(.headline)
            Spacer()
            Button(L10n.searchRecentClear) {
                search.clearRecentSearches()
            }
            .frame(minHeight: Constants.Search.touchTarget)
        }
    }
}
