import XCTest
@testable import CatalogueKit

final class HTTPClientTests: XCTestCase {
    /// Fails every request with the error code chosen by the test, without touching the network.
    private final class FailingURLProtocol: URLProtocol {
        nonisolated(unsafe) static var errorCode: URLError.Code = .cancelled

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            client?.urlProtocol(self, didFailWithError: URLError(Self.errorCode))
        }
        override func stopLoading() {}
    }

    private func client() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FailingURLProtocol.self]
        return URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    private let url = URL(string: "http://backend.test/products/featured")!

    func testCancelledRequestIsReportedAsCancellationError() async {
        FailingURLProtocol.errorCode = .cancelled

        do {
            _ = try await client().data(from: url)
            XCTFail("Expected an error")
        } catch {
            XCTAssertTrue(error is CancellationError, "A cancelled request must not look like a network failure")
        }
    }

    func testOfflineRequestStillReportsTheURLError() async {
        FailingURLProtocol.errorCode = .notConnectedToInternet

        do {
            _ = try await client().data(from: url)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }
}
