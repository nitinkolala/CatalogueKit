import Foundation

/// One search call: the text, the optional category scope, and which slice of results to fetch.
nonisolated struct ProductSearchRequest: Equatable, Sendable {
    let query: String
    let category: ProductCategory?
    let offset: Int
    let limit: Int
}

/// One page of search results.
nonisolated struct ProductPage: Equatable, Sendable {
    let items: [Product]
    let total: Int
    let hasMore: Bool
}

/// Why a search failed, in terms the screen can explain to the customer.
nonisolated enum SearchError: Error, Equatable, Sendable {
    case offline
    case service
}

/// Where search results come from. The implementation decides the network source.
nonisolated protocol ProductSearchRepository: Sendable {
    func search(_ request: ProductSearchRequest) async throws -> ProductPage
}
