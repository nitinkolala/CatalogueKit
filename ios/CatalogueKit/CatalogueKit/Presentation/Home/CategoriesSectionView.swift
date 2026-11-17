import SwiftUI

/// The Categories section at the end of Home. Shows placeholder tiles while loading and nothing when hidden.
struct CategoriesSectionView: View {
    let state: HomeViewModel.CategoriesState

    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .loading:
            section {
                ForEach(0..<Constants.Home.categoryPlaceholderCount, id: \.self) { _ in
                    CategoryTileView(name: L10n.categoriesTitle, initials: "", accent: CategoryPalette.neutral)
                        .redacted(reason: .placeholder)
                }
            }
        case .loaded(let categories):
            section {
                ForEach(categories) { category in
                    NavigationLink(value: AppRoute.category(category)) {
                        CategoryTileView(
                            name: category.displayName,
                            initials: CategoryInitials.make(from: category.displayName),
                            accent: CategoryPalette.accent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func section<Tiles: View>(@ViewBuilder tiles: () -> Tiles) -> some View {
        VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
            Text(L10n.categoriesTitle)
                .font(.title2.bold())
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Constants.Home.categoryMinimumWidth), spacing: Constants.Home.gridSpacing)],
                spacing: Constants.Home.gridSpacing
            ) {
                tiles()
            }
        }
    }
}

/// A compact grey row with a two-letter badge. Uses the system grey background, so it adapts to light and dark mode.
private struct CategoryTileView: View {
    let name: String
    let initials: String
    let accent: Color

    var body: some View {
        HStack(spacing: Constants.Home.gridSpacing / 2) {
            Text(initials)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: Constants.Home.categoryBadgeSize, height: Constants.Home.categoryBadgeSize)
                .background(Circle().fill(accent))
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity, minHeight: Constants.Home.categoryTileHeight)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Constants.Home.categoryCornerRadius))
    }
}
