import Cocoa
import FlutterMacOS
import QuartzCore
import ApplicationServices

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
