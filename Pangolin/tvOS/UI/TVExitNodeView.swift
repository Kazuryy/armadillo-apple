import SwiftUI

/// Chooses the exit node: a gateway site that all of the Apple TV's traffic is sent through.
/// With the tunnel up the change applies immediately, otherwise it is saved for the next connect.
struct TVExitNodeView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @State private var isWorking = false

    private var nodes: [SiteResource] {
        tunnelManager.availableExitNodes
    }

    var body: some View {
        TVScreen(
            title: "Exit Node",
            subtitle: "Send all of your traffic through one of your sites.",
            isActive: tunnelManager.status == .connected
        ) {
            if nodes.isEmpty {
                TVMessageCard(
                    systemImage: "globe",
                    text: "No exit nodes are set up for this organization.")
            } else {
                VStack(spacing: 16) {
                    Button {
                        apply { await tunnelManager.disableExitNode() }
                    } label: {
                        TVRowLabel(
                            systemImage: "xmark.circle",
                            title: "None",
                            subtitle: "Only reach your Pangolin resources",
                            isSelected: tunnelManager.activeExitNodeId == nil)
                    }
                    .buttonStyle(TVCardButtonStyle())

                    ForEach(nodes) { node in
                        Button {
                            apply { await tunnelManager.selectExitNode(node) }
                        } label: {
                            TVRowLabel(
                                systemImage: "globe",
                                title: node.name,
                                subtitle: node.niceId,
                                isSelected: tunnelManager.activeExitNodeId == node.siteResourceId)
                        }
                        .buttonStyle(TVCardButtonStyle())
                    }
                }
                .disabled(isWorking)

                TVFootnote(
                    tunnelManager.isNEConnected
                        ? "Changes apply immediately."
                        : "Your choice is saved and applied the next time you connect.")
            }
        }
        .task {
            await tunnelManager.refreshExitNodes()
        }
    }

    private func apply(_ change: @escaping () async -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task {
            await change()
            await MainActor.run { isWorking = false }
        }
    }
}
