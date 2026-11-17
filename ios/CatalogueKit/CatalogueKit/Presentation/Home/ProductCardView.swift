import SwiftUI

struct ProductCardView: View {
    let product: Product
    let imageLoader: ImageLoader

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Home.cardPadding) {
            CachedImageView(url: product.imageURL, loader: imageLoader)
                .frame(height: Constants.Home.cardImageHeight)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    if !product.available {
                        Text(L10n.outOfStock)
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                            .padding(Constants.Home.cardPadding)
                    }
                }
            Text(product.title)
                .font(.subheadline)
                .lineLimit(2, reservesSpace: true)
            Text(product.price, format: .currency(code: Constants.Currency.code))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(ProductFormatting.ratingText(for: product))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Constants.Home.cardPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Constants.Home.cardCornerRadius))
        .contentShape(Rectangle())
        // Cards have a fixed grid width. Larger text is capped here so the rows stay aligned.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}
