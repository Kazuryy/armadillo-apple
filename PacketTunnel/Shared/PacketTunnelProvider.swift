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
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("startTunnel called with options: %{public}@", log: logger, type: .debug, options?.description ?? "nil")

        // Don't reject nil/empty options here: a system-initiated start (Control Center,
        // an on-demand rule, a Settings toggle) always passes nil, and TunnelAdapter is the
        // one place that knows how to resolve that case (falling back to the credentials
        // persisted in the VPN configuration's passwordReference on tvOS). Gating on options
        // here too would short-circuit that fallback before it ever runs.

        // Initialize the tunnel adapter
        tunnelAdapter = TunnelAdapter(with: self)

        // Use the tunnel adapter to start the tunnel and discover the file descriptor
        tunnelAdapter?.start(options: options) { [weak self] (error: Error?) in
            if let error = error {
                os_log("Tunnel start failed: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
            } else {
                os_log("Tunnel start completed successfully", log: self?.logger ?? .default, type: .info)
            }
            completionHandler(error)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("stopTunnel called with reason: %d", log: logger, type: .debug, reason.rawValue)
        
        // Use the tunnel adapter to stop the Go tunnel
        if let error = tunnelAdapter?.stop() {
            os_log("Error stopping tunnel adapter: %{public}@", log: logger, type: .error, error.localizedDescription)
        } else {
            os_log("Tunnel stopped successfully", log: logger, type: .info)
        }
        
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
        os_log("Device going to sleep, setting power mode to low", log: logger, type: .info)
        setPowerMode(mode: "low")
        completionHandler()
    }
    
    override func wake() {
        os_log("Device waking up, setting power mode to normal", log: logger, type: .info)
        setPowerMode(mode: "normal")
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

