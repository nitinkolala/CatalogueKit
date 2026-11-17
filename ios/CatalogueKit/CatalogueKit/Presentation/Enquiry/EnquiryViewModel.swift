import Observation
import SwiftUI

/// Drives the Enquiry form for one product. Validation runs when a field loses focus and again on submit.
/// A failed submit keeps everything typed. A successful one clears the form and shows the thank-you message.
@MainActor
@Observable
final class EnquiryViewModel {
    enum Phase: Equatable {
        case editing
        case submitting
        case sent
        case failed(EnquiryError)
    }

    var draft = EnquiryDraft() {
        didSet {
            if draft.message.count > EnquiryLimits.messageMaxLength {
                draft.message = String(draft.message.prefix(EnquiryLimits.messageMaxLength))
            }
        }
    }

    private(set) var phase: Phase = .editing
    /// Fields the customer has left at least once.
    private(set) var touched: Set<EnquiryField> = []
    private(set) var submitAttempted = false
    /// Set when a submit finds a problem. The view scrolls to and focuses this field, then clears it.
    var pendingFocus: EnquiryField?

    let product: Product
    private let submitUseCase: SubmitEnquiryUseCase
    private let announce: @MainActor (String) -> Void

    init(
        product: Product,
        submitUseCase: SubmitEnquiryUseCase,
        announce: @escaping @MainActor (String) -> Void = { message in
            AccessibilityNotification.Announcement(message).post()
        }
    ) {
        self.product = product
        self.submitUseCase = submitUseCase
        self.announce = announce
    }

    /// Enabled once name, email and message are valid. A typed but invalid phone number still lets the customer
    /// submit, so the form can show the error and scroll to it.
    var canSubmit: Bool {
        draft.requiredFieldsAreFilled && phase != .submitting && phase != .sent
    }

    var isSubmitting: Bool { phase == .submitting }

    var hasUnsavedInput: Bool { draft.hasAnyText && phase != .sent }

    /// Required fields that still need a valid value, in form order. The form uses this to say what is missing.
    var missingRequiredFields: [EnquiryField] {
        [EnquiryField.name, .email, .message].filter { draft.issue(for: $0) != nil }
    }

    /// A quick question fills the message. If text is already there, it is added on a new line, not repeated.
    func applyQuickPrompt(_ text: String) {
        let current = draft.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            draft.message = text
        } else if !current.contains(text) {
            draft.message = current + "\n" + text
        }
    }

    /// Error text for a field. Shown once the field has been left or a submit has been tried.
    func errorText(for field: EnquiryField) -> String? {
        guard touched.contains(field) || submitAttempted, let issue = draft.issue(for: field) else { return nil }
        return Self.text(for: issue)
    }

    static func text(for issue: EnquiryIssue) -> String {
        switch issue {
        case .nameRequired: return L10n.enquiryErrorName
        case .emailInvalid: return L10n.enquiryErrorEmail
        case .phoneInvalid: return L10n.enquiryErrorPhone
        case .messageRequired: return L10n.enquiryErrorMessage
        }
    }

    func fieldDidEndEditing(_ field: EnquiryField) {
        touched.insert(field)
    }

    func submit() async {
        submitAttempted = true
        touched = Set(EnquiryField.allCases)

        if let first = draft.firstIssueField {
            pendingFocus = first
            announce(L10n.enquiryErrorsAnnouncement)
            return
        }
        guard phase != .submitting, phase != .sent else { return }

        phase = .submitting
        let phoneDigits = draft.trimmedPhone.isEmpty ? nil : MobileValidator.normalized(draft.trimmedPhone)
        let request = EnquiryRequest(
            productId: product.id,
            name: draft.trimmedName,
            email: draft.trimmedEmail,
            phone: phoneDigits,
            message: draft.trimmedMessage,
            marketingConsent: draft.marketingConsent
        )

        do {
            try await submitUseCase.execute(request)
            draft = EnquiryDraft()
            touched = []
            submitAttempted = false
            phase = .sent
            announce(L10n.enquirySentAnnouncement)
        } catch is CancellationError {
            phase = .editing
        } catch let error as EnquiryError {
            phase = .failed(error)
            announce(L10n.enquiryFailedAnnouncement)
        } catch {
            phase = .failed(.service)
            announce(L10n.enquiryFailedAnnouncement)
        }
    }
}
