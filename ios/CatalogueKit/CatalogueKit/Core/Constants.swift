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
        static let featuredCardWidth: CGFloat = 185
        static let featuredArrowSize: CGFloat = 36
        static let featuredArrowShadowOpacity = 0.15
        static let featuredArrowFadeDuration: Double = 0.2
        /// Sub-point slack when deciding whether the row can still scroll, so rounding never shows a stray arrow.
        static let scrollEdgeTolerance: CGFloat = 1
        static let cardCornerRadius: CGFloat = 12
        static let cardImageHeight: CGFloat = 160
        static let detailImageHeight: CGFloat = 280
        static let cardPadding: CGFloat = 8
        static let ratingDecimalPlaces = 1
        static let sectionSpacing: CGFloat = 24
        static let categoryMinimumWidth: CGFloat = 150
        static let categoryTileHeight: CGFloat = 64
        static let categoryPlaceholderCount = 4
        static let categoryBadgeSize: CGFloat = 36
        static let categoryInitialsLength = 2
        static let categoryInitialWordCount = 2
        static let colorChannelMax = 255
        static let categoryCornerRadius: CGFloat = 14
    }

    enum Currency {
        static let code = "USD"
    }

    enum Search {
        static let minLength = 2
        static let maxLength = 100
        /// Quiet time after the last keystroke before a request is sent.
        static let debounce: Duration = .milliseconds(300)
        static let pageSize = 20
        static let recentLimit = 5
        /// Minimum gap between two VoiceOver announcements of the result count.
        static let announcementThrottle: TimeInterval = 1
        static let recentSearchesKey = "catalogue.recentSearches"
        static let recentIconName = "clock"
        /// Apple's minimum comfortable tap target.
        static let touchTarget: CGFloat = 44
    }
}
