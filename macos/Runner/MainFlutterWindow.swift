import Cocoa
import FlutterMacOS
import QuartzCore
import ApplicationServices
import ServiceManagement
import IOKit

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

class KeyMonitorStreamHandler: NSObject, FlutterStreamHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var eventSink: FlutterEventSink?
    
    // Keycode to string mapping dictionary
    private static let keyCodeMap: [Int: String] = [
        // Numbers
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
        22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        
        // Letters
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
        34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
        12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
        16: "Y", 6: "Z",
        
        // Special keys
        36: "Enter", 48: "Tab", 49: "Space", 51: "Backspace", 53: "Esc",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        117: "Delete", 115: "Home", 119: "End", 116: "PageUp", 121: "PageDown",
        
        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18",
        80: "F19", 90: "F20",
        
        // Punctuation
        27: "-", 24: "=", 33: "[", 30: "]", 42: "\\",
        41: ";", 39: "'", 43: ",", 47: ".", 44: "/", 50: "`",
        
        // Keypad
        82: "Keypad 0", 83: "Keypad 1", 84: "Keypad 2", 85: "Keypad 3", 86: "Keypad 4",
        87: "Keypad 5", 88: "Keypad 6", 89: "Keypad 7", 91: "Keypad 8", 92: "Keypad 9",
        65: "Keypad .", 67: "Keypad *", 69: "Keypad +", 75: "Keypad /", 78: "Keypad -",
        81: "Keypad =", 76: "Keypad Enter", 71: "Keypad Clear"
    ]

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Request accessibility permissions with prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            return nil
        }
        
        // Create event tap for global key monitoring (captures ALL keys, including letters and numbers)
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let streamHandler = Unmanaged<KeyMonitorStreamHandler>.fromOpaque(refcon!).takeUnretainedValue() as KeyMonitorStreamHandler? {
                    streamHandler.handleCGEvent(event: event, type: type)
                    
                    // Workaround for Flutter crash with NumLock (71)
                    if type == .keyDown {
                        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                        if keyCode == 71 && NSRunningApplication.current.isActive {
                            return nil
                        }
                    }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return FlutterError(code: "EVENT_TAP_FAILED", message: "Failed to create event tap", details: nil)
        }
        
        self.eventTap = eventTap
        
        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Disable and cleanup event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
        self.eventSink = nil
        return nil
    }
    
    private func handleCGEvent(event: CGEvent, type: CGEventType) {
        guard let eventSink = eventSink else { return }
        
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            
            if let formatted = formatCGEvent(keyCode: Int(keyCode), flags: flags) {
                eventSink(formatted)
            }
        } else if type == .flagsChanged {
            let flags = event.flags
            if let formatted = formatModifierFlags(flags) {
                eventSink(formatted)
            }
        }
    }
    
    private func formatCGEvent(keyCode: Int, flags: CGEventFlags) -> String? {
        var parts = getModifierParts(flags)
        
        // Remove "Fn" if it's Keypad Clear (71) as it often reports Fn automatically
        if keyCode == 71 {
            parts.removeAll { $0 == "Fn" }
        }
        
        // Map key codes to readable strings
        let keyName = keyCodeToString(keyCode)
        if !keyName.isEmpty {
            parts.append(keyName)
        }
        
        if parts.isEmpty {
            return nil
        }
        return parts.joined(separator: " + ")
    }
    
    private func formatModifierFlags(_ flags: CGEventFlags) -> String? {
        let parts = getModifierParts(flags)
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }
    
    private func getModifierParts(_ flags: CGEventFlags) -> [String] {
        var parts: [String] = []
        
        if flags.contains(.maskAlphaShift) { parts.append("CapsLock") }
        if flags.contains(.maskSecondaryFn) { parts.append("Fn") }
        if flags.contains(.maskCommand) { parts.append("Cmd") }
        if flags.contains(.maskControl) { parts.append("Ctrl") }
        if flags.contains(.maskAlternate) { parts.append("Opt") }
        if flags.contains(.maskShift) { parts.append("Shift") }
        
        return parts
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String {
        return Self.keyCodeMap[keyCode] ?? ""
    }
}

class MouseMonitorStreamHandler: NSObject, FlutterStreamHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Get current mouse position immediately and send it
        if let mouseLocation = CGEvent(source: nil)?.location {
            sendMouseData(location: mouseLocation, type: .mouseMoved, eventSink: events)
        }
        
        // Request accessibility permissions with prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        if !trusted {
            return nil
        }
        
        // Create event tap for global mouse monitoring
        let eventMask = (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.leftMouseDragged.rawValue) | (1 << CGEventType.rightMouseDragged.rawValue) | (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let streamHandler = Unmanaged<MouseMonitorStreamHandler>.fromOpaque(refcon!).takeUnretainedValue() as MouseMonitorStreamHandler? {
                    streamHandler.handleCGEvent(event: event)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return FlutterError(code: "EVENT_TAP_FAILED", message: "Failed to create mouse event tap", details: nil)
        }
        
        self.eventTap = eventTap
        
        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Disable and cleanup event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
        self.eventSink = nil
        return nil
    }
    
    private func handleCGEvent(event: CGEvent) {
        guard let eventSink = eventSink else { return }
        sendMouseData(location: event.location, type: event.type, eventSink: eventSink)
    }
    
    private func sendMouseData(location: CGPoint, type: CGEventType, eventSink: @escaping FlutterEventSink) {
        // Find which screen the mouse is currently on
        let screens = NSScreen.screens
        var currentScreen: NSScreen?
        
        for screen in screens {
            let frame = screen.frame
            if location.x >= frame.minX && location.x <= frame.maxX &&
               location.y >= frame.minY && location.y <= frame.maxY {
                currentScreen = screen
                break
            }
        }
        
        // Default to main screen if not found
        guard let screen = currentScreen ?? NSScreen.main else { return }
        
        let screenFrame = screen.frame

        let eventTypeString: String
        switch type {
        case .leftMouseDown, .rightMouseDown:
            eventTypeString = "click"
        default:
            eventTypeString = "move"
        }
        
        // Send absolute position and screen info
        let data: [String: Any] = [
            "type": eventTypeString,
            "x": location.x,
            "y": location.y,
            "screenMinX": screenFrame.minX,
            "screenMinY": screenFrame.minY,
            "screenWidth": screenFrame.width,
            "screenHeight": screenFrame.height
        ]
        
        eventSink(data)
    }
}

// MARK: - System Info Handler
class SystemInfoHandler {
    private var previousCpuInfo: host_cpu_load_info?
    private var previousNetworkBytes: (upload: UInt64, download: UInt64)?
    private var previousNetworkTime: Date?
    private var lastNetworkUploadSpeed: Int = 0
    private var lastNetworkDownloadSpeed: Int = 0
    
    func getCpuUsage() -> Double {
        let cpuInfo = hostCPULoadInfo()
        guard let current = cpuInfo else { return 0.0 }
        
        var usage: Double = 0.0
        
        if let previous = previousCpuInfo {
            let userDiff = Double(current.cpu_ticks.0 - previous.cpu_ticks.0)
            let systemDiff = Double(current.cpu_ticks.1 - previous.cpu_ticks.1)
            let idleDiff = Double(current.cpu_ticks.2 - previous.cpu_ticks.2)
            let niceDiff = Double(current.cpu_ticks.3 - previous.cpu_ticks.3)
            
            let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
            if totalTicks > 0 {
                usage = ((userDiff + systemDiff + niceDiff) / totalTicks) * 100.0
            }
        }
        
        previousCpuInfo = current
        return usage
    }
    
    private func hostCPULoadInfo() -> host_cpu_load_info? {
        let count = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(count)
        var cpuLoadInfo = host_cpu_load_info()
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: count) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        if result != KERN_SUCCESS {
            return nil
        }
        return cpuLoadInfo
    }
    
    func getGpuUsage() -> Double {
        guard let accelerators = fetchIOService(kIOAcceleratorClassName) else {
            return 0.0
        }
        
        for accelerator in accelerators {
            if let stats = accelerator["PerformanceStatistics"] as? [String: Any] {
                // Try different keys that different GPU types use
                if let utilization = stats["Device Utilization %"] as? Int {
                    return Double(min(utilization, 100))
                }
                if let utilization = stats["GPU Activity(%)"] as? Int {
                    return Double(min(utilization, 100))
                }
                // For Apple Silicon GPUs
                if let utilization = stats["Renderer Utilization %"] as? Int {
                    return Double(min(utilization, 100))
                }
            }
        }
        
        return 0.0
    }
    
    func getRamUsage() -> Double {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result != KERN_SUCCESS {
            return 0.0
        }
        
        let pageSize = Double(vm_page_size)
        let active = Double(stats.active_count) * pageSize
        let wired = Double(stats.wire_count) * pageSize
        let compressed = Double(stats.compressor_page_count) * pageSize
        
        // Get total memory
        var hostInfo = host_basic_info()
        var hostCount = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let hostResult: kern_return_t = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostCount)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &hostCount)
            }
        }
        
        if hostResult != KERN_SUCCESS {
            return 0.0
        }
        
        let totalMemory = Double(hostInfo.max_mem)
        let usedMemory = active + wired + compressed
        
        return (usedMemory / totalMemory) * 100.0
    }
    
    func getDiskUsage() -> Double {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            
            if let totalCapacity = values.volumeTotalCapacity,
               let availableCapacity = values.volumeAvailableCapacity {
                let usedCapacity = totalCapacity - availableCapacity
                return (Double(usedCapacity) / Double(totalCapacity)) * 100.0
            }
        } catch {
            return 0.0
        }
        
        return 0.0
    }
    
    func getNetworkUpload() -> Int {
        updateNetworkStats()
        return lastNetworkUploadSpeed
    }
    
    func getNetworkDownload() -> Int {
        updateNetworkStats()
        return lastNetworkDownloadSpeed
    }
    
    private func updateNetworkStats() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }
        
        var totalUpload: UInt64 = 0
        var totalDownload: UInt64 = 0
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)
            
            // Only count physical interfaces (en0, en1, etc.)
            if name.hasPrefix("en") || name.hasPrefix("utun") || name.hasPrefix("pdp_ip") {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalUpload += UInt64(networkData.ifi_obytes)
                    totalDownload += UInt64(networkData.ifi_ibytes)
                }
            }
            
            if let next = interface.ifa_next {
                ptr = next
            } else {
                break
            }
        }
        
        let now = Date()
        
        if let previousBytes = previousNetworkBytes, let previousTime = previousNetworkTime {
            let timeDiff = now.timeIntervalSince(previousTime)
            if timeDiff > 0 {
                let uploadDiff = totalUpload >= previousBytes.upload ? totalUpload - previousBytes.upload : 0
                let downloadDiff = totalDownload >= previousBytes.download ? totalDownload - previousBytes.download : 0
                
                lastNetworkUploadSpeed = Int(Double(uploadDiff) / timeDiff)
                lastNetworkDownloadSpeed = Int(Double(downloadDiff) / timeDiff)
                
                previousNetworkBytes = (totalUpload, totalDownload)
                previousNetworkTime = now
            }
        } else {
            previousNetworkBytes = (totalUpload, totalDownload)
            previousNetworkTime = now
        }
    }
    
    func getAllStats() -> [String: Any] {
        // Update network stats once before getting all stats
        updateNetworkStats()
        
        return [
            "cpu": getCpuUsage(),
            "gpu": getGpuUsage(),
            "ram": getRamUsage(),
            "disk": getDiskUsage(),
            "networkUp": lastNetworkUploadSpeed,
            "networkDown": lastNetworkDownloadSpeed
        ]
    }
}

// MARK: - IOService Helper
func fetchIOService(_ name: String) -> [NSDictionary]? {
    var iterator: io_iterator_t = 0
    var masterPort: mach_port_t = 0
    if #available(macOS 12.0, *) {
        masterPort = kIOMainPortDefault
    } else {
        masterPort = kIOMasterPortDefault
    }
    let result = IOServiceGetMatchingServices(masterPort, IOServiceMatching(name), &iterator)
    
    guard result == KERN_SUCCESS else { return nil }
    defer { IOObjectRelease(iterator) }
    
    var list: [NSDictionary] = []
    var service = IOIteratorNext(iterator)
    
    while service != 0 {
        if let props = getIOProperties(service) {
            list.append(props)
        }
        IOObjectRelease(service)
        service = IOIteratorNext(iterator)
    }
    
    return list.isEmpty ? nil : list
}

func getIOProperties(_ entry: io_registry_entry_t) -> NSDictionary? {
    var properties: Unmanaged<CFMutableDictionary>?
    let result = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
    
    guard result == KERN_SUCCESS, let props = properties else { return nil }
    return props.takeRetainedValue() as NSDictionary
}
