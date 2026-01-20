import Cocoa
import FlutterMacOS

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
    let eventMask = (1 << CGEventType.mouseMoved.rawValue) |
                    (1 << CGEventType.leftMouseDragged.rawValue) |
                    (1 << CGEventType.rightMouseDragged.rawValue) |
                    (1 << CGEventType.leftMouseDown.rawValue) |
                    (1 << CGEventType.rightMouseDown.rawValue)
    
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
