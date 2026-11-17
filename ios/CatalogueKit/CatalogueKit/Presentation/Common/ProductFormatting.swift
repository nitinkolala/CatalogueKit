import Foundation

/// Display helpers shared by the card and the detail page.
nonisolated enum ProductFormatting {
    static func ratingText(for product: Product) -> String {
        String(
            format: L10n.ratingLabel,
            product.rating.rate.formatted(.number.precision(.fractionLength(Constants.Home.ratingDecimalPlaces))),
            product.rating.count
        )
    }
}
