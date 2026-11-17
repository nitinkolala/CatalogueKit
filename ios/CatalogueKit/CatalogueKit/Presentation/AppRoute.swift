import Foundation

/// Destinations pushed onto the Home navigation stack.
nonisolated enum AppRoute: Hashable, Sendable {
    case product(Product)
    case category(ProductCategory)
    case enquiry(Product)
}
