import XCTest
@testable import CatalogueKit

final class CacheLocationTests: XCTestCase {
    private let stagingURL = URL(string: "https://staging.api.example.com")!
    private let productionURL = URL(string: "https://api.example.com")!

    func testEachEnvironmentGetsItsOwnFolder() {
        let staging = CacheLocation.folderName(for: .staging, baseURL: stagingURL)
        let production = CacheLocation.folderName(for: .production, baseURL: productionURL)

        XCTAssertNotEqual(staging, production)
        XCTAssertTrue(staging.hasPrefix("staging-"))
        XCTAssertTrue(production.hasPrefix("production-"))
    }

    func testTwoServersInTheSameEnvironmentGetDifferentFolders() {
        let local = CacheLocation.folderName(for: .develop, baseURL: URL(string: "http://localhost:3000")!)
        let other = CacheLocation.folderName(for: .develop, baseURL: URL(string: "http://localhost:3100")!)

        XCTAssertNotEqual(local, other, "Pointing a debug build at another server must not reuse its cache")
    }

    func testFolderNameIsStableForTheSameBackend() {
        XCTAssertEqual(
            CacheLocation.folderName(for: .production, baseURL: productionURL),
            CacheLocation.folderName(for: .production, baseURL: productionURL)
        )
    }

    func testFolderNameDoesNotContainTheHost() {
        let name = CacheLocation.folderName(for: .production, baseURL: productionURL)

        XCTAssertFalse(name.contains("example"))
        XCTAssertEqual(name.count, "production-".count + Constants.Cache.folderHashBytes * 2)
    }

    func testSubdirectoryIsCreated() throws {
        let parent = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

        let images = try CacheLocation.subdirectory(Constants.Cache.imagesFolderName, in: parent)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: images.path(), isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
