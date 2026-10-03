import Foundation
import NetworkExtension
import os.log
import PangolinGo

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var tunnelAdapter: TunnelAdapter?
    private let logger: OSLog = {
        let subsystem = Bundle.main.bundleIdentifier ?? "net.pangolin.Pangolin.PacketTunnel"
        let log = OSLog(subsystem: subsystem, category: "PacketTunnelProvider")
        // Log the subsystem being used for debugging
        os_log("PacketTunnelProvider initialized with subsystem: %{public}@", log: log, type: .debug, subsystem)
        return log
    }()
    
    override init() {
        super.init()
    }
    
    private static let tunnelStartConfigJSONKey = "tunnelStartConfigJSON"

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("startTunnel called with options: %{public}@", log: logger, type: .debug, options?.description ?? "nil")

        let resolvedOptions: [String: NSObject]
        if let resolved = resolveStartOptions(options) {
            resolvedOptions = resolved
        } else {
            #if os(tvOS)
                // Nothing usable arrived with this start. A system-initiated start (Control Center,
                // a Settings toggle, an on-demand rule) always passes nil, and TunnelAdapter is the
                // one place that knows how to resolve that case, by falling back to the credentials
                // stored behind the VPN configuration's passwordReference. Rejecting the start here
                // would short-circuit that fallback before it ever runs.
                resolvedOptions = options ?? [:]
            #else
                let error = NSError(domain: "PacketTunnelProvider", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Tunnel options are required but were not provided"
                ])
                os_log(
                    "Tunnel start failed: could not resolve app options or tunnelStartConfigJSON",
                    log: logger, type: .error)
                completionHandler(error)
                return
            #endif
        }

        // Initialize the tunnel adapter
        tunnelAdapter = TunnelAdapter(with: self)

        // Use the tunnel adapter to start the tunnel and discover the file descriptor
            tunnelAdapter?.start(options: resolvedOptions) { [weak self] (error: Error?) in
            if let error = error {
                os_log("Tunnel start failed: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                #if os(iOS)
                VPNWidgetStatusStore.publishFromTunnelExtension(
                    isConnected: false,
                    isBusy: false
                )
                #endif
            } else {
                os_log("Tunnel start completed successfully", log: self?.logger ?? .default, type: .info)
                #if os(iOS)
                let endpoint = Self.stringValue(resolvedOptions, "endpoint")
                VPNWidgetStatusStore.publishFromTunnelExtension(
                    isConnected: true,
                    isBusy: false,
                    serverHostname: endpoint
                )
                #endif
            }
            completionHandler(error)
        }
    }

    /// Resolves tunnel start options from either:
    /// - App `startVPNTunnel` flat options (`endpoint`, `id`, …), or
    /// - JSON blob in options (`tunnelStartConfigJSON`), iOS `VendorData`, or
    ///   `protocolConfiguration.providerConfiguration`.
    ///
    /// iOS on-demand does **not** pass nil options — it passes a system dict with
    /// `is-on-demand` and wraps providerConfiguration under `VendorData`.
    private func resolveStartOptions(_ options: [String: NSObject]?) -> [String: NSObject]? {
        let jsonString =
            Self.extractTunnelStartConfigJSON(from: options)
            ?? Self.extractTunnelStartConfigJSON(
                fromProviderConfiguration:
                    (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration)
        let decodedFromJSON = jsonString.flatMap { Self.decodeTunnelStartConfigJSON($0) }

        let hasFlatAppOptions =
            options.map {
                Self.stringValue($0, "endpoint") != nil && Self.stringValue($0, "id") != nil
                    && Self.stringValue($0, "secret") != nil
            } ?? false

        // Prefer flat app options when present (explicit startVPNTunnel).
        if let options, hasFlatAppOptions {
            os_log(
                "Tunnel start: app-initiated (flat options, %{public}d keys)",
                log: logger, type: .info, options.count)
            return options
        }

        // On-demand / Always On / fallback: decoded JSON blob.
        if let decodedFromJSON {
            let onDemand = options?["is-on-demand"] != nil
            os_log(
                "Tunnel start: %{public}@ (decoded tunnelStartConfigJSON, %{public}d keys)",
                log: logger, type: .info,
                onDemand ? "on-demand / Always On" : "JSON fallback",
                decodedFromJSON.count)
            return decodedFromJSON
        }

        os_log(
            "Tunnel start: resolve failed (flat=%{public}d json=%{public}d optionKeys=%{public}@)",
            log: logger, type: .error,
            hasFlatAppOptions ? 1 : 0,
            decodedFromJSON != nil ? 1 : 0,
            options?.keys.sorted().joined(separator: ",") ?? "nil")
        return nil
    }

    private static func extractTunnelStartConfigJSON(from options: [String: NSObject]?)
        -> String?
    {
        guard let options else { return nil }
        if let json = stringValue(options, tunnelStartConfigJSONKey) {
            return json
        }
        // iOS on-demand wraps providerConfiguration as VendorData (NSDictionary).
        if let vendor = options["VendorData"] as? NSDictionary {
            if let json = vendor[tunnelStartConfigJSONKey] as? String {
                return json
            }
            if let json = vendor[tunnelStartConfigJSONKey] as? NSString {
                return json as String
            }
        }
        return nil
    }

    private static func extractTunnelStartConfigJSON(
        fromProviderConfiguration providerConfiguration: [String: Any]?
    ) -> String? {
        providerConfiguration?[tunnelStartConfigJSONKey] as? String
    }

    private static func decodeTunnelStartConfigJSON(_ json: String) -> [String: NSObject]? {
        guard let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        var converted: [String: NSObject] = [:]
        for (key, value) in object {
            if let object = value as? NSObject {
                converted[key] = object
            }
        }
        return converted.isEmpty ? nil : converted
    }

    private static func stringValue(_ options: [String: NSObject], _ key: String) -> String? {
        if let string = options[key] as? String { return string }
        if let string = options[key] as? NSString { return string as String }
        return nil
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("stopTunnel called with reason: %d", log: logger, type: .debug, reason.rawValue)
        
        // Use the tunnel adapter to stop the Go tunnel
        if let error = tunnelAdapter?.stop() {
            os_log("Error stopping tunnel adapter: %{public}@", log: logger, type: .error, error.localizedDescription)
        } else {
            os_log("Tunnel stopped successfully", log: logger, type: .info)
        }

        #if os(iOS)
        VPNWidgetStatusStore.publishFromTunnelExtension(
            isConnected: false,
            isBusy: false
        )
        #endif
        
        completionHandler()
        
        #if os(macOS)
        // HACK: This is a workaround for Apple bug 32073323.
        // System extensions on macOS sometimes don't terminate properly without this.
        exit(0)
        #endif
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Used on tvOS, where the extension's sandbox denies bind() on a Unix domain socket
        // entirely (confirmed via EPERM from olm's own API server), so there is no local socket
        // to relay to. For the one thing the app actually polls repeatedly (GET /status), call
        // straight into the Go core in-process instead and fake an HTTP response so the app's
        // existing HTTP-response parsing doesn't need to change. Other endpoints (switch-org,
        // metadata, exit, etc.) aren't reachable this way yet.
        os_log(
            "handleAppMessage: received %d bytes", log: logger, type: .debug, messageData.count)

        guard let requestString = String(data: messageData, encoding: .utf8),
            let requestLine = requestString.components(separatedBy: "\r\n").first
        else {
            completionHandler?(nil)
            return
        }

        if requestLine.hasPrefix("GET /status") {
            guard let statusResult = PangolinGo.getOlmStatus() else {
                completionHandler?(nil)
                return
            }
            let statusJSON = String(cString: statusResult)
            statusResult.deallocate()
            completionHandler?(httpResponse(body: statusJSON))
            return
        }

        completionHandler?(nil)
    }

    private func httpResponse(body: String) -> Data {
        let bodyData = Data(body.utf8)
        var response = "HTTP/1.1 200 OK\r\n"
        response += "Content-Type: application/json\r\n"
        response += "Content-Length: \(bodyData.count)\r\n"
        response += "\r\n"
        var data = Data(response.utf8)
        data.append(bodyData)
        return data
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        #if os(iOS) || os(tvOS)
            // tvOS follows the iOS path on purpose: it is the behavior that has been validated on
            // Apple TV hardware, while the macOS path below (keep the websocket up, poke on wake)
            // was written for macOS and has not been exercised on tvOS.
            //
            // Low power mode disconnects the control websocket and throttles
            // monitoring intervals, which matters on iOS: the extension keeps
            // running in the background under a tight execution/battery budget,
            // and idle pings/reconnect attempts would eat into it for no benefit
            // while the device is asleep or backgrounded.
            os_log("Device going to sleep, setting power mode to low", log: logger, type: .info)
            setPowerMode(mode: "low")
        #else
            // macOS: leave the control websocket connected through sleep rather
            // than tearing it down. Real system sleep halts all process timers,
            // so there's no idle-loop cost to avoid here the way there is on
            // iOS - and leaving it connected keeps its own dead-connection
            // detection (read-deadline/pong, see websocket.Client) armed, so
            // recovery on wake is driven by an actual failed round trip instead
            // of a fixed timer guessing the network is back. See wake() below.
            os_log("Device going to sleep (macOS, leaving control connection intact)", log: logger, type: .info)
        #endif
        completionHandler()
    }

    override func wake() {
        #if os(iOS) || os(tvOS)
            os_log("Device waking up, setting power mode to normal", log: logger, type: .info)
            setPowerMode(mode: "normal")
        #else
            // Nudge the (never-disconnected) control websocket with an immediate
            // ping rather than forcing a full reconnect: a live connection
            // confirms itself in one round trip, and a dead one starts
            // reconnecting right away via the same path a failed scheduled ping
            // would trigger. See pokeConnection/PokeConnection.
            os_log("Device waking up, poking control connection", log: logger, type: .info)
            pokeConnection()
        #endif
        sweepStaleDNS()
    }

    private func pokeConnection() {
        if let result = PangolinGo.pokeConnection() {
            let message = String(cString: result)
            result.deallocate()
            os_log("pokeConnection returned: %{public}@", log: logger, type: .debug, message)
        } else {
            os_log("Failed to call Go pokeConnection function (returned nil)", log: logger, type: .error)
        }
    }

    // Best-effort cleanup of any stale DNS override left behind by a previous
    // unclean shutdown (e.g. a crashed/killed extension process). wake() is a
    // reliable place to run this: it's invoked by the OS after every sleep.
    private func sweepStaleDNS() {
        if let result = PangolinGo.sweepStaleDNS() {
            let message = String(cString: result)
            result.deallocate()
            os_log("sweepStaleDNS returned: %{public}@", log: logger, type: .debug, message)
        } else {
            os_log("Failed to call Go sweepStaleDNS function (returned nil)", log: logger, type: .error)
        }
    }

    private func setPowerMode(mode: String) {
        let modeCString = mode.utf8CString
        let modePtr = UnsafeMutablePointer<CChar>.allocate(capacity: modeCString.count)
        modeCString.withUnsafeBufferPointer { buffer in
            modePtr.initialize(from: buffer.baseAddress!, count: buffer.count)
        }
        defer {
            modePtr.deallocate()
        }
        
        if let result = PangolinGo.setPowerMode(modePtr) {
            let message = String(cString: result)
            result.deallocate()
            os_log("setPowerMode returned: %{public}@", log: logger, type: .debug, message)
            
            if message.lowercased().contains("error") || message.lowercased().contains("fail") {
                os_log("Failed to set power mode: %{public}@", log: logger, type: .error, message)
            }
        } else {
            os_log("Failed to call Go setPowerMode function (returned nil)", log: logger, type: .error)
        }
    }
}

