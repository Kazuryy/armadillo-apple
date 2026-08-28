import SwiftUI
import os.log

@main
struct PangolinApp: App {
    @StateObject private var configManager = ConfigManager()
    @StateObject private var secretManager = SecretManager()
    @StateObject private var accountManager = AccountManager()
    @StateObject private var apiClient: APIClient
    @StateObject private var authManager: AuthManager
    @StateObject private var tunnelManager: TunnelManager
    @ObservedObject private var alertManager = AlertManager.shared

    init() {
        let configMgr = ConfigManager()
        let secretMgr = SecretManager()
        let accountMgr = AccountManager()

        let activeAccount = accountMgr.activeAccount

        let hostname = activeAccount?.hostname ?? ConfigManager.defaultHostname
        let token =
            activeAccount.flatMap { acct in
                secretMgr.getSessionToken(userId: acct.userId)
            } ?? ""

        let client = APIClient(baseURL: hostname, sessionToken: token)
        let authMgr = AuthManager(
            apiClient: client,
            configManager: configMgr,
            accountManager: accountMgr,
            secretManager: secretMgr,
        )
        let tunnelMgr = TunnelManager(
            configManager: configMgr,
            accountManager: accountMgr,
            secretManager: secretMgr,
            authManager: authMgr,
        )

        authMgr.tunnelManager = tunnelMgr

        _configManager = StateObject(wrappedValue: configMgr)
        _secretManager = StateObject(wrappedValue: secretMgr)
        _accountManager = StateObject(wrappedValue: accountMgr)
        _apiClient = StateObject(wrappedValue: client)
        _authManager = StateObject(wrappedValue: authMgr)
        _tunnelManager = StateObject(wrappedValue: tunnelMgr)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isInitializing {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if authManager.isAuthenticated {
                    TVMainView(
                        authManager: authManager,
                        accountManager: accountManager,
                        tunnelManager: tunnelManager
                    )
                } else {
                    TVLoginView(
                        authManager: authManager,
                        accountManager: accountManager
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                Task {
                    await authManager.initialize()
                }
            }
            .alert(alertManager.alertTitle, isPresented: $alertManager.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertManager.alertMessage)
            }
        }
    }
}
