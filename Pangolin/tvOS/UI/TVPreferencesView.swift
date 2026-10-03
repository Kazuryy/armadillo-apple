import SwiftUI

/// App settings: automatic connection, DNS, the exit node routing rule, MTU and About.
struct TVPreferencesView: View {
    @ObservedObject var configManager: ConfigManager
    @ObservedObject var tunnelManager: TunnelManager

    private var dnsOverride: Binding<Bool> {
        Binding(
            get: { configManager.getDNSOverrideEnabled() },
            set: { _ = configManager.setDNSOverrideEnabled($0) })
    }

    private var dnsOverTunnel: Binding<Bool> {
        Binding(
            get: { configManager.getDNSTunnelEnabled() },
            set: { _ = configManager.setDNSTunnelEnabled($0) })
    }

    private var exitNodeTakesPrecedence: Binding<Bool> {
        Binding(
            get: { configManager.getExitNodeTakesPrecedence() },
            set: { _ = configManager.setExitNodeTakesPrecedence($0) })
    }

    private var onDemandSummary: String {
        let model = ActivateOnDemandViewModel(from: configManager.config)
        return model.localizedInterfaceDescription
    }

    var body: some View {
        TVScreen(title: "Settings") {
            VStack(spacing: 16) {
                TVSectionHeader("Connection")

                NavigationLink {
                    TVOnDemandView(configManager: configManager, tunnelManager: tunnelManager)
                } label: {
                    TVRowLabel(
                        systemImage: "arrow.triangle.2.circlepath",
                        title: "Connect Automatically",
                        value: onDemandSummary,
                        showsChevron: true)
                }
                .buttonStyle(TVCardButtonStyle())

                TVSectionHeader("DNS")

                TVToggleRow(
                    systemImage: "network",
                    title: "Enable Aliases (DNS Override)",
                    isOn: dnsOverride)
                TVFootnote(
                    "Resolves your internal resources and aliases with Pangolin's DNS. Anything that is not a Pangolin resource is forwarded to the upstream DNS server below.")

                TVToggleRow(
                    systemImage: "lock.shield",
                    title: "DNS Over Tunnel",
                    isOn: dnsOverTunnel)
                    .disabled(!dnsOverride.wrappedValue)
                TVFootnote(
                    "Sends DNS queries through the tunnel. Define the DNS server as a Pangolin resource and enter its address as an upstream DNS server.")

                dnsServerRow(
                    title: "Primary Upstream DNS Server",
                    value: configManager.getPrimaryDNSServer(),
                    save: { configManager.setPrimaryDNSServer($0) })
                dnsServerRow(
                    title: "Secondary Upstream DNS Server",
                    value: configManager.getSecondaryDNSServer(),
                    save: { configManager.setSecondaryDNSServer($0) })

                TVFootnote("DNS changes apply the next time you connect.")

                TVSectionHeader("Advanced")

                TVToggleRow(
                    systemImage: "arrow.triangle.branch",
                    title: "Exit Node Takes Precedence Over Resources",
                    isOn: exitNodeTakesPrecedence)
                TVFootnote(
                    "Routes for individual resources are not added and their aliases are not resolved, so all traffic goes through the exit node.")

                NavigationLink {
                    TVTextEntryView(
                        title: "MTU",
                        explanation: "Your sites must use the same MTU value.",
                        placeholder: String(ConfigManager.defaultTunnelMTU),
                        initialValue: String(configManager.getTunnelMTU()),
                        validate: { text in
                            if text.isEmpty { return nil }
                            guard let mtu = Int(text), (576...65535).contains(mtu) else {
                                return "Enter a number between 576 and 65535."
                            }
                            return nil
                        },
                        save: { configManager.setTunnelMTUFromString($0) })
                } label: {
                    TVRowLabel(
                        systemImage: "slider.horizontal.3",
                        title: "MTU",
                        value: String(configManager.getTunnelMTU()),
                        showsChevron: true)
                }
                .buttonStyle(TVCardButtonStyle())

                TVFootnote("Leave the field empty to go back to the default. MTU changes apply the next time you connect.")

                TVSectionHeader("About")

                NavigationLink {
                    TVAboutView()
                } label: {
                    TVRowLabel(
                        systemImage: "info.circle.fill", title: "About Armadillo",
                        showsChevron: true)
                }
                .buttonStyle(TVCardButtonStyle())
            }
        }
    }

    private func dnsServerRow(
        title: String, value: String, save: @escaping (String) -> Bool
    ) -> some View {
        NavigationLink {
            TVTextEntryView(
                title: title,
                explanation: "An IPv4 or IPv6 address. Leave it empty to clear it.",
                placeholder: "1.1.1.1",
                initialValue: value,
                validate: { text in
                    IPAddressValidator.isValid(text) ? nil : "Enter a valid IPv4 or IPv6 address."
                },
                save: save)
        } label: {
            TVRowLabel(
                systemImage: "server.rack",
                title: title,
                value: value.isEmpty ? "Not set" : value,
                showsChevron: true)
        }
        .buttonStyle(TVCardButtonStyle())
    }
}
