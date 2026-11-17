import Foundation

/// The fields on the Enquiry form.
nonisolated enum EnquiryField: Hashable, CaseIterable, Sendable {
    case name
    case email
    case phone
    case message
}

/// Why a field is wrong. The screen turns these into text, so the message is never colour alone.
nonisolated enum EnquiryIssue: Equatable, Sendable {
    case nameRequired
    case emailInvalid
    case phoneInvalid
    case messageRequired
}

/// Limits shared by the form and its validation.
nonisolated enum EnquiryLimits {
    static let nameMaxLength = 100
    static let messageMaxLength = 1000
    /// Show the character counter once the message gets this close to the limit.
    static let counterThreshold = 900
}

/// The values the customer typed, before trimming.
nonisolated struct EnquiryDraft: Equatable, Sendable {
    var name = ""
    var email = ""
    var phone = ""
    var message = ""
    var marketingConsent = false

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedPhone: String { phone.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedMessage: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasAnyText: Bool {
        !trimmedName.isEmpty || !trimmedEmail.isEmpty || !trimmedPhone.isEmpty || !trimmedMessage.isEmpty
    }

    /// Name, email and message are required. The phone number is optional, but must be valid when it is typed.
    var requiredFieldsAreFilled: Bool {
        !trimmedName.isEmpty && EmailValidator.isValid(trimmedEmail) && !trimmedMessage.isEmpty
            && trimmedName.count <= EnquiryLimits.nameMaxLength && trimmedMessage.count <= EnquiryLimits.messageMaxLength
    }

    /// The issue for one field, or nil when it is valid.
    func issue(for field: EnquiryField) -> EnquiryIssue? {
        switch field {
        case .name:
            return trimmedName.isEmpty || trimmedName.count > EnquiryLimits.nameMaxLength ? .nameRequired : nil
        case .email:
            return EmailValidator.isValid(trimmedEmail) ? nil : .emailInvalid
        case .phone:
            return trimmedPhone.isEmpty || MobileValidator.isValid(trimmedPhone) ? nil : .phoneInvalid
        case .message:
            return trimmedMessage.isEmpty || trimmedMessage.count > EnquiryLimits.messageMaxLength ? .messageRequired : nil
        }
    }

    /// The first field, in form order, that has an issue.
    var firstIssueField: EnquiryField? {
        EnquiryField.allCases.first { issue(for: $0) != nil }
    }
}
