import CryptoKit
import Foundation
import UIKit

/// Loads product images through a memory cache, then a disk cache, then the network.
actor ImageLoader {
    private let client: HTTPClient
    private let diskDirectory: URL
    private let memory = NSCache<NSURL, UIImage>()

    init(client: HTTPClient, diskDirectory: URL) {
        self.client = client
        self.diskDirectory = diskDirectory
    }

    static func defaultDiskDirectory() throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let directory = caches.appending(path: "\(Constants.Cache.directoryName)/images", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = memory.object(forKey: url as NSURL) {
            return cached
        }
        let file = diskFile(for: url)
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            memory.setObject(image, forKey: url as NSURL)
            return image
        }
        guard let data = try? await client.data(from: url), let image = UIImage(data: data) else {
            return nil
        }
        memory.setObject(image, forKey: url as NSURL)
        try? data.write(to: file, options: .atomic)
        return image
    }

    private func diskFile(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return diskDirectory.appending(path: name)
    }
}
