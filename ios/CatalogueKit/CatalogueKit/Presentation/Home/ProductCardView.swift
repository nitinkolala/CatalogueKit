import SwiftUI

struct ProductCardView: View {
    let product: Product
    let imageLoader: ImageLoader

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Home.cardPadding) {
            CachedImageView(url: product.imageURL, loader: imageLoader)
                .frame(height: Constants.Home.cardImageHeight)
                .frame(maxWidth: .infinity)
            Text(product.title)
                .font(.subheadline)
                .lineLimit(2)
            Text(product.price, format: .currency(code: Constants.Currency.code))
                .font(.headline)
            if !product.available {
                Text(L10n.outOfStock)
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
            Text(ProductFormatting.ratingText(for: product))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Constants.Home.cardPadding)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: Constants.Home.cardCornerRadius))
        .contentShape(Rectangle())
    }
}
