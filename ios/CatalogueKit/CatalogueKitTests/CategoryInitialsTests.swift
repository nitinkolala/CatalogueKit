import XCTest
@testable import CatalogueKit

final class CategoryInitialsTests: XCTestCase {
    func testTwoWordsUseFirstLetterOfEach() {
        XCTAssertEqual(CategoryInitials.make(from: "Men's Clothing"), "MC")
        XCTAssertEqual(CategoryInitials.make(from: "Women's Clothing"), "WC")
    }

    func testSingleWordUsesFirstTwoCharacters() {
        XCTAssertEqual(CategoryInitials.make(from: "Electronics"), "EL")
        XCTAssertEqual(CategoryInitials.make(from: "Jewelery"), "JE")
    }

    func testShortSingleWordUsesWhatIsThere() {
        XCTAssertEqual(CategoryInitials.make(from: "A"), "A")
    }

    func testExtraWordsAreIgnored() {
        XCTAssertEqual(CategoryInitials.make(from: "Home  and Garden"), "HA")
    }
}
