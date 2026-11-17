import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    @State private var isDescriptionExpanded = false
    @Environment(\.dismiss) private var dismiss
    private let imageLoader: ImageLoader

    init(viewModel: ProductDetailViewModel, imageLoader: ImageLoader) {
        _viewModel = State(initialValue: viewModel)
        self.imageLoader = imageLoader
    }

    var body: some View {
        Group {
            if let product = viewModel.product {
                content(for: product)
            } else {
                notFound
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private func content(for product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.ProductPage.sectionSpacing) {
                if case .failed(let error) = viewModel.phase {
                    refreshBanner(error)
                }
                ProductGalleryView(images: [product.imageURL], productName: product.title, imageLoader: imageLoader)
                summary(for: product)
                descriptionSection(product.description)
                specificationsSection(for: product)
            }
            .padding(Constants.Home.gridSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .refreshable { await viewModel.load() }
    }

    /// Name, price, rating and stock, in the order a screen reader reads them.
    private func summary(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: Constants.ProductPage.statusBadgeSpacing) {
            Text(product.title)
                .font(.title2.bold())
            Text(product.price, format: .currency(code: Constants.Currency.code))
                .font(.title3)
            Text(ProductFormatting.ratingText(for: product))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            stockLabel(StockStatus(available: product.available))
        }
    }

    /// Stock status always has text as well as an icon and colour.
    @ViewBuilder
    private func stockLabel(_ status: StockStatus) -> some View {
        switch status {
        case .inStock:
            Label(L10n.productInStock, systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        case .outOfStock:
            Label(L10n.outOfStock, systemImage: "xmark.octagon.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func descriptionSection(_ description: String) -> some View {
        let isLong = DescriptionLength.isLong(description)
        let collapsed = isLong && !isDescriptionExpanded
        VStack(alignment: .leading, spacing: Constants.ProductPage.statusBadgeSpacing) {
            Text(description)
                .lineLimit(collapsed ? Constants.ProductPage.descriptionCollapsedLines : nil)
            if isLong {
                Button {
                    withAnimation { isDescriptionExpanded.toggle() }
                } label: {
                    Text(isDescriptionExpanded ? L10n.productShowLess : L10n.productShowMore)
                        .font(.subheadline.bold())
                }
                .frame(minHeight: Constants.Layout.minTouchTarget, alignment: .leading)
            }
        }
    }

    private func specificationsSection(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: Constants.ProductPage.statusBadgeSpacing) {
            Text(L10n.productSpecifications)
                .font(.headline)
            specificationRow(L10n.productSpecCategory, product.category.capitalized)
            specificationRow(L10n.productSpecId, String(product.id))
            specificationRow(
                L10n.productSpecRating,
                product.rating.rate.formatted(.number.precision(.fractionLength(Constants.Home.ratingDecimalPlaces)))
            )
        }
    }

    /// Label on the left, value on the right. Long values wrap instead of being cut off.
    private func specificationRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.Home.gridSpacing) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func refreshBanner(_ error: ProductLoadError) -> some View {
        VStack(alignment: .leading, spacing: Constants.Home.gridSpacing / 2) {
            Text(error == .offline ? L10n.productOffline : L10n.productLoadFailed)
                .font(.subheadline)
            Button(L10n.homeRetry) {
                Task { await viewModel.load() }
            }
            .buttonStyle(.bordered)
            .frame(minHeight: Constants.Layout.minTouchTarget)
        }
        .padding(Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Constants.Home.cardCornerRadius))
    }

    private var notFound: some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Text(L10n.productNotFound)
                .multilineTextAlignment(.center)
            Button(L10n.productBack) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: Constants.Layout.minTouchTarget)
        }
        .padding(Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
