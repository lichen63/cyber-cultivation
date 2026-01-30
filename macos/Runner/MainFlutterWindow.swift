import Cocoa
import FlutterMacOS
import QuartzCore
import ApplicationServices
import ServiceManagement

class MainFlutterWindow: NSWindow {
  private var layerObserver: NSKeyValueObservation?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: false)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let keyEventChannel = FlutterEventChannel(name: "com.lichen63.cyber_cultivation/key_events", binaryMessenger: flutterViewController.engine.binaryMessenger)
    keyEventChannel.setStreamHandler(KeyMonitorStreamHandler())

    let mouseEventChannel = FlutterEventChannel(name: "com.lichen63.cyber_cultivation/mouse_events", binaryMessenger: flutterViewController.engine.binaryMessenger)
    mouseEventChannel.setStreamHandler(MouseMonitorStreamHandler())

    let mouseControlChannel = FlutterMethodChannel(name: "com.lichen63.cyber_cultivation/mouse_control", binaryMessenger: flutterViewController.engine.binaryMessenger)
    mouseControlChannel.setMethodCallHandler { (call, result) in
        if call.method == "moveMouse" {
            if let args = call.arguments as? [String: Any],
               let dx = args["dx"] as? Double,
               let dy = args["dy"] as? Double {
                
                if let currentEvent = CGEvent(source: nil) {
                    let currentPos = currentEvent.location
                    let newPos = CGPoint(x: currentPos.x + dx, y: currentPos.y + dy)
                    
                    if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: newPos, mouseButton: .left) {
                        moveEvent.post(tap: .cghidEventTap)
                        result(true)
                        return
                    }
                }
                result(FlutterError(code: "EVENT_CREATION_FAILED", message: "Failed to create mouse event", details: nil))
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "dx and dy are required", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // Accessibility permission method channel
    let accessibilityChannel = FlutterMethodChannel(name: "com.lichen63.cyber_cultivation/accessibility", binaryMessenger: flutterViewController.engine.binaryMessenger)
    accessibilityChannel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "checkAccessibility":
            // Check without prompting
            let trusted = AXIsProcessTrusted()
            result(trusted)
        case "requestAccessibility":
            // Check with prompt - opens System Preferences
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let trusted = AXIsProcessTrustedWithOptions(options)
            result(trusted)
        case "openAccessibilitySettings":
            // Open System Preferences directly to Accessibility settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // System info method channel
    let systemInfoChannel = FlutterMethodChannel(name: "com.lichen63.cyber_cultivation/system_info", binaryMessenger: flutterViewController.engine.binaryMessenger)
    let systemInfoHandler = SystemInfoHandler()
    systemInfoChannel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "getCpuUsage":
            result(systemInfoHandler.getCpuUsage())
        case "getGpuUsage":
            result(systemInfoHandler.getGpuUsage())
        case "getRamUsage":
            result(systemInfoHandler.getRamUsage())
        case "getDiskUsage":
            result(systemInfoHandler.getDiskUsage())
        case "getNetworkUpload":
            result(systemInfoHandler.getNetworkUpload())
        case "getNetworkDownload":
            result(systemInfoHandler.getNetworkDownload())
        case "getAllStats":
            result(systemInfoHandler.getAllStats())
        case "getTopCpuProcesses":
            let limit = (call.arguments as? [String: Any])?["limit"] as? Int ?? 5
            result(systemInfoHandler.getTopCpuProcesses(limit: limit))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Launch at startup method channel
    let launchAtStartupChannel = FlutterMethodChannel(name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger)
    launchAtStartupChannel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "launchAtStartupIsEnabled":
            if #available(macOS 13.0, *) {
                result(SMAppService.mainApp.status == .enabled)
            } else {
                // For older macOS versions, we can't easily check, return false
                result(false)
            }
        case "launchAtStartupSetEnabled":
            if let arguments = call.arguments as? [String: Any],
               let setEnabled = arguments["setEnabledValue"] as? Bool {
                if #available(macOS 13.0, *) {
                    do {
                        if setEnabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        result(nil)
                    } catch {
                        result(FlutterError(code: "LAUNCH_AT_STARTUP_ERROR", message: error.localizedDescription, details: nil))
                    }
                } else {
                    // For older macOS, use deprecated SMLoginItemSetEnabled
                    let bundleId = Bundle.main.bundleIdentifier ?? ""
                    let success = SMLoginItemSetEnabled(bundleId as CFString, setEnabled)
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(code: "LAUNCH_AT_STARTUP_ERROR", message: "Failed to set launch at startup", details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "setEnabledValue is required", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    super.awakeFromNib()
    
    // Configure window for transparency
    self.isOpaque = false
    self.backgroundColor = .clear
    self.alphaValue = 0.0 // Hide window initially to prevent flicker
    self.hasShadow = false
    
    // Configure the content view
    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.backgroundColor = .clear
      contentView.layer?.isOpaque = false
    }
    
    // Configure Flutter view
    let flutterView = flutterViewController.view
    flutterView.wantsLayer = true
    
    // Set up delayed checks to catch the Metal layer after it's created
    // Multiple attempts ensure we catch the layer even if creation timing varies
    let delays: [TimeInterval] = [0.05, 0.1, 0.2]
    delays.forEach { delay in
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        self?.configureTransparency(for: flutterView)
      }
    }
  }
  
  private func configureTransparency(for view: NSView) {
    guard let layer = view.layer else { return }
    
    // Configure the main layer
    layer.backgroundColor = .clear
    layer.isOpaque = false
    
    // Recursively configure all sublayers (including Metal layers)
    configureSublayers(layer)
  }
  
  private func configureSublayers(_ layer: CALayer) {
    layer.backgroundColor = .clear
    layer.isOpaque = false
    
    // Special handling for Metal layers
    if let metalLayer = layer as? CAMetalLayer {
      metalLayer.isOpaque = false
      metalLayer.backgroundColor = .clear
      metalLayer.framebufferOnly = false
    }
    
    // Process all sublayers recursively
    layer.sublayers?.forEach { configureSublayers($0) }
  }
}
