import Foundation

/// Search backed by the catalogue backend. Maps network failures to the errors the screen understands.
nonisolated struct RemoteProductSearchRepository: ProductSearchRepository {
    /// URL error codes that mean the device has no usable connection.
    static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .internationalRoamingOff,
    ]

    let remote: RemoteProductDataSource

    func search(_ request: ProductSearchRequest) async throws -> ProductPage {
        do {
            return try await remote.searchProducts(request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            throw SearchError.offline
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw SearchError.service
        }
    }
}
