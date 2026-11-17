import XCTest
@testable import CatalogueKit

final class FeaturedProductsRepositoryTests: XCTestCase {
    private let baseURL = URL(string: "http://backend.test")!

    private func makeRepository(
        client: HTTPClient,
        cacheFile: URL,
        now: @escaping @Sendable () -> Date,
        ttl: TimeInterval = 300
    ) -> FeaturedProductsRepository {
        FeaturedProductsRepository(
            remote: RemoteProductDataSource(client: client, baseURL: baseURL),
            cache: ProductsDiskCache(fileURL: cacheFile),
            timeToLive: ttl,
            now: now
        )
    }

    func testFetchesFromBackendWhenCacheEmpty() async throws {
        let products = [TestData.product(id: 1)]
        let body = try TestData.wireBody(products)
        let repository = makeRepository(
            client: StubHTTPClient { _ in body },
            cacheFile: TestData.tempFile(),
            now: { Date(timeIntervalSince1970: 0) }
        )

        let result = try await repository.featuredProducts()

        XCTAssertEqual(result.items, products)
        XCTAssertFalse(result.isStale)
    }

    func testServesFreshCacheWithoutCallingBackend() async throws {
        let cacheFile = TestData.tempFile()
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let calls = CallCounter()
        let body = try TestData.wireBody([TestData.product(id: 1)])
        let repository = makeRepository(
            client: StubHTTPClient { _ in calls.increment(); return body },
            cacheFile: cacheFile,
            now: { clock.now }
        )

        _ = try await repository.featuredProducts()
        clock.now = Date(timeIntervalSince1970: 60)
        _ = try await repository.featuredProducts()

        XCTAssertEqual(calls.value, 1)
    }

    func testRefetchesAfterTimeToLive() async throws {
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let calls = CallCounter()
        let body = try TestData.wireBody([TestData.product(id: 1)])
        let repository = makeRepository(
            client: StubHTTPClient { _ in calls.increment(); return body },
            cacheFile: TestData.tempFile(),
            now: { clock.now },
            ttl: 300
        )

        _ = try await repository.featuredProducts()
        clock.now = Date(timeIntervalSince1970: 301)
        _ = try await repository.featuredProducts()

        XCTAssertEqual(calls.value, 2)
    }

    func testFallsBackToStaleCacheWhenBackendFails() async throws {
        let cacheFile = TestData.tempFile()
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let saved = [TestData.product(id: 9)]
        let online = makeRepository(
            client: StubHTTPClient { _ in try TestData.wireBody(saved) },
            cacheFile: cacheFile,
            now: { clock.now }
        )
        _ = try await online.featuredProducts()

        clock.now = Date(timeIntervalSince1970: 10_000)
        let offline = makeRepository(
            client: StubHTTPClient { _ in throw StubError.offline },
            cacheFile: cacheFile,
            now: { clock.now }
        )

        let result = try await offline.featuredProducts()

        XCTAssertEqual(result.items, saved)
        XCTAssertTrue(result.isStale, "A saved list served while offline must be flagged as stale")
    }

    func testForceRefreshBypassesFreshCache() async throws {
        let cacheFile = TestData.tempFile()
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let calls = CallCounter()
        let body = try TestData.wireBody([TestData.product(id: 1)])
        let repository = makeRepository(
            client: StubHTTPClient { _ in calls.increment(); return body },
            cacheFile: cacheFile,
            now: { clock.now }
        )

        _ = try await repository.featuredProducts(forceRefresh: false)
        _ = try await repository.featuredProducts(forceRefresh: true)

        XCTAssertEqual(calls.value, 2)
    }

    func testThrowsWhenBackendFailsAndNothingCached() async {
        let repository = makeRepository(
            client: StubHTTPClient { _ in throw StubError.offline },
            cacheFile: TestData.tempFile(),
            now: { Date() }
        )

        do {
            _ = try await repository.featuredProducts()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? StubError, .offline)
        }
    }
}

/// Mutable clock for deterministic cache-expiry tests.
final class Clock: @unchecked Sendable {
    var now: Date
    init(_ now: Date) { self.now = now }
}
