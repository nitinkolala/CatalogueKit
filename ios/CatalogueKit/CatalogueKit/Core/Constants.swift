import CoreGraphics
import Foundation

nonisolated enum Constants {
    enum Network {
        static let requestTimeout: TimeInterval = 10
        static let successStatusRange = 200..<300
    }

    enum Cache {
        /// How long a fetched featured list is served without asking the backend again.
        static let featuredTTL: TimeInterval = 300
        static let directoryName = "CatalogueKitCache"
        static let productsFileName = "featured-products.json"
    }

    enum Home {
        static let featuredCount = 5
        static let gridSpacing: CGFloat = 16
        static let gridMinimumWidth: CGFloat = 160
        static let cardCornerRadius: CGFloat = 12
        static let cardImageHeight: CGFloat = 160
        static let detailImageHeight: CGFloat = 280
        static let cardPadding: CGFloat = 8
        static let ratingDecimalPlaces = 1
    }

    enum Currency {
        static let code = "USD"
    }
}
