import Foundation

/// Sends enquiries to the catalogue backend. Maps network failures to the errors the form understands.
nonisolated struct RemoteEnquiryRepository: EnquiryRepository {
    let client: HTTPClient
    let baseURL: URL

    func submit(_ request: EnquiryRequest) async throws {
        let body = EnquiryBody(
            productId: request.productId,
            name: request.name,
            email: request.email,
            phone: request.phone,
            message: request.message,
            marketingConsent: request.marketingConsent
        )
        do {
            let data = try JSONEncoder().encode(body)
            _ = try await client.post(baseURL.appending(path: "enquiries"), body: data)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where RemoteProductSearchRepository.offlineCodes.contains(error.code) {
            throw EnquiryError.offline
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw EnquiryError.service
        }
    }
}

/// Wire format of `POST /enquiries`.
nonisolated struct EnquiryBody: Encodable, Sendable {
    let productId: Int
    let name: String
    let email: String
    let phone: String?
    let message: String
    let marketingConsent: Bool
}
