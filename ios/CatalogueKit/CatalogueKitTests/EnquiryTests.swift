import XCTest
@testable import CatalogueKit

final class ValidatorTests: XCTestCase {
    func testStrictEmailAcceptsNormalAddresses() {
        XCTAssertTrue(EmailValidator.isValid("sam@example.com"))
        XCTAssertTrue(EmailValidator.isValid("first.last+tag@shop.co.au"))
    }

    func testStrictEmailRejectsIncompleteAddresses() {
        XCTAssertFalse(EmailValidator.isValid("sam@example"))
        XCTAssertFalse(EmailValidator.isValid("sam example@x.com"))
        XCTAssertFalse(EmailValidator.isValid("no-at-sign.com"))
        XCTAssertFalse(EmailValidator.isValid("sam@@example.com"))
        XCTAssertFalse(EmailValidator.isValid("sam@example.c"))
        XCTAssertFalse(EmailValidator.isValid(""))
    }

    func testMobileNeedsExactlyTenDigits() {
        XCTAssertTrue(MobileValidator.isValid("0412345678"))
        XCTAssertFalse(MobileValidator.isValid("041234567"), "9 digits")
        XCTAssertFalse(MobileValidator.isValid("04123456789"), "11 digits")
    }

    func testMobileIgnoresFormattingCharacters() {
        XCTAssertTrue(MobileValidator.isValid("(04) 1234-5678"))
        XCTAssertTrue(MobileValidator.isValid("041.234.5678"))
        XCTAssertFalse(MobileValidator.isValid("04ab345678"))
    }
}

final class EnquiryDraftTests: XCTestCase {
    private func validDraft() -> EnquiryDraft {
        var draft = EnquiryDraft()
        draft.name = "  Sam Lee  "
        draft.email = " sam@example.com "
        draft.message = "Is it in stock?"
        return draft
    }

    func testValidDraftHasNoIssues() {
        let draft = validDraft()
        XCTAssertTrue(draft.requiredFieldsAreFilled)
        XCTAssertNil(draft.firstIssueField)
    }

    func testBlankRequiredFieldsAreReportedInFormOrder() {
        let draft = EnquiryDraft()
        XCTAssertFalse(draft.requiredFieldsAreFilled)
        XCTAssertEqual(draft.firstIssueField, .name)
    }

    func testOptionalPhoneIsOnlyWrongWhenTyped() {
        var draft = validDraft()
        XCTAssertNil(draft.issue(for: .phone))
        draft.phone = "123"
        XCTAssertEqual(draft.issue(for: .phone), .phoneInvalid)
        XCTAssertTrue(draft.requiredFieldsAreFilled, "a bad phone does not block the required check")
    }

    func testWhitespaceOnlyNameIsMissing() {
        var draft = validDraft()
        draft.name = "   "
        XCTAssertEqual(draft.issue(for: .name), .nameRequired)
    }
}

@MainActor
final class EnquiryViewModelTests: XCTestCase {
    final class Recorder: @unchecked Sendable {
        var requests: [EnquiryRequest] = []
    }

    struct FakeSubmit: SubmitEnquiryUseCase {
        let recorder: Recorder
        let handler: @Sendable (EnquiryRequest) async throws -> Void

        func execute(_ request: EnquiryRequest) async throws {
            recorder.requests.append(request)
            try await handler(request)
        }
    }

    private let product = TestData.product(id: 7)

    private func makeViewModel(
        recorder: Recorder = Recorder(),
        handler: @escaping @Sendable (EnquiryRequest) async throws -> Void = { _ in },
        announcements: @escaping @MainActor (String) -> Void = { _ in }
    ) -> EnquiryViewModel {
        EnquiryViewModel(
            product: product,
            submitUseCase: FakeSubmit(recorder: recorder, handler: handler),
            announce: announcements
        )
    }

    private func fillValid(_ viewModel: EnquiryViewModel) {
        viewModel.draft.name = "Sam Lee"
        viewModel.draft.email = "sam@example.com"
        viewModel.draft.message = "Is it in stock?"
    }

    func testSubmitStaysDisabledUntilRequiredFieldsAreValid() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.canSubmit)
        fillValid(viewModel)
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testMissingRequiredFieldsListsOnlyEmptyOrInvalidRequiredFields() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.missingRequiredFields, [.name, .email, .message])

        viewModel.draft.name = "Sam Lee"
        viewModel.draft.email = "bad"
        XCTAssertEqual(viewModel.missingRequiredFields, [.email, .message])

        fillValid(viewModel)
        viewModel.draft.phone = "12"
        XCTAssertEqual(viewModel.missingRequiredFields, [])
    }

    func testQuickPromptFillsAnEmptyMessage() {
        let viewModel = makeViewModel()
        viewModel.applyQuickPrompt(L10n.enquiryPromptStock)
        XCTAssertEqual(viewModel.draft.message, L10n.enquiryPromptStock)
    }

    func testQuickPromptAddsToExistingMessageWithoutRepeating() {
        let viewModel = makeViewModel()
        viewModel.draft.message = "Hello"
        viewModel.applyQuickPrompt("Is it in stock?")
        viewModel.applyQuickPrompt("Is it in stock?")
        XCTAssertEqual(viewModel.draft.message, "Hello\nIs it in stock?")
    }

    func testErrorsAppearOnlyAfterAFieldIsLeftOrSubmitIsTried() {
        let viewModel = makeViewModel()
        viewModel.draft.email = "bad"
        XCTAssertNil(viewModel.errorText(for: .email))
        viewModel.fieldDidEndEditing(.email)
        XCTAssertNotNil(viewModel.errorText(for: .email))
    }

    func testInvalidEmailBlocksSendAndFocusesTheField() async {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        fillValid(viewModel)
        viewModel.draft.email = "bad"

        await viewModel.submit()

        XCTAssertEqual(viewModel.pendingFocus, .email)
        XCTAssertTrue(recorder.requests.isEmpty)
        XCTAssertEqual(viewModel.phase, .editing)
    }

    func testInvalidPhoneStillLetsTheCustomerSubmitAndFocusesPhone() async {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        fillValid(viewModel)
        viewModel.draft.phone = "12"
        XCTAssertTrue(viewModel.canSubmit)

        await viewModel.submit()

        XCTAssertEqual(viewModel.pendingFocus, .phone)
        XCTAssertTrue(recorder.requests.isEmpty)
    }

    func testSuccessSendsTrimmedValuesAndClearsTheForm() async {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        viewModel.draft.name = "  Sam Lee "
        viewModel.draft.email = " sam@example.com "
        viewModel.draft.phone = "(04) 1234-5678"
        viewModel.draft.message = "  Is it in stock?  "

        await viewModel.submit()

        XCTAssertEqual(viewModel.phase, .sent)
        XCTAssertEqual(recorder.requests.count, 1)
        let sent = recorder.requests[0]
        XCTAssertEqual(sent.productId, 7)
        XCTAssertEqual(sent.name, "Sam Lee")
        XCTAssertEqual(sent.email, "sam@example.com")
        XCTAssertEqual(sent.phone, "0412345678")
        XCTAssertEqual(sent.message, "Is it in stock?")
        XCTAssertEqual(viewModel.draft, EnquiryDraft(), "the form clears after a successful send")
        XCTAssertFalse(viewModel.canSubmit, "the sent form cannot be sent again")
    }

    func testFailureKeepsEverythingTyped() async {
        let viewModel = makeViewModel(handler: { _ in throw EnquiryError.offline })
        fillValid(viewModel)

        await viewModel.submit()

        XCTAssertEqual(viewModel.phase, .failed(.offline))
        XCTAssertEqual(viewModel.draft.name, "Sam Lee")
        XCTAssertEqual(viewModel.draft.message, "Is it in stock?")
    }

    func testRetryAfterFailureSendsAgain() async {
        let calls = CallCounter()
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder, handler: { _ in
            let call = calls.value
            calls.increment()
            if call == 0 { throw EnquiryError.service }
        })
        fillValid(viewModel)

        await viewModel.submit()
        XCTAssertEqual(viewModel.phase, .failed(.service))

        await viewModel.submit()
        XCTAssertEqual(viewModel.phase, .sent)
        XCTAssertEqual(recorder.requests.count, 2)
    }

    func testMessageIsCappedAtTheLimit() {
        let viewModel = makeViewModel()
        viewModel.draft.message = String(repeating: "a", count: EnquiryLimits.messageMaxLength + 50)
        XCTAssertEqual(viewModel.draft.message.count, EnquiryLimits.messageMaxLength)
    }

    func testMarketingConsentIsNotTickedByDefault() {
        XCTAssertFalse(makeViewModel().draft.marketingConsent)
    }

    func testUnsavedInputIsDetected() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.hasUnsavedInput)
        viewModel.draft.name = "Sam"
        XCTAssertTrue(viewModel.hasUnsavedInput)
    }

    func testSuccessAnnouncesTheThankYou() async {
        var messages: [String] = []
        let viewModel = makeViewModel(announcements: { messages.append($0) })
        fillValid(viewModel)

        await viewModel.submit()

        XCTAssertEqual(messages, [L10n.enquirySentAnnouncement])
    }
}

final class RemoteEnquiryRepositoryTests: XCTestCase {
    private let baseURL = URL(string: "https://api.test")!

    func testPostsTheEnquiryAsJSONToTheEnquiriesEndpoint() async throws {
        let captured = CallCounter()
        let client = StubHTTPClient(handler: { _ in Data() }, postHandler: { url, body in
            captured.increment()
            XCTAssertEqual(url, self.baseURL.appending(path: "enquiries"))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["productId"] as? Int, 7)
            XCTAssertEqual(json["email"] as? String, "sam@example.com")
            XCTAssertEqual(json["phone"] as? String, "0412345678")
            return Data(#"{"ok":true}"#.utf8)
        })
        let repository = RemoteEnquiryRepository(client: client, baseURL: baseURL)

        try await repository.submit(EnquiryRequest(
            productId: 7, name: "Sam", email: "sam@example.com", phone: "0412345678",
            message: "Hi", marketingConsent: false
        ))

        XCTAssertEqual(captured.value, 1)
    }

    func testNoNetworkMapsToOffline() async {
        let client = StubHTTPClient(handler: { _ in Data() }, postHandler: { _, _ in throw URLError(.notConnectedToInternet) })
        let repository = RemoteEnquiryRepository(client: client, baseURL: baseURL)
        do {
            try await repository.submit(EnquiryRequest(productId: 1, name: "a", email: "a@b.co", phone: nil, message: "m", marketingConsent: false))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? EnquiryError, .offline)
        }
    }

    func testServerRejectionMapsToService() async {
        let client = StubHTTPClient(handler: { _ in Data() }, postHandler: { _, _ in throw HTTPError.unexpectedStatus(400) })
        let repository = RemoteEnquiryRepository(client: client, baseURL: baseURL)
        do {
            try await repository.submit(EnquiryRequest(productId: 1, name: "a", email: "a@b.co", phone: nil, message: "m", marketingConsent: false))
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? EnquiryError, .service)
        }
    }
}
