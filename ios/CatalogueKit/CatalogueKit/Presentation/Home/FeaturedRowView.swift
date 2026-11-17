import SwiftUI

/// Featured products in one row that scrolls sideways. Arrow buttons sit at each edge and appear only
/// when there is more content in that direction. Each tap moves the row by one card.
struct FeaturedRowView: View {
    let products: [Product]
    let imageLoader: ImageLoader

    @State private var position = ScrollPosition(edge: .leading)
    @State private var metrics = ScrollMetrics.zero

    private var canScrollBack: Bool {
        metrics.offsetX > Constants.Home.scrollEdgeTolerance
    }

    private var canScrollForward: Bool {
        metrics.offsetX + metrics.visibleWidth < metrics.contentWidth - Constants.Home.scrollEdgeTolerance
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: Constants.Home.gridSpacing) {
                ForEach(products) { product in
                    NavigationLink(value: AppRoute.product(product)) {
                        ProductCardView(product: product, imageLoader: imageLoader)
                            .frame(width: Constants.Home.featuredCardWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: ScrollMetrics.self) { geometry in
            ScrollMetrics(
                offsetX: geometry.contentOffset.x,
                visibleWidth: geometry.containerSize.width,
                contentWidth: geometry.contentSize.width
            )
        } action: { _, newMetrics in
            metrics = newMetrics
        }
        .overlay(alignment: .leading) {
            arrowButton(systemName: "chevron.left", label: L10n.featuredScrollLeft, visible: canScrollBack, direction: -1)
        }
        .overlay(alignment: .trailing) {
            arrowButton(systemName: "chevron.right", label: L10n.featuredScrollRight, visible: canScrollForward, direction: 1)
        }
    }

    private func arrowButton(systemName: String, label: String, visible: Bool, direction: CGFloat) -> some View {
        Button {
            scroll(by: direction)
        } label: {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: Constants.Home.featuredArrowSize, height: Constants.Home.featuredArrowSize)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(Constants.Home.featuredArrowShadowOpacity), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(visible)
        .animation(.easeInOut(duration: Constants.Home.featuredArrowFadeDuration), value: visible)
        .padding(.horizontal, Constants.Home.cardPadding)
    }

    private func scroll(by direction: CGFloat) {
        let step = Constants.Home.featuredCardWidth + Constants.Home.gridSpacing
        let furthest = max(0, metrics.contentWidth - metrics.visibleWidth)
        let target = min(max(0, metrics.offsetX + direction * step), furthest)
        withAnimation(.easeInOut) {
            position.scrollTo(x: target)
        }
    }
}

/// Scroll geometry the arrows need to decide visibility and where to scroll to.
private struct ScrollMetrics: Equatable {
    var offsetX: CGFloat
    var visibleWidth: CGFloat
    var contentWidth: CGFloat

    static let zero = ScrollMetrics(offsetX: 0, visibleWidth: 0, contentWidth: 0)
}
