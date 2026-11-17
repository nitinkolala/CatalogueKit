import Foundation

/// User-facing strings. Keys live in `Resources/Localizable.strings`.
nonisolated enum L10n {
    static let homeTitle = String(localized: "home.title")
    static let homeEmpty = String(localized: "home.empty")
    static let homeLoadFailed = String(localized: "home.load_failed")
    static let homeRetry = String(localized: "home.retry")
    static let ratingLabel = String(localized: "home.rating_label")
    static let outOfStock = String(localized: "product.out_of_stock")
}
