import SwiftUI

// Building blocks shared by the pushed tvOS screens. They reuse the look of the main screen:
// the charcoal TVGradientBackground, soft rounded cards that lift to a white focused state
// (TVCardButtonStyle), and brand-orange icons.

/// Scaffold for a pushed screen: brand background, large title and a centered column of cards.
struct TVScreen<Content: View>: View {
    let title: String
    var subtitle: String?
    var isActive: Bool
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        isActive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.content = content()
    }

    var body: some View {
        ZStack {
            TVGradientBackground(isActive: isActive)

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 56, weight: .bold))
                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 8)

                    content
                }
                .padding(48)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// Content of a tappable row: orange icon, title with an optional caption, then an optional
/// value, a checkmark for the current choice, a switch for on/off rows and a chevron for rows
/// that open another screen. Wrap it in a Button or NavigationLink using TVCardButtonStyle.
struct TVRowLabel: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var value: String?
    var isSelected = false
    var showsChevron = false
    /// When set, the row ends with a switch showing this state. The switch itself is not
    /// interactive: the surrounding Button flips the setting.
    var toggleValue: Bool?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("AccentColor"))
            }
            if let toggleValue {
                Toggle("", isOn: .constant(toggleValue))
                    .labelsHidden()
                    .tint(Color("AccentColor"))
                    .allowsHitTesting(false)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row that flips a Bool setting when selected.
struct TVToggleRow: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            TVRowLabel(
                systemImage: systemImage, title: title, subtitle: subtitle, toggleValue: isOn)
        }
        .buttonStyle(TVCardButtonStyle())
    }
}

/// A read-only card that can still take focus, so a screen made only of information can be
/// scrolled with the remote. It mirrors the focused look of TVCardButtonStyle.
struct TVInfoCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Inner(content: content)
            .focusable()
    }

    private struct Inner: View {
        @Environment(\.isFocused) private var isFocused
        let content: Content

        var body: some View {
            content
                .foregroundColor(isFocused ? .black : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.08))
                )
                .scaleEffect(isFocused ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isFocused)
        }
    }
}

/// Small uppercase label that introduces a group of rows.
struct TVSectionHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
    }
}

/// Explanatory text that sits under a row or a group of rows.
struct TVFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }
}

/// Icon and sentence on a soft card, for empty states and notices.
struct TVMessageCard: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(Color("AccentColor"))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
    }
}
