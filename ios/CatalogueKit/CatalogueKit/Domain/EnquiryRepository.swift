import Foundation

/// A validated enquiry ready to send. Values are already trimmed.
nonisolated struct EnquiryRequest: Equatable, Sendable {
    let productId: Int
    let name: String
    let email: String
    let phone: String?
    let message: String
    let marketingConsent: Bool
}

/// Why an enquiry could not be sent.
nonisolated enum EnquiryError: Error, Equatable, Sendable {
    case offline
    case service
}

/// Where enquiries are sent. The implementation decides the network source.
nonisolated protocol EnquiryRepository: Sendable {
    func submit(_ request: EnquiryRequest) async throws
}

nonisolated protocol SubmitEnquiryUseCase: Sendable {
    func execute(_ request: EnquiryRequest) async throws
}

/// Sends an enquiry through the repository.
nonisolated struct DefaultSubmitEnquiryUseCase: SubmitEnquiryUseCase {
    let repository: EnquiryRepository

    func execute(_ request: EnquiryRequest) async throws {
        try await repository.submit(request)
    }
}
