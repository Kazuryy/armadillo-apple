import SwiftUI

/// Lists the signed-in accounts and lets the user switch between them, add another one or
/// remove one.
struct TVAccountsView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var accountManager: AccountManager
    @ObservedObject var tunnelManager: TunnelManager

    @State private var selectedAccount: Account?
    @State private var accountPendingRemoval: Account?
    @State private var showAddAccount = false

    private var accounts: [Account] {
        accountManager.accounts.values.sorted {
            ($0.email.lowercased(), $0.hostname) < ($1.email.lowercased(), $1.hostname)
        }
    }

    var body: some View {
        TVScreen(
            title: "Accounts",
            subtitle: "Switch between your Pangolin accounts or add another one."
        ) {
            VStack(spacing: 16) {
                ForEach(accounts) { account in
                    Button {
                        selectedAccount = account
                    } label: {
                        TVRowLabel(
                            systemImage: "person.circle.fill",
                            title: displayName(for: account),
                            subtitle: subtitle(for: account),
                            isSelected: account.userId == accountManager.activeUserId)
                    }
                    .buttonStyle(TVCardButtonStyle())
                }

                Button {
                    showAddAccount = true
                } label: {
                    TVRowLabel(systemImage: "plus.circle.fill", title: "Add Account")
                }
                .buttonStyle(TVCardButtonStyle())
            }
        }
        .confirmationDialog(
            selectedAccount.map(displayName(for:)) ?? "",
            isPresented: Binding(
                get: { selectedAccount != nil },
                set: { if !$0 { selectedAccount = nil } }),
            presenting: selectedAccount
        ) { account in
            if account.userId != accountManager.activeUserId {
                Button("Switch to This Account") {
                    Task { await authManager.switchAccount(userId: account.userId) }
                }
            }
            Button("Remove Account", role: .destructive) {
                accountPendingRemoval = account
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Remove Account?",
            isPresented: Binding(
                get: { accountPendingRemoval != nil },
                set: { if !$0 { accountPendingRemoval = nil } }),
            presenting: accountPendingRemoval
        ) { account in
            Button("Remove", role: .destructive) {
                Task { await authManager.deleteAccount(userId: account.userId) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { account in
            Text(
                "\(displayName(for: account)) will be signed out of Armadillo on this Apple TV.")
        }
        .fullScreenCover(isPresented: $showAddAccount) {
            TVLoginView(authManager: authManager, accountManager: accountManager)
        }
        .onChange(of: accountManager.activeUserId) { _, _ in
            // A successful login adds the account and makes it the active one.
            guard showAddAccount else { return }
            showAddAccount = false
            if tunnelManager.isNEConnected {
                Task { await tunnelManager.disconnect() }
            }
        }
    }

    private func displayName(for account: Account) -> String {
        if let name = account.name, !name.isEmpty { return name }
        if let username = account.username, !username.isEmpty { return username }
        return account.email
    }

    private func subtitle(for account: Account) -> String {
        let host = URL(string: account.hostname)?.host ?? account.hostname
        var text = "\(account.email) · \(host)"
        if !authManager.hasSession(userId: account.userId) {
            text += " · Login required"
        }
        return text
    }
}
