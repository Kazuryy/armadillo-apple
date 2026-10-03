import SwiftUI

/// A screen with one text field and a Save button, used for the settings that need typing
/// (DNS servers, MTU, Wi-Fi network names). The caller supplies the validation and the save.
struct TVTextEntryView: View {
    let title: String
    let explanation: String
    let placeholder: String
    /// Returns an error message when the text isn't acceptable, or nil when it is.
    let validate: (String) -> String?
    /// Stores the trimmed text and returns whether it was accepted.
    let save: (String) -> Bool

    @State private var text: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        explanation: String,
        placeholder: String,
        initialValue: String = "",
        validate: @escaping (String) -> String? = { _ in nil },
        save: @escaping (String) -> Bool
    ) {
        self.title = title
        self.explanation = explanation
        self.placeholder = placeholder
        self.validate = validate
        self.save = save
        _text = State(initialValue: initialValue)
    }

    var body: some View {
        TVScreen(title: title, subtitle: explanation) {
            VStack(spacing: 24) {
                TextField(placeholder, text: $text)
                    .autocorrectionDisabled()
                    .onChange(of: text) { _, _ in errorMessage = nil }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Save") {
                    commit()
                }
                .buttonStyle(TVPrimaryButtonStyle())
            }
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message = validate(trimmed) {
            errorMessage = message
            return
        }
        guard save(trimmed) else {
            errorMessage = "This value could not be saved."
            return
        }
        dismiss()
    }
}
