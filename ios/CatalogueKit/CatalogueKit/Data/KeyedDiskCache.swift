import Foundation

/// A small JSON file on disk that holds several saved values, each under a key, with the time it was saved.
actor KeyedDiskCache<Value: Codable & Sendable> {
    struct Entry: Codable, Sendable {
        let savedAt: Date
        let value: Value
    }

    private let fileURL: URL
    private var entries: [String: Entry]?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load(key: String) -> Entry? {
        allEntries()[key]
    }

    func save(_ value: Value, key: String, at date: Date) {
        var all = allEntries()
        all[key] = Entry(savedAt: date, value: value)
        entries = all
        guard let data = try? JSONEncoder().encode(all) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    private func allEntries() -> [String: Entry] {
        if let entries { return entries }
        let loaded = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: Entry].self, from: $0) } ?? [:]
        entries = loaded
        return loaded
    }
}
