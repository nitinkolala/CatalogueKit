import Foundation

/// Products in one category: the top-rated ones first, then the rest in the same order.
nonisolated struct CategoryProducts: Codable, Equatable, Sendable {
    let topRated: [Product]
    let more: [Product]
}
