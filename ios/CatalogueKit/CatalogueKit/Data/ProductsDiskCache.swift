import Foundation

/// Keeps the last successful featured list in memory and on disk, with the time it was saved.
actor ProductsDiskCache {
    struct Entry: Codable, Sendable {
        let savedAt: Date
        let products: [Product]
    }

    private let fileURL: URL
    private var memory: Entry?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    static func defaultFileURL() throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let directory = caches.appending(path: Constants.Cache.directoryName, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: Constants.Cache.productsFileName)
    }

    func load() -> Entry? {
        if let memory { return memory }
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(Entry.self, from: data) else {
            return nil
        }
        memory = entry
        return entry
    }

    func save(_ products: [Product], at date: Date) {
        let entry = Entry(savedAt: date, products: products)
        memory = entry
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }
}
