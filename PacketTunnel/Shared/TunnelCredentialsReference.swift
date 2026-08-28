import Foundation
import Security

/// Stores the tunnel's connect parameters (endpoint, OLM credentials, session token, DNS
/// settings, last-known fingerprint/postures - everything TunnelAdapter needs to start) as a
/// Keychain item shared between the app and the extension via `keychain-access-groups`, and
/// exposes it through `NETunnelProviderProtocol.passwordReference` on the saved VPN
/// configuration. This lets the extension start the tunnel on its own - from Control Center, a
/// Settings toggle, or an on-demand rule - without the app having to be running to hand it fresh
/// options, the same approach WireGuard's own client uses for its config.
enum TunnelCredentialsReference {
    // Matches the "keychain-access-groups" entitlement on both the app and extension targets.
    // $(AppIdentifierPrefix) only resolves inside entitlements/plist files, not compiled Swift,
    // so the team ID has to be written out here to match.
    private static let keychainAccessGroup = "82V4UQQ84J.dev.kazuryy.Pangolin"

    private static func serviceName() -> String {
        var bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.pangolin.Pangolin"
        // The app and extension have different bundle IDs; normalize to one shared service name
        // so both look up the same Keychain item.
        if let range = bundleIdentifier.range(of: ".PacketTunnel", options: .backwards) {
            bundleIdentifier.removeSubrange(range.lowerBound..<bundleIdentifier.endIndex)
        }
        return bundleIdentifier
    }

    /// Replaces any existing reference and stores `value` under a fresh Keychain item, returning
    /// a persistent reference suitable for `NEVPNProtocol.passwordReference`.
    static func makeReference(containing value: String, previouslyReferencedBy oldRef: Data? = nil)
        -> Data?
    {
        if let oldRef {
            deleteReference(oldRef)
        }

        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessGroup: keychainAccessGroup,
            kSecAttrService: serviceName(),
            kSecAttrAccount: "tunnelCredentials",
        ]

        // In case a stale item is left over from a previous install/crash that didn't clean up
        // via `oldRef` (e.g. it was lost along with the rest of app state).
        SecItemDelete(baseQuery as CFDictionary)

        var addQuery = baseQuery
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        addQuery[kSecValueData] = Data(value.utf8)
        addQuery[kSecReturnPersistentRef] = true

        var ref: CFTypeRef?
        let status = SecItemAdd(addQuery as CFDictionary, &ref)
        guard status == errSecSuccess else { return nil }
        return ref as? Data
    }

    static func openReference(_ ref: Data) -> String? {
        let query: [CFString: Any] = [
            kSecValuePersistentRef: ref,
            kSecReturnData: true,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteReference(_ ref: Data) {
        SecItemDelete([kSecValuePersistentRef: ref] as CFDictionary)
    }
}
