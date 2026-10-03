import SwiftUI

/// Chooses on which networks the VPN should connect by itself. Changes are saved as they are
/// made and handed to the tunnel so the system rules stay in sync.
struct TVOnDemandView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var tunnelManager: TunnelManager
    @StateObject private var model: ActivateOnDemandViewModel
    @State private var ssidPendingRemoval: String?

    init(configManager: ConfigManager, tunnelManager: TunnelManager) {
        self.configManager = configManager
        self.tunnelManager = tunnelManager
        _model = StateObject(wrappedValue: ActivateOnDemandViewModel(from: configManager.config))
    }

    var body: some View {
        TVScreen(
            title: "Connect Automatically",
            subtitle: "Choose the networks where the VPN should connect by itself."
        ) {
            VStack(spacing: 16) {
                TVSectionHeader("Connect On")

                TVToggleRow(
                    systemImage: "wifi",
                    title: ActivateOnDemandViewModel.wiFiInterfaceLabel,
                    isOn: $model.isWiFiInterfaceEnabled)

                TVToggleRow(
                    systemImage: "cable.connector",
                    title: ActivateOnDemandViewModel.nonWiFiInterfaceLabel,
                    isOn: $model.isNonWiFiInterfaceEnabled)

                if model.isWiFiInterfaceEnabled {
                    TVSectionHeader(ActivateOnDemandViewModel.ssidsLabel)

                    ForEach(OnDemandSSIDOptionKind.allCases, id: \.self) { kind in
                        Button {
                            model.ssidOption = kind
                        } label: {
                            TVRowLabel(
                                systemImage: "antenna.radiowaves.left.and.right",
                                title: kind.localizedUIString,
                                isSelected: model.ssidOption == kind)
                        }
                        .buttonStyle(TVCardButtonStyle())
                    }

                    if model.ssidOption != .any {
                        ForEach(model.selectedSSIDs, id: \.self) { ssid in
                            Button {
                                ssidPendingRemoval = ssid
                            } label: {
                                TVRowLabel(
                                    systemImage: "wifi", title: ssid, value: "Remove")
                            }
                            .buttonStyle(TVCardButtonStyle())
                        }

                        NavigationLink {
                            TVTextEntryView(
                                title: "Add Wi-Fi Network",
                                explanation: "Enter the exact name of the network.",
                                placeholder: "Network name",
                                validate: { $0.isEmpty ? "Enter a network name." : nil },
                                save: { name in
                                    if !model.selectedSSIDs.contains(name) {
                                        model.selectedSSIDs.append(name)
                                    }
                                    return true
                                })
                        } label: {
                            TVRowLabel(
                                systemImage: "plus.circle.fill", title: "Add Wi-Fi Network",
                                showsChevron: true)
                        }
                        .buttonStyle(TVCardButtonStyle())

                        if model.selectedSSIDs.isEmpty {
                            TVFootnote(
                                "Add at least one network. Until you do, any Wi-Fi network matches.")
                        }
                    }
                }

                TVFootnote(
                    "With rules set, the Connect button keeps the VPN on for these networks and the system reconnects it for you.")
            }
        }
        .confirmationDialog(
            ssidPendingRemoval.map { "Remove \"\($0)\"?" } ?? "",
            isPresented: Binding(
                get: { ssidPendingRemoval != nil },
                set: { if !$0 { ssidPendingRemoval = nil } }),
            presenting: ssidPendingRemoval
        ) { ssid in
            Button("Remove", role: .destructive) {
                model.selectedSSIDs.removeAll { $0 == ssid }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: model.isWiFiInterfaceEnabled) { _, _ in apply() }
        .onChange(of: model.isNonWiFiInterfaceEnabled) { _, _ in apply() }
        .onChange(of: model.ssidOption) { _, _ in apply() }
        .onChange(of: model.selectedSSIDs) { _, _ in apply() }
    }

    private func apply() {
        // Picking "only" or "except" before any network is listed would be reset to "any" by
        // the view model, so wait until there is at least one network to save.
        if model.ssidOption != .any && model.selectedSSIDs.isEmpty {
            return
        }
        let option = configManager.setOnDemandSettings(from: model)
        Task {
            await tunnelManager.updateOnDemandSettings(option: option)
        }
    }
}
