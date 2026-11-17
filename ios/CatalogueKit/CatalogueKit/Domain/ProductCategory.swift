import Foundation

/// A product category as the backend names it, for example "electronics".
nonisolated struct ProductCategory: Codable, Hashable, Identifiable, Sendable {
    let name: String

    var id: String { name }
    var displayName: String { name.capitalized }
}
