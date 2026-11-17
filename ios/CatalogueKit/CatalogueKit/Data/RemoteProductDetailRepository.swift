import Foundation

/// Product detail backed by the catalogue backend. Maps network failures to the errors the product page understands.
nonisolated struct RemoteProductDetailRepository: ProductDetailRepository {
    let remote: RemoteProductDataSource

    func product(id: Int) async throws -> Product {
        do {
            return try await remote.product(id: id)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where RemoteProductSearchRepository.offlineCodes.contains(error.code) {
            throw ProductLoadError.offline
        } catch HTTPError.unexpectedStatus(404) {
            throw ProductLoadError.notFound
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ProductLoadError.service
        }
    }
}

/// Wire format of `GET /products/:id` on the backend.
nonisolated struct ProductItemDTO: Decodable, Sendable {
    let item: ProductDTO
}
