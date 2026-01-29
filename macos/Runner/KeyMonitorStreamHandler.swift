import Cocoa
import FlutterMacOS

class KeyMonitorStreamHandler: NSObject, FlutterStreamHandler {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var eventSink: FlutterEventSink?
  
  // Track the previous modifier flags to detect key-down vs key-up
  private var previousModifierFlags: CGEventFlags = []
  
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
      let currentFlags = event.flags
      
      // Only count modifier key presses, not releases
      // A key press is detected when the number of active modifiers increases
      let previousCount = countModifiers(previousModifierFlags)
      let currentCount = countModifiers(currentFlags)
      
      // Update the previous flags for next comparison
      previousModifierFlags = currentFlags
      
      // Only send event if a modifier was pressed (not released)
      if currentCount > previousCount {
        if let formatted = formatModifierFlags(currentFlags) {
          eventSink(formatted)
        }
      }
    }
  }
  
  /// Count the number of active modifier keys
  private func countModifiers(_ flags: CGEventFlags) -> Int {
    var count = 0
    if flags.contains(.maskAlphaShift) { count += 1 }
    if flags.contains(.maskSecondaryFn) { count += 1 }
    if flags.contains(.maskCommand) { count += 1 }
    if flags.contains(.maskControl) { count += 1 }
    if flags.contains(.maskAlternate) { count += 1 }
    if flags.contains(.maskShift) { count += 1 }
    return count
  }
  
  private func formatCGEvent(keyCode: Int, flags: CGEventFlags) -> String? {
    var parts = getModifierParts(flags)
    
    // Remove "Fn" for keys that macOS reports Fn automatically:
    // - Arrow keys (123=←, 124=→, 125=↓, 126=↑)
    // - Navigation keys (115=Home, 116=PageUp, 117=Delete, 119=End, 121=PageDown)
    // - Keypad Clear (71)
    let fnAutoKeys: Set<Int> = [71, 115, 116, 117, 119, 121, 123, 124, 125, 126]
    if fnAutoKeys.contains(keyCode) {
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
