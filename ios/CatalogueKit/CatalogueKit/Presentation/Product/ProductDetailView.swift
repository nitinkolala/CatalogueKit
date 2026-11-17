import SwiftUI

struct ProductDetailView: View {
    let product: Product
    let imageLoader: ImageLoader

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.Home.gridSpacing) {
                CachedImageView(url: product.imageURL, loader: imageLoader)
                    .frame(height: Constants.Home.detailImageHeight)
                    .frame(maxWidth: .infinity)
                Text(product.title)
                    .font(.title2.bold())
                Text(product.price, format: .currency(code: Constants.Currency.code))
                    .font(.title3)
                if !product.available {
                    Text(L10n.outOfStock)
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
                Text(ProductFormatting.ratingText(for: product))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(product.category.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(product.description)
            }
            .padding(Constants.Home.gridSpacing)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
