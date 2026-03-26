import Cocoa
import FlutterMacOS

class MouseMonitorStreamHandler: NSObject, FlutterStreamHandler {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var eventSink: FlutterEventSink?
  private var wakeObserver: NSObjectProtocol?
  
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
      options: .listenOnly,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
        // Re-enable the tap if macOS disabled it (e.g. after sleep/wake or timeout)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
          if let handler = Unmanaged<MouseMonitorStreamHandler>.fromOpaque(refcon!).takeUnretainedValue() as MouseMonitorStreamHandler? {
            if let tap = handler.eventTap {
              CGEvent.tapEnable(tap: tap, enable: true)
            }
          }
          return Unmanaged.passUnretained(event)
        }
        if let streamHandler = Unmanaged<MouseMonitorStreamHandler>.fromOpaque(refcon!).takeUnretainedValue() as MouseMonitorStreamHandler? {
          streamHandler.handleCGEvent(event: event)
        }
        return Unmanaged.passUnretained(event)
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
    
    // Re-enable the event tap after system wake from sleep
    wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      if let tap = self?.eventTap {
        CGEvent.tapEnable(tap: tap, enable: true)
      }
    }
    
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    // Remove sleep/wake observer
    if let observer = wakeObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
      wakeObserver = nil
    }
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
  
  /// Convert an NSScreen frame (NS coordinates, Y-up from bottom-left) to
  /// CG coordinates (Y-down from top-left of primary screen).
  private func nsToCGFrame(_ nsFrame: NSRect, primaryHeight: CGFloat) -> NSRect {
    let cgMinY = primaryHeight - nsFrame.maxY
    return NSRect(x: nsFrame.minX, y: cgMinY, width: nsFrame.width, height: nsFrame.height)
  }
  
  private func sendMouseData(location: CGPoint, type: CGEventType, eventSink: @escaping FlutterEventSink) {
    // CGEvent.location uses CG coordinates (origin at top-left, Y increases downward).
    // NSScreen.frame uses NS coordinates (origin at bottom-left, Y increases upward).
    // We must convert NS frames to CG frames before comparing or sending.
    let screens = NSScreen.screens
    guard let primaryScreen = screens.first else { return }
    let primaryHeight = primaryScreen.frame.height
    
    // Find which screen the mouse is currently on (using CG coordinates)
    var currentScreen: NSScreen?
    
    for screen in screens {
      let cgFrame = nsToCGFrame(screen.frame, primaryHeight: primaryHeight)
      if location.x >= cgFrame.minX && location.x <= cgFrame.maxX &&
         location.y >= cgFrame.minY && location.y <= cgFrame.maxY {
        currentScreen = screen
        break
      }
    }
    
    // Default to primary screen if not found
    let screen = currentScreen ?? primaryScreen
    
    let cgFrame = nsToCGFrame(screen.frame, primaryHeight: primaryHeight)
    
    let eventTypeString: String
    switch type {
    case .leftMouseDown, .rightMouseDown:
      eventTypeString = "click"
    default:
      eventTypeString = "move"
    }
    
    // Send position relative to screen and screen dimensions, all in CG coordinates
    let data: [String: Any] = [
      "type": eventTypeString,
      "x": location.x,
      "y": location.y,
      "screenMinX": cgFrame.minX,
      "screenMinY": cgFrame.minY,
      "screenWidth": cgFrame.width,
      "screenHeight": cgFrame.height
    ]
    
    eventSink(data)
  }
}
