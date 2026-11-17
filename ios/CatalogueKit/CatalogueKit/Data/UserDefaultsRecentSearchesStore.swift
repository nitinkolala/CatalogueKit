import Foundation

/// Stores recent searches in UserDefaults, under one key.
nonisolated struct UserDefaultsRecentSearchesStore: RecentSearchesStore, @unchecked Sendable {
    let defaults: UserDefaults
    let key: String

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(_ terms: [String]) {
        defaults.set(terms, forKey: key)
    }
}
