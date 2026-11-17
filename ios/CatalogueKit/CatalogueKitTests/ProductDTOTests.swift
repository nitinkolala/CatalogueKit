import XCTest
@testable import CatalogueKit

final class ProductDTOTests: XCTestCase {
    private let sampleJSON = """
    {"items":[{"id":3,"title":"Jacket","price":22.3,"description":"Warm","category":"men",
    "imageUrl":"https://img.test/3.jpg","rating":{"rate":4.7,"count":500}}]}
    """

    func testDecodesBackendListAndMapsToDomain() throws {
        let list = try JSONDecoder().decode(ProductListDTO.self, from: Data(sampleJSON.utf8))
        let product = try list.items[0].toDomain()

        XCTAssertEqual(product.id, 3)
        XCTAssertEqual(product.title, "Jacket")
        XCTAssertEqual(product.imageURL, URL(string: "https://img.test/3.jpg"))
        XCTAssertEqual(product.rating, Product.Rating(rate: 4.7, count: 500))
    }

    func testMissingAvailabilityDefaultsToAvailable() throws {
        let product = try ProductDTO(
            id: 1, title: "t", price: 1, description: "", category: "c",
            imageUrl: "https://img.test/1.jpg", available: nil, rating: .init(rate: 1, count: 1)
        ).toDomain()

        XCTAssertTrue(product.available)
    }

    func testOutOfStockFlagIsMapped() throws {
        let product = try ProductDTO(
            id: 1, title: "t", price: 1, description: "", category: "c",
            imageUrl: "https://img.test/1.jpg", available: false, rating: .init(rate: 1, count: 1)
        ).toDomain()

        XCTAssertFalse(product.available)
    }

    func testRejectsMalformedImageURL() throws {
        let dto = ProductDTO(
            id: 1, title: "t", price: 1, description: "", category: "c",
            imageUrl: "http://[bad", available: nil, rating: .init(rate: 1, count: 1)
        )

        XCTAssertThrowsError(try dto.toDomain()) { error in
            XCTAssertEqual(error as? ProductMappingError, .invalidImageURL("http://[bad"))
        }
    }
}
