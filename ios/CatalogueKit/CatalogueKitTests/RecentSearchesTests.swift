import XCTest
@testable import CatalogueKit

final class RecentSearchesTests: XCTestCase {
    func testNewestSearchGoesFirst() {
        let terms = RecentSearches.adding("lamp", to: ["gaming"], limit: 5)
        XCTAssertEqual(terms, ["lamp", "gaming"])
    }

    func testRepeatIgnoringCaseMovesToTheFront() {
        let terms = RecentSearches.adding("Lamp", to: ["gaming", "lamp"], limit: 5)
        XCTAssertEqual(terms, ["Lamp", "gaming"])
    }

    func testListIsCappedAtTheLimit() {
        var terms: [String] = []
        for index in 1...7 {
            terms = RecentSearches.adding("term\(index)", to: terms, limit: 5)
        }
        XCTAssertEqual(terms, ["term7", "term6", "term5", "term4", "term3"])
    }

    func testStoreSavesAndLoadsUnderItsKey() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "RecentSearchesTests"))
        defer { suite.removePersistentDomain(forName: "RecentSearchesTests") }
        let store = UserDefaultsRecentSearchesStore(defaults: suite, key: "test.key")

        XCTAssertEqual(store.load(), [])
        store.save(["gaming", "lamp"])
        XCTAssertEqual(store.load(), ["gaming", "lamp"])
    }
}
