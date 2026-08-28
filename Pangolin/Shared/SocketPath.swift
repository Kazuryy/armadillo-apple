import Darwin
import Foundation

/// Returns the platform-appropriate socket path for the OLM socket.
/// On iOS, uses the app group container if available, otherwise falls back to temp directory.
/// On macOS, uses the standard system path.
func getSocketPath() -> String {
    #if os(iOS)
    // On iOS, use a path in the app's container directory (accessible in network extensions)
    // Use the app group container if available, otherwise use a temp directory
    if let appGroupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.pangolin.Pangolin") {
        return appGroupContainer.appendingPathComponent("olm.sock").path
    } else {
        // Fallback to temp directory if app group is not available
        return (NSTemporaryDirectory() as NSString).appendingPathComponent("olm.sock")
    }
    #elseif os(tvOS)
    // The app never connects to this socket directly on tvOS (see TunnelManager's
    // messageTransport, which relays through NETunnelProviderSession.sendProviderMessage
    // instead), so this only needs to be reachable within the extension's own process. That
    // matters because tvOS's app group container path is long enough to exceed sockaddr_un's
    // ~104-byte sun_path limit, which would otherwise break both bind() (in the Go core) and
    // connect() (in the extension's relay) the same way regardless of which process is
    // involved. chdir() into the container and use a short relative filename instead, which
    // fits under the limit no matter how deeply nested the container path actually is.
    let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.dev.kazuryy.Pangolin")
        ?? URL(fileURLWithPath: NSTemporaryDirectory())
    _ = chdir(directory.path)
    return "olm.sock"
    #else
    // On macOS, use the standard system path
    return "/var/run/olm.sock"
    #endif
}

