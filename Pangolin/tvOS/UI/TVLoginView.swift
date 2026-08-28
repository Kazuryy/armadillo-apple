import CoreImage.CIFilterBuiltins
import SwiftUI

struct TVLoginView: View {
    @State private var hostingOption: HostingOption?
    @State private var selfHostedURL: String = ""
    @State private var isLoggingIn = false
    @State private var loginTask: Task<Void, Never>?
    @State private var qrImage: Image?

    private static let ciContext = CIContext()

    @ObservedObject var authManager: AuthManager
    @ObservedObject var accountManager: AccountManager
    var startImmediatelyWithHostname: String? = nil

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("Armadillo")
                    .font(.system(size: 56, weight: .bold))
                if hostingOption == nil && authManager.deviceAuthCode == nil && !isLoggingIn {
                    Text("For Pangolin, the zero trust remote access platform.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Group {
                if authManager.deviceAuthCode != nil {
                    deviceAuthCodeView
                } else if isLoggingIn {
                    ProgressView("Generating login code...")
                } else if hostingOption == .selfHosted {
                    readyToLoginView
                } else {
                    hostingSelectionView
                }
            }
            .frame(maxWidth: authManager.deviceAuthCode != nil ? 1400 : 900)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            loginTask?.cancel()
            authManager.cancelDeviceAuth()
        }
        .onAppear {
            if let hostname = startImmediatelyWithHostname, !hostname.isEmpty {
                hostingOption = .selfHosted
                selfHostedURL = hostname
                performLogin(hostname: hostname)
            }
        }
    }

    private var hostingSelectionView: some View {
        HStack(spacing: 32) {
            Button {
                hostingOption = .cloud
                performLogin(hostname: "https://app.pangolin.net")
            } label: {
                hostingOptionLabel(
                    systemImage: "icloud.fill",
                    title: "Pangolin Cloud",
                    subtitle: "app.pangolin.net")
            }

            Button {
                hostingOption = .selfHosted
                selfHostedURL = accountManager.activeAccount?.hostname ?? ""
            } label: {
                hostingOptionLabel(
                    systemImage: "server.rack",
                    title: "Self-Hosted",
                    subtitle: "Enter your custom hostname")
            }
        }
        .buttonStyle(.card)
    }

    private func hostingOptionLabel(systemImage: String, title: String, subtitle: String)
        -> some View
    {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 64, height: 64)
                .background(Color("AccentColor").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
    }

    private var readyToLoginView: some View {
        VStack(spacing: 24) {
            TextField("Server URL", text: $selfHostedURL)
                .autocorrectionDisabled()

            Button("Continue") {
                let hostname = normalizeHostname(selfHostedURL)
                if hostname.isEmpty {
                    AlertManager.shared.showAlertDialog(
                        title: "Error", message: "Please enter a server URL.")
                    return
                }
                performLogin(hostname: hostname)
            }
            .buttonStyle(TVPrimaryButtonStyle())
            .disabled(selfHostedURL.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var deviceAuthCodeView: some View {
        VStack(spacing: 32) {
            HStack(alignment: .top, spacing: 48) {
                if let qrImage {
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 220, height: 220)
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 220, height: 220)
                        .overlay(ProgressView().scaleEffect(1.5))
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("Scan to Sign In")
                        .font(.system(size: 32, weight: .bold))

                    Text("Point your phone's camera at the code, or open the address below and type in the code shown.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let loginURL = authManager.deviceAuthLoginURL {
                        Text(loginURL)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                    }

                    if let deviceCode = authManager.deviceAuthCode {
                        Text(deviceCode)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule().fill(Color("AccentColor"))
                            )
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )

            HStack(spacing: 20) {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color("AccentColor"))
                    Text("Waiting for confirmation…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    cancelDeviceAuth()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .task(id: qrCodeURLString) {
            qrImage = qrCodeImage(from: qrCodeURLString)
        }
    }

    private func cancelDeviceAuth() {
        loginTask?.cancel()
        authManager.cancelDeviceAuth()
        hostingOption = nil
        isLoggingIn = false
    }

    private var qrCodeURLString: String {
        guard let loginURL = authManager.deviceAuthLoginURL,
            let deviceCode = authManager.deviceAuthCode
        else {
            return ""
        }
        let codeWithoutHyphen = deviceCode.replacingOccurrences(of: "-", with: "")
        return "\(loginURL)?code=\(codeWithoutHyphen)"
    }

    private func qrCodeImage(from string: String) -> Image? {
        guard !string.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = Self.ciContext.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }
        return Image(decorative: cgImage, scale: 1.0)
    }

    private func normalizeHostname(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        var normalized = trimmed
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "https://" + normalized
        }
        return normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func performLogin(hostname: String) {
        isLoggingIn = true
        loginTask = Task {
            do {
                try await authManager.loginWithDeviceAuth(hostnameOverride: hostname)
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        AlertManager.shared.showErrorDialog(error)
                    }
                }
            }
            await MainActor.run {
                isLoggingIn = false
            }
        }
    }
}

private enum HostingOption {
    case cloud
    case selfHosted
}

/// Filled brand-orange pill that matches tvOS's own focused look (white background, black
/// text) instead of `.tint`, which recolors the label along with the background and leaves
/// unfocused text unreadable against the same-colored fill.
struct TVPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .foregroundColor(isFocused ? .black : .white)
            .background(isFocused ? Color.white : Color("AccentColor"))
            .opacity(isEnabled ? 1 : 0.4)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
