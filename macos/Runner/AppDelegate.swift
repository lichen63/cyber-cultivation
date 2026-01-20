import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var statusItems: [String: NSStatusItem] = [:]
  private var contextMenu: NSMenu?
  var calendarPopover: NSPopover?
  private var calendarViewController: CalendarViewController?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "menu_bar_helper",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    // Create context menu
    contextMenu = NSMenu()
    let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(showWindowClicked), keyEquivalent: "")
    showWindowItem.target = self
    contextMenu?.addItem(showWindowItem)
    let hideWindowItem = NSMenuItem(title: "Hide Window", action: #selector(hideWindowClicked), keyEquivalent: "")
    hideWindowItem.target = self
    contextMenu?.addItem(hideWindowItem)
    contextMenu?.addItem(NSMenuItem.separator())
    let exitItem = NSMenuItem(title: "Exit", action: #selector(exitClicked), keyEquivalent: "")
    exitItem.target = self
    contextMenu?.addItem(exitItem)
    
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setAttributedTitle":
        self?.setAttributedTitle(call, result: result)
      case "setMenuBarItems":
        self?.setMenuBarItems(call, result: result)
      case "clearMenuBarItems":
        self?.clearMenuBarItems(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  @objc private func showWindowClicked() {
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  @objc private func hideWindowClicked() {
    mainFlutterWindow?.orderOut(nil)
  }
  
  @objc private func exitClicked() {
    NSApp.terminate(nil)
  }
  
  private func setMenuBarItems(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let items = args["items"] as? [[String: Any]],
          let fontSize = args["fontSize"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    let fontWeight: NSFont.Weight
    if let weightString = args["fontWeight"] as? String {
      switch weightString {
      case "light":
        fontWeight = .light
      case "regular":
        fontWeight = .regular
      case "medium":
        fontWeight = .medium
      case "semibold":
        fontWeight = .semibold
      case "bold":
        fontWeight = .bold
      default:
        fontWeight = .regular
      }
    } else {
      fontWeight = .regular
    }
    
    DispatchQueue.main.async {
      // Remove items that are no longer in the list
      let newItemIds = Set(items.compactMap { $0["id"] as? String })
      let existingIds = Set(self.statusItems.keys)
      for idToRemove in existingIds.subtracting(newItemIds) {
        if let item = self.statusItems[idToRemove] {
          NSStatusBar.system.removeStatusItem(item)
          self.statusItems.removeValue(forKey: idToRemove)
        }
      }
      
      // Update or create items (in reverse order so they appear left-to-right)
      for itemData in items.reversed() {
        guard let id = itemData["id"] as? String,
              let topText = itemData["top"] as? String,
              let bottomText = itemData["bottom"] as? String else {
          continue
        }
        
        let alignmentStr = itemData["alignment"] as? String ?? "center"
        let fixedWidth = itemData["fixedWidth"] as? Double ?? -1
        
        let statusItem: NSStatusItem
        if let existingItem = self.statusItems[id] {
          statusItem = existingItem
          // Update length if needed
          if fixedWidth > 0 {
            statusItem.length = CGFloat(fixedWidth)
          }
        } else {
          let length = fixedWidth > 0 ? CGFloat(fixedWidth) : NSStatusItem.variableLength
          statusItem = NSStatusBar.system.statusItem(withLength: length)
          self.statusItems[id] = statusItem
        }
        
        // Create attributed string
        let style = NSMutableParagraphStyle()
        switch alignmentStr {
        case "left":
          style.alignment = .left
        case "right":
          style.alignment = .right
        default:
          style.alignment = .center
        }
        
        let attributedString: NSAttributedString
        
        // Special handling for systemTime - single row with larger font
        if id == "systemTime" {
          let timeText = "\(topText) \(bottomText)"  // Combine date and time on one line
          let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: style,
            .baselineOffset: 0
          ]
          attributedString = NSAttributedString(string: timeText, attributes: timeAttributes)
        } else {
          // Get per-item font sizes, fallback to global fontSize if not specified (-1 means use default)
          let itemTopFontSize = itemData["topFontSize"] as? Double ?? -1
          let itemBottomFontSize = itemData["bottomFontSize"] as? Double ?? -1
          let topFontSize: CGFloat = itemTopFontSize > 0 ? CGFloat(itemTopFontSize) : CGFloat(fontSize)
          let bottomFontSize: CGFloat = itemBottomFontSize > 0 ? CGFloat(itemBottomFontSize) : CGFloat(fontSize)
          
          let topStyle = NSMutableParagraphStyle()
          topStyle.alignment = style.alignment
          topStyle.lineSpacing = -2
          topStyle.paragraphSpacing = 0
          topStyle.maximumLineHeight = topFontSize + 1
          
          let bottomStyle = NSMutableParagraphStyle()
          bottomStyle.alignment = style.alignment
          bottomStyle.lineSpacing = 0
          bottomStyle.paragraphSpacing = 0
          bottomStyle.maximumLineHeight = bottomFontSize + 1
          
          let topAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: topFontSize, weight: .regular),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: topStyle,
            .baselineOffset: -4
          ]
          
          let bottomAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: bottomFontSize, weight: fontWeight),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: bottomStyle,
            .baselineOffset: -5
          ]
          
          let mutableString = NSMutableAttributedString()
          mutableString.append(NSAttributedString(string: topText, attributes: topAttributes))
          mutableString.append(NSAttributedString(string: "\n", attributes: topAttributes))
          mutableString.append(NSAttributedString(string: bottomText, attributes: bottomAttributes))
          attributedString = mutableString
        }
        
        if let button = statusItem.button {
          button.attributedTitle = attributedString
          // Add click action to show context menu or calendar
          button.target = self
          button.action = #selector(self.menuBarItemClicked(_:))
          button.sendAction(on: [.leftMouseUp, .rightMouseUp])
          // Store the id in the button's identifier
          button.identifier = NSUserInterfaceItemIdentifier(id)
        }
      }
      
      result(true)
    }
  }
  
  @objc private func menuBarItemClicked(_ sender: NSStatusBarButton) {
    // Check if this is the systemTime item
    if sender.identifier?.rawValue == "systemTime" {
      showCalendarPopover(from: sender)
    } else {
      // Show context menu below the clicked button
      guard let menu = contextMenu else { return }
      // Pop up menu at the mouse location
      menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
    }
  }
  
  private func showCalendarPopover(from sender: NSStatusBarButton) {
    // Close if already open
    if let popover = calendarPopover, popover.isShown {
      popover.performClose(nil)
      return
    }
    
    // Create popover if needed
    if calendarPopover == nil {
      calendarPopover = NSPopover()
      calendarViewController = CalendarViewController()
      calendarPopover?.contentViewController = calendarViewController
      calendarPopover?.behavior = .transient
      calendarPopover?.animates = true
    }
    
    // Update calendar to current date
    calendarViewController?.updateToCurrentDate()
    
    // Show popover below the button
    calendarPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
  }
  
  private func clearMenuBarItems(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      for (_, item) in self.statusItems {
        NSStatusBar.system.removeStatusItem(item)
      }
      self.statusItems.removeAll()
      result(true)
    }
  }
  
  private func setAttributedTitle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let title = args["title"] as? String,
          let fontSize = args["fontSize"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    let fontWeight: NSFont.Weight
    if let weightString = args["fontWeight"] as? String {
      switch weightString {
      case "light":
        fontWeight = .light
      case "regular":
        fontWeight = .regular
      case "medium":
        fontWeight = .medium
      case "semibold":
        fontWeight = .semibold
      case "bold":
        fontWeight = .bold
      default:
        fontWeight = .regular
      }
    } else {
      fontWeight = .regular
    }
    
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    style.lineSpacing = -2
    style.paragraphSpacing = 0
    
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight),
      .foregroundColor: NSColor.textColor,
      .paragraphStyle: style,
      .baselineOffset: -1  // Lower the text
    ]
    
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    
    DispatchQueue.main.async {
      // Find all windows that are status bar windows and update them
      for window in NSApplication.shared.windows {
        let windowClassName = String(describing: type(of: window))
        if windowClassName.contains("NSStatusBarWindow") {
          self.findAndUpdateButton(in: window.contentView, with: attributedString)
        }
      }
      result(true)
    }
  }
  
  private func findAndUpdateButton(in view: NSView?, with attributedString: NSAttributedString) {
    guard let view = view else { return }
    
    if let button = view as? NSStatusBarButton {
      button.attributedTitle = attributedString
      return
    }
    
    for subview in view.subviews {
      findAndUpdateButton(in: subview, with: attributedString)
    }
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Keep app running when window is hidden
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
