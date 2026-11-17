import Foundation

nonisolated struct Product: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let imageURL: URL
    /// False when out of stock or unavailable. The product can still be viewed.
    let available: Bool
    let rating: Rating

    nonisolated struct Rating: Codable, Equatable, Hashable, Sendable {
        let rate: Double
        let count: Int
    }
}
