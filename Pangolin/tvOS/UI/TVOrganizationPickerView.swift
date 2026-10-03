import SwiftUI

/// Lets the user pick which organization to connect to, when the account belongs to several.
struct TVOrganizationPickerView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var isSwitching = false

    var body: some View {
        TVScreen(
            title: "Organization",
            subtitle: "Choose the organization you want to connect to."
        ) {
            VStack(spacing: 16) {
                ForEach(authManager.organizations, id: \.orgId) { org in
                    Button {
                        select(org)
                    } label: {
                        TVRowLabel(
                            systemImage: "building.2.fill",
                            title: org.name,
                            subtitle: org.isOwner == true ? "Owner" : nil,
                            isSelected: org.orgId == authManager.currentOrg?.orgId)
                    }
                    .buttonStyle(TVCardButtonStyle())
                    .disabled(isSwitching)
                }
            }

            if isSwitching {
                ProgressView()
            }
        }
        .task {
            await authManager.refreshOrganizations()
        }
    }

    private func select(_ org: Organization) {
        guard org.orgId != authManager.currentOrg?.orgId else {
            dismiss()
            return
        }
        isSwitching = true
        Task {
            await authManager.selectOrganization(org)
            await MainActor.run {
                isSwitching = false
                dismiss()
            }
        }
    }
}
