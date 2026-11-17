import Foundation

/// Rules for the recent-searches list: newest first, no duplicates (ignoring case), capped at a limit.
nonisolated enum RecentSearches {
    static func adding(_ term: String, to terms: [String], limit: Int) -> [String] {
        let key = term.lowercased()
        let kept = terms.filter { $0.lowercased() != key }
        return Array(([term] + kept).prefix(limit))
    }
}

/// Keeps recent searches on the device between launches.
nonisolated protocol RecentSearchesStore: Sendable {
    func load() -> [String]
    func save(_ terms: [String])
}

/// Tells the search screen when the device can reach the network again.
nonisolated protocol ConnectivityMonitor: Sendable {
    /// Returns once the device has a usable connection. Returns at once when it is already online.
    func waitUntilOnline() async
}
