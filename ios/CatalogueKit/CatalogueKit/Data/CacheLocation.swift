import CryptoKit
import Foundation

/// Where the app keeps its cached files.
///
/// Each backend gets its own folder, named after the environment and the base URL it talks to, so data saved
/// from one backend is never shown while the app talks to another (for example after switching from staging
/// to production, or after pointing a debug build at a different local server).
nonisolated enum CacheLocation {
    /// The folder for one backend, created if it does not exist yet.
    static func directory(
        for environment: AppEnvironment,
        baseURL: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = try rootDirectory(fileManager)
            .appending(path: folderName(for: environment, baseURL: baseURL), directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// A sub-folder inside a backend's folder, created if it does not exist yet.
    static func subdirectory(
        _ name: String,
        in directory: URL,
        fileManager: FileManager = .default
    ) throws -> URL {
        let subdirectory = directory.appending(path: name, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: subdirectory, withIntermediateDirectories: true)
        return subdirectory
    }

    /// Environment name plus a short hash of the base URL, for example `production-3f9a01c2`.
    /// The hash keeps two servers in the same environment apart without putting a host name in a path.
    static func folderName(for environment: AppEnvironment, baseURL: URL) -> String {
        let digest = SHA256.hash(data: Data(baseURL.absoluteString.utf8))
        let shortHash = digest.prefix(Constants.Cache.folderHashBytes)
            .map { String(format: "%02x", $0) }
            .joined()
        return "\(environment.rawValue)-\(shortHash)"
    }

    /// Removes files saved before caches were split by backend. Which backend wrote them is unknown,
    /// so they are deleted rather than reused.
    static func removeLegacyFiles(fileManager: FileManager = .default) {
        guard let root = try? rootDirectory(fileManager) else { return }
        for name in Constants.Cache.legacyEntryNames {
            try? fileManager.removeItem(at: root.appending(path: name))
        }
    }

    private static func rootDirectory(_ fileManager: FileManager) throws -> URL {
        try fileManager
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: Constants.Cache.directoryName, directoryHint: .isDirectory)
    }
}
