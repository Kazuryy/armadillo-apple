import SwiftUI

/// Live connection status of the sites the tunnel is talking to.
struct TVSiteStatusView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @ObservedObject private var olmStatus: OLMStatusManager

    init(tunnelManager: TunnelManager) {
        self.tunnelManager = tunnelManager
        _olmStatus = ObservedObject(wrappedValue: tunnelManager.olmStatusManager)
    }

    private var isConnected: Bool {
        tunnelManager.status == .connected
    }

    private var items: [SiteStatusItem] {
        guard let status = olmStatus.socketStatus else { return [] }
        return SiteStatusItem.list(from: status)
    }

    var body: some View {
        TVScreen(
            title: "Sites",
            subtitle: olmStatus.socketStatus?.tunnelIP.map { "Tunnel address \($0)" },
            isActive: isConnected
        ) {
            if !isConnected {
                TVMessageCard(
                    systemImage: "point.3.connected.trianglepath.dotted",
                    text: "Connect to see the status of your sites.")
            } else if items.isEmpty {
                ProgressView()
                    .padding()
            } else {
                VStack(spacing: 16) {
                    ForEach(items) { item in
                        TVInfoCard {
                            row(for: item)
                        }
                    }
                }
            }
        }
        .onAppear {
            tunnelManager.olmStatusManager.startPolling()
        }
        .onDisappear {
            tunnelManager.olmStatusManager.stopPolling()
        }
    }

    private func row(for item: SiteStatusItem) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(item.connected ? Color.green : Color.gray)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail(for: item))
                    .font(.caption)
                    .tvSecondary()
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if item.isGateway {
                Text("Exit node")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("AccentColor").opacity(0.2)))
                    .foregroundColor(Color("AccentColor"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The state is always spelled out in words, so it never relies on the dot's color alone.
    private func detail(for item: SiteStatusItem) -> String {
        var parts = [item.connected ? "Connected" : "Disconnected"]
        if item.connected, let connection = item.connection {
            parts.append(connection)
        }
        if item.connected, let endpoint = item.endpoint, !endpoint.isEmpty {
            parts.append(endpoint)
        }
        return parts.joined(separator: " · ")
    }
}
