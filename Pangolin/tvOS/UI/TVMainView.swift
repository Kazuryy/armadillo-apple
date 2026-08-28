import SwiftUI

struct TVMainView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var accountManager: AccountManager
    @ObservedObject var tunnelManager: TunnelManager
    @State private var showLoginView = false

    private var tunnelStatus: TunnelStatus {
        tunnelManager.status
    }

    private var isInIntermediateState: Bool {
        switch tunnelStatus {
        case .starting, .registering:
            return true
        default:
            return false
        }
    }

    private var statusColor: Color {
        switch tunnelStatus {
        case .connected:
            return .green
        case .disconnected:
            return .gray
        case .starting, .registering:
            return Color("AccentColor")
        }
    }

    var body: some View {
        ZStack {
            TVGradientBackground(isActive: tunnelStatus == .connected)

            ScrollView {
                VStack(spacing: 24) {
                    Text("Armadillo")
                        .font(.system(size: 56, weight: .bold))
                        .padding(.bottom, 8)

                    if authManager.isServerDown {
                        bannerCard(
                            systemImage: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            text: "The server appears to be down.")
                    }

                    if let errorMessage = authManager.errorMessage, !authManager.isServerDown,
                        !authManager.sessionExpired
                    {
                        bannerCard(
                            systemImage: "exclamationmark.circle.fill",
                            iconColor: .red,
                            text: errorMessage)
                    }

                    if authManager.sessionExpired {
                        sessionExpiredCard
                    } else {
                        connectCard
                    }

                    infoCard

                    Button {
                        Task { await authManager.logout() }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(TVCardButtonStyle())
                }
                .padding(48)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            TVLoginView(
                authManager: authManager,
                accountManager: accountManager,
                startImmediatelyWithHostname: accountManager.activeAccount?.hostname
            )
        }
    }

    // MARK: - Connect card

    private var connectCard: some View {
        Button {
            guard tunnelStatus != .starting else { return }
            Task {
                if tunnelManager.isNEConnected {
                    await tunnelManager.disconnect()
                } else {
                    await tunnelManager.connect()
                }
            }
        } label: {
            HStack(spacing: 16) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 14, height: 14)
                    .shadow(color: statusColor.opacity(0.5), radius: 4)

                Text(tunnelStatus.displayText)
                    .font(.headline)

                if isInIntermediateState {
                    ProgressView()
                        .tint(statusColor)
                }

                Spacer()

                Toggle("", isOn: .constant(tunnelManager.isNEConnected))
                    .labelsHidden()
                    .tint(Color("AccentColor"))
                    .allowsHitTesting(false)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(TVCardButtonStyle())
        .disabled(tunnelStatus == .starting)
    }

    private var sessionExpiredCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
            Text("Session Expired")
                .font(.headline)
            Spacer()
            Button("Log In") {
                showLoginView = true
            }
            .buttonStyle(TVPrimaryButtonStyle())
            .disabled(authManager.isDeviceAuthInProgress)
            .fixedSize()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(spacing: 0) {
            if let user = authManager.currentUser {
                infoRow(systemImage: "person.circle.fill", title: user.displayName, subtitle: "Account")
            }
            if !authManager.sessionExpired, let org = authManager.currentOrg {
                infoDivider
                infoRow(systemImage: "building.2.fill", title: org.name, subtitle: "Organization")
            }
            if let hostname = accountManager.activeAccount?.hostname {
                infoDivider
                infoRow(systemImage: "server.rack", title: hostname, subtitle: "Server")
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var infoDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private func infoRow(systemImage: String, title: String, subtitle: String) -> some View {
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
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func bannerCard(systemImage: String, iconColor: Color, text: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(iconColor)
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

/// Focus-driven card style shared by the tvOS main screen's tappable rows: a soft dark
/// card at rest that lifts to the system's white focused look, mirroring the treatment
/// `Color(.systemGray6)` cards get on iOS while staying idiomatic for tvOS focus.
struct TVCardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isFocused ? .black : .primary)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isFocused ? Color.white : Color.white.opacity(0.08))
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
