import UIKit
import XCTest
@testable import CatalogueKit

final class ImageLoaderTests: XCTestCase {
    private let url = URL(string: "https://img.test/photo.png")!

    private func tempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// A plain PNG of the given size in pixels.
    private func pngData(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testConcurrentRequestsForTheSameImageShareOneDownload() async throws {
        let calls = CallCounter()
        let body = pngData(width: 400, height: 200)
        let loader = ImageLoader(
            client: StubHTTPClient { _ in
                calls.increment()
                // Slow enough that every request below starts before the first download ends.
                Thread.sleep(forTimeInterval: 0.3)
                return body
            },
            diskDirectory: try tempDirectory()
        )

        async let first = loader.image(for: url, maxPixelSize: 100)
        async let second = loader.image(for: url, maxPixelSize: 100)
        async let third = loader.image(for: url, maxPixelSize: 300)
        let images = await [first, second, third]

        XCTAssertTrue(images.allSatisfy { $0 != nil })
        XCTAssertEqual(calls.value, 1, "Three requests for one URL, at two sizes, must download it once")
    }

    func testImageIsDecodedNoLargerThanTheRequestedSize() async throws {
        let loader = ImageLoader(
            client: StubHTTPClient { [body = pngData(width: 2000, height: 1000)] _ in body },
            diskDirectory: try tempDirectory()
        )

        let loaded = await loader.image(for: url, maxPixelSize: 200)
        let image = try XCTUnwrap(loaded)

        let cgImage = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(max(cgImage.width, cgImage.height), 200)
        XCTAssertEqual(cgImage.width, 200)
        XCTAssertEqual(cgImage.height, 100, "The aspect ratio is kept")
    }

    func testSmallImageIsNotEnlarged() async throws {
        let loader = ImageLoader(
            client: StubHTTPClient { [body = pngData(width: 80, height: 40)] _ in body },
            diskDirectory: try tempDirectory()
        )

        let loaded = await loader.image(for: url, maxPixelSize: 500)
        let image = try XCTUnwrap(loaded)

        XCTAssertEqual(image.cgImage?.width, 80)
    }

    func testSecondRequestIsServedWithoutTheNetwork() async throws {
        let calls = CallCounter()
        let body = pngData(width: 100, height: 100)
        let loader = ImageLoader(
            client: StubHTTPClient { _ in calls.increment(); return body },
            diskDirectory: try tempDirectory()
        )

        _ = await loader.image(for: url, maxPixelSize: 50)
        _ = await loader.image(for: url, maxPixelSize: 50)
        _ = await loader.image(for: url, maxPixelSize: 80)

        XCTAssertEqual(calls.value, 1, "The same size comes from memory, a new size is decoded from the disk copy")
    }

    func testDiskCopySurvivesANewLoader() async throws {
        let directory = try tempDirectory()
        let body = pngData(width: 100, height: 100)
        _ = await ImageLoader(client: StubHTTPClient { _ in body }, diskDirectory: directory)
            .image(for: url, maxPixelSize: 50)

        let offline = ImageLoader(client: StubHTTPClient { _ in throw StubError.offline }, diskDirectory: directory)
        let image = await offline.image(for: url, maxPixelSize: 50)

        XCTAssertNotNil(image, "An image saved earlier opens with no network, as after an app restart")
    }

    func testDataThatIsNotAnImageFailsAndIsDownloadedAgainNextTime() async throws {
        let calls = CallCounter()
        let loader = ImageLoader(
            client: StubHTTPClient { _ in calls.increment(); return Data("not an image".utf8) },
            diskDirectory: try tempDirectory()
        )

        let first = await loader.image(for: url, maxPixelSize: 50)
        let second = await loader.image(for: url, maxPixelSize: 50)

        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(calls.value, 2, "A file that cannot be decoded is not kept on disk")
    }

    func testFailedDownloadReturnsNil() async throws {
        let loader = ImageLoader(
            client: StubHTTPClient { _ in throw StubError.offline },
            diskDirectory: try tempDirectory()
        )

        let image = await loader.image(for: url, maxPixelSize: 50)

        XCTAssertNil(image)
    }
}
