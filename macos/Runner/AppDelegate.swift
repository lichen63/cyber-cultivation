import Cocoa
import FlutterMacOS
import SwiftUI

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var popoverChannel: FlutterMethodChannel?
  private var statusItems: [String: NSStatusItem] = [:]
  var calendarPopover: NSPopover?
  private var calendarViewController: CalendarViewController?
  private var popoverEventMonitor: Any?
  private var isDarkMode: Bool = true
  
  // Native menu bar popover (using custom panel for no arrow)
  private var menuBarPopoverPanel: BorderlessPopoverPanel?
  private var menuBarPopoverViewController: MenuBarPopoverViewController?
  private var menuBarPopoverEventMonitor: Any?
  private var currentPopoverItemId: String?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "menu_bar_helper",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    // Set up popover method channel
    popoverChannel = FlutterMethodChannel(
      name: "menu_bar_popover",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setAttributedTitle":
        self?.setAttributedTitle(call, result: result)
      case "setMenuBarItems":
        self?.setMenuBarItems(call, result: result)
      case "clearMenuBarItems":
        self?.clearMenuBarItems(result: result)
      case "showWindow":
        self?.showWindowClicked()
        result(true)
      case "hideWindow":
        self?.hideWindowClicked()
        result(true)
      case "exitApp":
        self?.exitClicked()
        result(true)
      case "setTheme":
        self?.setTheme(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    popoverChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "showPopover":
        self?.showMenuBarPopover(call, result: result)
      case "hidePopover":
        self?.hideMenuBarPopover(result: result)
      case "updatePopoverContent":
        self?.updateMenuBarPopoverContent(call, result: result)
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
      // Check if we need to add any NEW items
      let newItemIds = Set(items.compactMap { $0["id"] as? String })
      let existingIds = Set(self.statusItems.keys)
      let itemsToAdd = newItemIds.subtracting(existingIds)
      let itemsToRemove = existingIds.subtracting(newItemIds)
      
      // If we need to add new items, we must recreate ALL items to maintain correct order
      // This is because NSStatusBar always inserts new items at the leftmost position
      let needsFullRecreate = !itemsToAdd.isEmpty
      
      if needsFullRecreate {
        // Remove ALL existing items
        for (_, item) in self.statusItems {
          NSStatusBar.system.removeStatusItem(item)
        }
        self.statusItems.removeAll()
      } else {
        // Only remove items that are no longer needed
        for idToRemove in itemsToRemove {
          if let item = self.statusItems[idToRemove] {
            NSStatusBar.system.removeStatusItem(item)
            self.statusItems.removeValue(forKey: idToRemove)
          }
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
        
        // Check for battery special handling
        if id == "battery" && topText.hasPrefix("BATTERY:") {
          // Parse battery info: "BATTERY:<level>:<charging>"
          let parts = topText.split(separator: ":")
          if parts.count >= 3,
             let level = Int(parts[1]) {
            let isCharging = parts[2] == "1"
            if let button = statusItem.button {
              // Create battery icon with percentage inside
              let batteryImage = self.createBatteryImage(level: level, isCharging: isCharging, width: CGFloat(fixedWidth > 0 ? fixedWidth : 38))
              button.image = batteryImage
              button.imagePosition = .imageOnly
              button.attributedTitle = NSAttributedString(string: "")
              button.target = self
              button.action = #selector(self.menuBarItemClicked(_:))
              button.sendAction(on: [.leftMouseUp, .rightMouseUp])
              button.identifier = NSUserInterfaceItemIdentifier(id)
            }
          }
          continue
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
            .font: NSFont.systemFont(ofSize: topFontSize, weight: fontWeight),
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
          button.image = nil
          button.imagePosition = .noImage
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
  
  /// Create a battery icon image with percentage text inside
  private func createBatteryImage(level: Int, isCharging: Bool, width: CGFloat) -> NSImage {
    let height: CGFloat = 22  // Menu bar height
    let batteryWidth: CGFloat = 26
    let batteryHeight: CGFloat = 12
    let tipWidth: CGFloat = 2
    let tipHeight: CGFloat = 5
    let cornerRadius: CGFloat = 2.5
    let borderWidth: CGFloat = 1.0
    let chargingIconWidth: CGFloat = isCharging ? 10 : 0  // Space for charging icon on the left
    
    let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { rect in
      let batteryX = (width - batteryWidth - tipWidth + chargingIconWidth) / 2
      let batteryY = (height - batteryHeight) / 2
      
      // Always use white for border
      let borderColor = NSColor.white
      // Use white for fill, black for text
      let fillColor = NSColor.white
      let textColor = NSColor.black
      
      // Draw charging indicator (lightning bolt) to the left of the battery
      if isCharging {
        let boltCenterX = batteryX - 6
        let boltCenterY = batteryY + batteryHeight / 2
        
        // Draw a cleaner, wider lightning bolt shape
        let boltPath = NSBezierPath()
        // Top point
        boltPath.move(to: NSPoint(x: boltCenterX + 1.5, y: boltCenterY + 6))
        // Left side going down to middle
        boltPath.line(to: NSPoint(x: boltCenterX - 2.5, y: boltCenterY + 0.5))
        // Middle notch (left)
        boltPath.line(to: NSPoint(x: boltCenterX - 0.5, y: boltCenterY + 0.5))
        // Bottom point
        boltPath.line(to: NSPoint(x: boltCenterX - 1.5, y: boltCenterY - 6))
        // Right side going up to middle
        boltPath.line(to: NSPoint(x: boltCenterX + 2.5, y: boltCenterY - 0.5))
        // Middle notch (right)
        boltPath.line(to: NSPoint(x: boltCenterX + 0.5, y: boltCenterY - 0.5))
        boltPath.close()
        
        NSColor.white.setFill()
        boltPath.fill()
      }
      
      // Draw battery body outline
      let bodyRect = NSRect(x: batteryX, y: batteryY, width: batteryWidth, height: batteryHeight)
      let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
      borderColor.setStroke()
      bodyPath.lineWidth = borderWidth
      bodyPath.stroke()
      
      // Draw battery tip (positive terminal)
      let tipRect = NSRect(
        x: batteryX + batteryWidth,
        y: batteryY + (batteryHeight - tipHeight) / 2,
        width: tipWidth,
        height: tipHeight
      )
      let tipPath = NSBezierPath(roundedRect: tipRect, xRadius: 1, yRadius: 1)
      borderColor.setFill()
      tipPath.fill()
      
      // Draw fill level (white fill)
      let inset: CGFloat = 1.5
      let fillWidth = (batteryWidth - inset * 2) * CGFloat(level) / 100.0
      if fillWidth > 0 {
        let fillRect = NSRect(
          x: batteryX + inset,
          y: batteryY + inset,
          width: fillWidth,
          height: batteryHeight - inset * 2
        )
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1.0, yRadius: 1.0)
        fillColor.setFill()
        fillPath.fill()
      }
      
      // Draw percentage number inside the battery (no % symbol, black text with white outline)
      let percentText = "\(level)"
      let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .bold)
      let textSize = (percentText as NSString).size(withAttributes: [.font: font])
      let textX = batteryX + (batteryWidth - textSize.width) / 2
      let textY = batteryY + (batteryHeight - textSize.height) / 2
      
      // Draw white outline (stroke) first
      let strokeAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .strokeColor: NSColor.white,
        .strokeWidth: -3.0  // Negative value fills the text and adds stroke
      ]
      (percentText as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: strokeAttributes)
      
      // Draw black fill on top
      let fillAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: textColor
      ]
      (percentText as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: fillAttributes)
      
      return true
    }
    
    image.isTemplate = false
    return image
  }
  
  @objc private func menuBarItemClicked(_ sender: NSStatusBarButton) {
    // Check if this is the systemTime item
    if sender.identifier?.rawValue == "systemTime" {
      showCalendarPopover(from: sender)
    } else {
      // Close calendar popover if open when clicking other menu bar items
      if let popover = calendarPopover, popover.isShown {
        closeCalendarPopover()
      }
      
      // Show native popover immediately for this menu bar item
      let itemId = sender.identifier?.rawValue ?? ""
      showMenuBarPopoverImmediately(itemId: itemId, from: sender)
      
      // Request popover data from Flutter (will update the already-visible popover)
      methodChannel?.invokeMethod("onMenuBarItemClicked", arguments: [
        "itemId": itemId
      ])
    }
  }
  
  /// Show popover immediately with loading state, before Flutter provides data
  private func showMenuBarPopoverImmediately(itemId: String, from sender: NSStatusBarButton) {
    // Close existing popover if different item
    if menuBarPopoverPanel?.isVisible == true && currentPopoverItemId != itemId {
      closeMenuBarPopover()
    }
    
    // If same item and popover is shown, close it (toggle behavior)
    if menuBarPopoverPanel?.isVisible == true && currentPopoverItemId == itemId {
      closeMenuBarPopover()
      return
    }
    
    // Create view controller if needed
    if menuBarPopoverViewController == nil {
      menuBarPopoverViewController = MenuBarPopoverViewController()
    }
    
    // Create panel if needed
    if menuBarPopoverPanel == nil {
      menuBarPopoverPanel = BorderlessPopoverPanel(
        contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
      )
      menuBarPopoverPanel?.contentViewController = menuBarPopoverViewController
    }
    
    // Configure with basic data (loading state)
    let initialData: [String: Any] = [
      "itemId": itemId,
      "brightness": isDarkMode ? "dark" : "light",
      "isLoading": true
    ]
    
    menuBarPopoverViewController?.configure(
      itemId: itemId,
      data: initialData,
      isDarkMode: isDarkMode,
      onShowWindow: { [weak self] in
        self?.showWindowClicked()
        self?.closeMenuBarPopover()
      },
      onHideWindow: { [weak self] in
        self?.hideWindowClicked()
        self?.closeMenuBarPopover()
      },
      onExitApp: { [weak self] in
        self?.exitClicked()
      },
      onActivityMonitorTap: { [weak self] in
        self?.openActivityMonitor()
        self?.closeMenuBarPopover()
      }
    )
    
    currentPopoverItemId = itemId
    
    // Position panel below the status bar button
    if let buttonWindow = sender.window {
      let buttonFrame = sender.convert(sender.bounds, to: nil)
      let screenFrame = buttonWindow.convertToScreen(buttonFrame)
      
      // Get panel size from view controller
      let panelSize = menuBarPopoverViewController?.view.fittingSize ?? NSSize(width: 280, height: 200)
      
      // Position below button, centered
      let panelX = screenFrame.midX - panelSize.width / 2
      let panelY = screenFrame.minY - panelSize.height - 4  // 4pt gap below menu bar
      
      menuBarPopoverPanel?.setFrame(NSRect(x: panelX, y: panelY, width: panelSize.width, height: panelSize.height), display: true)
    }
    
    // Show the panel
    menuBarPopoverPanel?.orderFront(nil)
    
    // Add global event monitor to close popover when clicking outside
    menuBarPopoverEventMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown]
    ) { [weak self] event in
      if let panel = self?.menuBarPopoverPanel,
         panel.isVisible {
        let mouseLocation = NSEvent.mouseLocation
        if !panel.frame.contains(mouseLocation) {
          self?.closeMenuBarPopover()
        }
      }
    }
  }
  
  private func setTheme(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let brightness = args["brightness"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    isDarkMode = brightness == "dark"
    // Update calendar view controller if it exists
    calendarViewController?.isDarkMode = isDarkMode
    result(true)
  }
  
  private func showCalendarPopover(from sender: NSStatusBarButton) {
    // Close if already open
    if let popover = calendarPopover, popover.isShown {
      closeCalendarPopover()
      return
    }
    
    // Notify Flutter to hide any open popup window before showing native popover
    methodChannel?.invokeMethod("onNativePopupShowing", arguments: nil)
    
    // Create popover if needed
    if calendarPopover == nil {
      calendarPopover = NSPopover()
      calendarViewController = CalendarViewController()
      calendarViewController?.isDarkMode = isDarkMode
      calendarPopover?.contentViewController = calendarViewController
      calendarPopover?.behavior = .transient
      calendarPopover?.animates = true
    }
    
    // Update theme in case it changed
    calendarViewController?.isDarkMode = isDarkMode
    
    // Update calendar to current date
    calendarViewController?.updateToCurrentDate()
    
    // Show popover below the button
    calendarPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    
    // Add global event monitor to close popover when clicking outside
    popoverEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
      self?.closeCalendarPopover()
    }
  }
  
  private func closeCalendarPopover() {
    calendarPopover?.performClose(nil)
    if let monitor = popoverEventMonitor {
      NSEvent.removeMonitor(monitor)
      popoverEventMonitor = nil
    }
  }
  
  // MARK: - Menu Bar Popover (Native)
  
  private func showMenuBarPopover(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let itemId = args["itemId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "itemId is required", details: nil))
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        result(false)
        return
      }
      
      // Close calendar popover if open
      if let popover = self.calendarPopover, popover.isShown {
        self.closeCalendarPopover()
      }
      
      // Get the status item button for positioning
      guard let statusItem = self.statusItems[itemId],
            let button = statusItem.button else {
        result(false)
        return
      }
      
      // Close existing popover if different item
      if self.menuBarPopoverPanel?.isVisible == true && self.currentPopoverItemId != itemId {
        self.closeMenuBarPopover()
      }
      
      // If same item and popover is shown, close it (toggle behavior)
      if self.menuBarPopoverPanel?.isVisible == true && self.currentPopoverItemId == itemId {
        self.closeMenuBarPopover()
        result(true)
        return
      }
      
      // Create view controller if needed
      if self.menuBarPopoverViewController == nil {
        self.menuBarPopoverViewController = MenuBarPopoverViewController()
      }
      
      // Create panel if needed
      if self.menuBarPopoverPanel == nil {
        self.menuBarPopoverPanel = BorderlessPopoverPanel(
          contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
          styleMask: [.borderless, .nonactivatingPanel],
          backing: .buffered,
          defer: false
        )
        self.menuBarPopoverPanel?.contentViewController = self.menuBarPopoverViewController
      }
      
      // Configure the view controller with data
      self.menuBarPopoverViewController?.configure(
        itemId: itemId,
        data: args,
        isDarkMode: self.isDarkMode,
        onShowWindow: { [weak self] in
          self?.showWindowClicked()
          self?.closeMenuBarPopover()
        },
        onHideWindow: { [weak self] in
          self?.hideWindowClicked()
          self?.closeMenuBarPopover()
        },
        onExitApp: { [weak self] in
          self?.exitClicked()
        },
        onActivityMonitorTap: { [weak self] in
          self?.openActivityMonitor()
          self?.closeMenuBarPopover()
        }
      )
      
      self.currentPopoverItemId = itemId
      
      // Position panel below the status bar button
      if let buttonWindow = button.window {
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        // Get panel size from view controller
        let panelSize = self.menuBarPopoverViewController?.view.fittingSize ?? NSSize(width: 280, height: 200)
        
        // Position below button, centered
        let panelX = screenFrame.midX - panelSize.width / 2
        let panelY = screenFrame.minY - panelSize.height - 4  // 4pt gap below menu bar
        
        self.menuBarPopoverPanel?.setFrame(NSRect(x: panelX, y: panelY, width: panelSize.width, height: panelSize.height), display: true)
      }
      
      // Show the panel
      self.menuBarPopoverPanel?.orderFront(nil)
      
      // Add global event monitor to close popover when clicking outside
      self.menuBarPopoverEventMonitor = NSEvent.addGlobalMonitorForEvents(
        matching: [.leftMouseDown, .rightMouseDown]
      ) { [weak self] event in
        if let panel = self?.menuBarPopoverPanel,
           panel.isVisible {
          let mouseLocation = NSEvent.mouseLocation
          if !panel.frame.contains(mouseLocation) {
            self?.closeMenuBarPopover()
          }
        }
      }
      
      result(true)
    }
  }
  
  private func hideMenuBarPopover(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      self?.closeMenuBarPopover()
      result(true)
    }
  }
  
  private func updateMenuBarPopoverContent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.menuBarPopoverViewController?.updateData(args)
      result(true)
    }
  }
  
  private func closeMenuBarPopover() {
    menuBarPopoverPanel?.orderOut(nil)
    if let monitor = menuBarPopoverEventMonitor {
      NSEvent.removeMonitor(monitor)
      menuBarPopoverEventMonitor = nil
    }
    currentPopoverItemId = nil
    popoverChannel?.invokeMethod("onPopoverClosed", arguments: nil)
  }
  
  private func openActivityMonitor() {
    if let activityMonitorURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
      NSWorkspace.shared.openApplication(at: activityMonitorURL, configuration: NSWorkspace.OpenConfiguration())
    }
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

/// A borderless panel for displaying popovers without the arrow
class BorderlessPopoverPanel: NSPanel {
  override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
    super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    
    // Configure panel appearance
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = true
    self.level = .popUpMenu
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    self.isMovableByWindowBackground = false
    self.hidesOnDeactivate = false
  }
  
  override var canBecomeKey: Bool {
    return true
  }
}
