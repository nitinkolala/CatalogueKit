import SwiftUI

/// The Enquiry page for one product. Name, email and message are required. Phone is optional.
///
/// The page is grouped into cards rather than a plain form. Quick questions fill the message in one tap. The bottom
/// dock says what is still needed, so Submit is never a mystery.
struct EnquiryView: View {
    @State private var viewModel: EnquiryViewModel
    @FocusState private var focus: EnquiryField?
    @State private var showDiscardConfirm = false
    @Environment(\.dismiss) private var dismiss

    private let quickPrompts = [
        L10n.enquiryPromptStock,
        L10n.enquiryPromptDelivery,
        L10n.enquiryPromptWarranty
    ]

    init(viewModel: EnquiryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if viewModel.phase == .sent {
                        thankYou
                    } else {
                        content
                    }
                }
                .padding(Constants.Home.gridSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.pendingFocus) { _, field in
                guard let field else { return }
                withAnimation { proxy.scrollTo(field, anchor: .center) }
                focus = field
                viewModel.pendingFocus = nil
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.enquiryTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    backTapped()
                } label: {
                    Label(L10n.enquiryBack, systemImage: "chevron.backward")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                // Name and email move on with Return. Phone and message have no way to finish, so they get Done.
                if focus == .phone || focus == .message {
                    Spacer()
                    Button(L10n.enquiryDone) { focus = nil }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.phase != .sent {
                submitDock
            }
        }
        .confirmationDialog(L10n.enquiryDiscardTitle, isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button(L10n.enquiryDiscard, role: .destructive) { dismiss() }
            Button(L10n.enquiryKeepWriting, role: .cancel) {}
        }
        .onChange(of: focus) { previous, _ in
            if let previous { viewModel.fieldDidEndEditing(previous) }
        }
    }

    /// Back asks before throwing away typed text. Without typed text it simply goes back.
    private func backTapped() {
        if viewModel.hasUnsavedInput {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Constants.Enquiry.sectionSpacing) {
            productCard
            if case .failed(let error) = viewModel.phase {
                failureBanner(error)
            }
            quickQuestions
            detailsCard
            messageCard
            consentCard
        }
    }

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.enquiryAboutLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(viewModel.product.title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Enquiry.tilePadding)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.Enquiry.cardCornerRadius))
    }

    private var quickQuestions: some View {
        VStack(alignment: .leading, spacing: Constants.Enquiry.chipSpacing) {
            Text(L10n.enquiryQuickTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Enquiry.chipSpacing) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button(prompt) {
                            viewModel.applyQuickPrompt(prompt)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .frame(minHeight: Constants.Enquiry.minTouchTarget)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            fieldRow(.name, icon: "person.fill", label: L10n.enquiryNameLabel) {
                TextField("", text: $viewModel.draft.name, onEditingChanged: { editing in
                    if !editing { viewModel.fieldDidEndEditing(.name) }
                })
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit { focus = .email }
            }
            cardDivider
            fieldRow(.email, icon: "envelope.fill", label: L10n.enquiryEmailLabel) {
                TextField("", text: $viewModel.draft.email, onEditingChanged: { editing in
                    if !editing { viewModel.fieldDidEndEditing(.email) }
                })
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .onSubmit { focus = .phone }
            }
            cardDivider
            fieldRow(.phone, icon: "phone.fill", label: L10n.enquiryPhoneLabel) {
                TextField("", text: $viewModel.draft.phone, onEditingChanged: { editing in
                    if !editing { viewModel.fieldDidEndEditing(.phone) }
                })
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .submitLabel(.next)
                .onSubmit { focus = .message }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.Enquiry.cardCornerRadius))
    }

    private var messageCard: some View {
        fieldRow(.message, icon: "text.bubble.fill", label: L10n.enquiryMessageLabel) {
            VStack(alignment: .leading, spacing: Constants.Enquiry.chipSpacing) {
                ZStack(alignment: .topLeading) {
                    if viewModel.draft.message.isEmpty {
                        Text(L10n.enquiryMessagePlaceholder)
                            .foregroundStyle(.tertiary)
                            .padding(.top, Constants.Enquiry.editorInset)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.draft.message)
                        .padding(.leading, -Constants.Enquiry.editorInset)
                        .frame(minHeight: Constants.Enquiry.messageMinHeight)
                }
                if viewModel.draft.message.count >= EnquiryLimits.counterThreshold {
                    Text(L10n.enquiryCounter(viewModel.draft.message.count, EnquiryLimits.messageMaxLength))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.Enquiry.cardCornerRadius))
    }

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: Constants.Enquiry.rowSpacing) {
            Toggle(L10n.enquiryMarketing, isOn: $viewModel.draft.marketingConsent)
                .frame(minHeight: Constants.Enquiry.minTouchTarget)
            Text(L10n.enquiryPrivacy)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link(L10n.enquiryPrivacyLink, destination: Constants.Enquiry.privacyPolicyURL)
                .font(.footnote)
        }
        .padding(Constants.Enquiry.tilePadding)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.Enquiry.cardCornerRadius))
    }

    private var cardDivider: some View {
        Divider().padding(.leading, Constants.Enquiry.dividerInset)
    }

    /// One row in a card: an icon, a small label above the input, and any error text under it.
    private func fieldRow<Content: View>(
        _ field: EnquiryField,
        icon: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let error = viewModel.errorText(for: field)
        return HStack(alignment: .top, spacing: Constants.Enquiry.rowSpacing) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(error == nil ? Color.secondary : Color.red)
                .frame(width: Constants.Enquiry.iconSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(error == nil ? Color.secondary : Color.red)
                content()
                    .focused($focus, equals: field)
                    .accessibilityLabel(label)
                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Constants.Enquiry.tilePadding)
        .frame(minHeight: Constants.Enquiry.minTouchTarget, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { focus = field }
        .id(field)
    }

    /// One opaque bar pinned above the keyboard. The button says what is missing while it is disabled,
    /// so there is no separate caption to read.
    private var submitDock: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            HStack(spacing: Constants.Home.gridSpacing / 2) {
                if viewModel.isSubmitting {
                    ProgressView()
                }
                Text(submitTitle)
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!viewModel.canSubmit)
        .padding(Constants.Home.gridSpacing)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var submitTitle: String {
        let missing = viewModel.missingRequiredFields
        guard !viewModel.canSubmit, !missing.isEmpty else { return L10n.enquirySubmit }
        return L10n.enquiryMissing(missing.map(Self.title(for:)).joined(separator: ", "))
    }

    private static func title(for field: EnquiryField) -> String {
        switch field {
        case .name: return L10n.enquiryNameLabel
        case .email: return L10n.enquiryEmailLabel
        case .phone: return L10n.enquiryPhoneLabel
        case .message: return L10n.enquiryMessageLabel
        }
    }

    private func failureBanner(_ error: EnquiryError) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Constants.Home.gridSpacing / 2) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            Text(error == .offline ? L10n.enquiryOffline : L10n.enquiryFailed)
                .font(.subheadline)
            Spacer(minLength: 0)
            Button(L10n.homeRetry) {
                Task { await viewModel.submit() }
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(Constants.Enquiry.tilePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.Enquiry.cardCornerRadius))
    }

    private var thankYou: some View {
        VStack(spacing: Constants.Home.gridSpacing) {
            Spacer(minLength: Constants.Home.sectionSpacing)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Constants.Enquiry.successIconSize))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text(L10n.enquirySentTitle)
                .font(.title2.bold())
            Text(L10n.enquirySentBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(L10n.enquiryBackToProduct) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .frame(minHeight: Constants.Enquiry.minTouchTarget)
            .padding(.top, Constants.Home.sectionSpacing)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.Home.sectionSpacing)
    }
}
