import CryptoKit
import Foundation
import UIKit

/// Loads product images through a memory cache, then a disk cache, then the network.
///
/// - Requests for the same image share one download, even when several views ask at the same time.
/// - Images are decoded at the size they are shown, not at full size, and decoding runs off this actor.
/// - The memory cache has a byte budget and drops the least recently used images beyond it.
actor ImageLoader {
    private let client: HTTPClient
    private let diskDirectory: URL
    private let memory = NSCache<NSString, UIImage>()
    /// Downloads in progress, keyed by URL. Every caller for the same URL awaits the same task.
    private var dataTasks: [URL: Task<Data?, Never>] = [:]
    /// Decodes in progress, keyed by URL and size.
    private var imageTasks: [String: Task<UIImage?, Never>] = [:]

    init(client: HTTPClient, diskDirectory: URL, memoryLimitBytes: Int = Constants.Images.memoryCacheBytes) {
        self.client = client
        self.diskDirectory = diskDirectory
        memory.totalCostLimit = memoryLimitBytes
    }

    /// Returns the image at `url`, decoded so its longest side is at most `maxPixelSize` pixels.
    func image(for url: URL, maxPixelSize: Int) async -> UIImage? {
        let key = Self.cacheKey(url: url, maxPixelSize: maxPixelSize)
        if let cached = memory.object(forKey: key as NSString) {
            return cached
        }
        if let running = imageTasks[key] {
            return await running.value
        }

        let task = Task<UIImage?, Never> {
            guard let data = await self.data(for: url) else { return nil }
            return await Task.detached(priority: .userInitiated) {
                ImageDecoder.downsample(data, maxPixelSize: maxPixelSize)
            }.value
        }
        imageTasks[key] = task
        let image = await task.value

        if let image {
            memory.setObject(image, forKey: key as NSString, cost: image.decodedByteCount)
        } else {
            // A file that cannot be decoded is removed, so the next request downloads it again.
            try? FileManager.default.removeItem(at: diskFile(for: url))
        }
        imageTasks[key] = nil
        return image
    }

    /// The image's bytes from disk, or from the network if they are not on disk yet.
    private func data(for url: URL) async -> Data? {
        if let running = dataTasks[url] {
            return await running.value
        }
        let file = diskFile(for: url)
        let task = Task.detached(priority: .userInitiated) { [client] () -> Data? in
            if let saved = try? Data(contentsOf: file) {
                return saved
            }
            guard let downloaded = try? await client.data(from: url) else { return nil }
            try? downloaded.write(to: file, options: .atomic)
            return downloaded
        }
        dataTasks[url] = task
        let data = await task.value
        dataTasks[url] = nil
        return data
    }

    private func diskFile(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return diskDirectory.appending(path: name)
    }

    static func cacheKey(url: URL, maxPixelSize: Int) -> String {
        "\(maxPixelSize)|\(url.absoluteString)"
    }
}
