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
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: style,
            .baselineOffset: 0
          ]
          attributedString = NSAttributedString(string: timeText, attributes: timeAttributes)
        } else {
          style.lineSpacing = -2  // Tighter line spacing
          style.paragraphSpacing = 0
          style.maximumLineHeight = CGFloat(fontSize) + 1
          
          let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(fontSize), weight: fontWeight),
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: style,
            .baselineOffset: -5  // Lower the text more
          ]
          
          let fullText = "\(topText)\n\(bottomText)"
          attributedString = NSAttributedString(string: fullText, attributes: attributes)
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
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - Calendar View Controller

class CalendarViewController: NSViewController {
  private var currentYear: Int = 0
  private var currentMonth: Int = 0
  private var selectedDate: Date?
  
  private let calendar = Calendar.current
  private let dateFormatter = DateFormatter()
  
  private var monthLabel: NSTextField!
  private var gridStackView: NSStackView!
  private var weekdayStack: NSStackView!
  private var timeLabel: NSTextField!
  private var timeTimer: Timer?
  
  deinit {
    timeTimer?.invalidate()
  }
  
  override func loadView() {
    let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 100))
    containerView.wantsLayer = true
    
    // Main stack view
    let mainStack = NSStackView()
    mainStack.orientation = .vertical
    mainStack.alignment = .centerX
    mainStack.spacing = 0
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(mainStack)
    
    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: containerView.topAnchor),
      mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
    ])
    
    // Calendar container with background
    let calendarContainer = NSView()
    calendarContainer.wantsLayer = true
    calendarContainer.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1.0).cgColor
    calendarContainer.translatesAutoresizingMaskIntoConstraints = false
    
    let calendarStack = NSStackView()
    calendarStack.orientation = .vertical
    calendarStack.alignment = .centerX
    calendarStack.spacing = 10
    calendarStack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    calendarStack.translatesAutoresizingMaskIntoConstraints = false
    calendarContainer.addSubview(calendarStack)
    
    NSLayoutConstraint.activate([
      calendarStack.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
      calendarStack.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor),
      calendarStack.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor),
      calendarStack.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor)
    ])
    
    // Navigation header - use overlay approach for true centering
    let headerContainer = NSView()
    headerContainer.translatesAutoresizingMaskIntoConstraints = false
    
    // Month label centered
    monthLabel = NSTextField(labelWithString: "")
    monthLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
    monthLabel.alignment = .center
    monthLabel.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(monthLabel)
    
    // Navigation buttons on sides
    let prevButton = createNavigationButton(title: "◀", action: #selector(previousMonth))
    prevButton.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(prevButton)
    
    let nextButton = createNavigationButton(title: "▶", action: #selector(nextMonth))
    nextButton.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(nextButton)
    
    let todayButton = createNavigationButton(title: "Today", action: #selector(goToToday))
    todayButton.font = NSFont.systemFont(ofSize: 14)
    todayButton.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(todayButton)
    
    NSLayoutConstraint.activate([
      // Center month label
      monthLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
      monthLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
      
      // Prev button on left of month label
      prevButton.trailingAnchor.constraint(equalTo: monthLabel.leadingAnchor, constant: -8),
      prevButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
      
      // Next button on right of month label
      nextButton.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 8),
      nextButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
      
      // Today button on far right
      todayButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
      todayButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
      
      // Header height
      headerContainer.heightAnchor.constraint(equalToConstant: 30)
    ])
    
    calendarStack.addArrangedSubview(headerContainer)
    
    // Constrain header to fill width
    NSLayoutConstraint.activate([
      headerContainer.leadingAnchor.constraint(equalTo: calendarStack.leadingAnchor, constant: 16),
      headerContainer.trailingAnchor.constraint(equalTo: calendarStack.trailingAnchor, constant: -16)
    ])
    
    // Weekday headers - use fixed width cells
    weekdayStack = NSStackView()
    weekdayStack.orientation = .horizontal
    weekdayStack.distribution = .fillEqually
    weekdayStack.spacing = 0
    weekdayStack.translatesAutoresizingMaskIntoConstraints = false
    
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    for day in weekdays {
      let label = NSTextField(labelWithString: day)
      label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
      label.textColor = NSColor.secondaryLabelColor
      label.alignment = .center
      weekdayStack.addArrangedSubview(label)
    }
    
    calendarStack.addArrangedSubview(weekdayStack)
    
    // Constrain weekday to fill width
    NSLayoutConstraint.activate([
      weekdayStack.leadingAnchor.constraint(equalTo: calendarStack.leadingAnchor, constant: 16),
      weekdayStack.trailingAnchor.constraint(equalTo: calendarStack.trailingAnchor, constant: -16)
    ])
    
    // Days grid
    gridStackView = NSStackView()
    gridStackView.orientation = .vertical
    gridStackView.spacing = 4
    gridStackView.distribution = .fillEqually
    gridStackView.translatesAutoresizingMaskIntoConstraints = false
    
    calendarStack.addArrangedSubview(gridStackView)
    
    // Constrain gridStackView to have same width as weekdayStack
    NSLayoutConstraint.activate([
      gridStackView.leadingAnchor.constraint(equalTo: weekdayStack.leadingAnchor),
      gridStackView.trailingAnchor.constraint(equalTo: weekdayStack.trailingAnchor)
    ])
    
    mainStack.addArrangedSubview(calendarContainer)
    
    // Constrain calendar container to fill width
    NSLayoutConstraint.activate([
      calendarContainer.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
      calendarContainer.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
    ])
    
    // Time label container with different background
    let timeContainer = NSView()
    timeContainer.wantsLayer = true
    timeContainer.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1.0).cgColor
    timeContainer.translatesAutoresizingMaskIntoConstraints = false
    
    timeLabel = NSTextField(labelWithString: "")
    timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 26, weight: .light)
    timeLabel.alignment = .center
    timeLabel.textColor = NSColor.labelColor
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeContainer.addSubview(timeLabel)
    
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 12),
      timeLabel.bottomAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: -12),
      timeLabel.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
      timeLabel.trailingAnchor.constraint(equalTo: timeContainer.trailingAnchor)
    ])
    
    mainStack.addArrangedSubview(timeContainer)
    
    // Constrain time container to fill width
    NSLayoutConstraint.activate([
      timeContainer.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
      timeContainer.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
    ])
    
    self.view = containerView
    
    // Update frame to fit content
    containerView.layoutSubtreeIfNeeded()
    let fittingSize = mainStack.fittingSize
    containerView.frame = NSRect(x: 0, y: 0, width: max(340, fittingSize.width), height: fittingSize.height)
  }
  
  private func createNavigationButton(title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: self, action: action)
    button.bezelStyle = .inline
    button.isBordered = false
    button.font = NSFont.systemFont(ofSize: 16)
    return button
  }
  
  func updateToCurrentDate() {
    // Ensure view is loaded before accessing UI elements
    _ = self.view
    
    let now = Date()
    currentYear = calendar.component(.year, from: now)
    currentMonth = calendar.component(.month, from: now)
    selectedDate = now
    updateCalendarDisplay()
    startTimeTimer()
  }
  
  private func startTimeTimer() {
    // Stop existing timer
    timeTimer?.invalidate()
    
    // Update time immediately
    updateTimeLabel()
    
    // Update every second
    timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateTimeLabel()
    }
  }
  
  private func updateTimeLabel() {
    let now = Date()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    timeLabel.stringValue = dateFormatter.string(from: now)
  }
  
  @objc private func previousMonth() {
    currentMonth -= 1
    if currentMonth < 1 {
      currentMonth = 12
      currentYear -= 1
    }
    updateCalendarDisplay()
  }
  
  @objc private func nextMonth() {
    currentMonth += 1
    if currentMonth > 12 {
      currentMonth = 1
      currentYear += 1
    }
    updateCalendarDisplay()
  }
  
  @objc private func goToToday() {
    updateToCurrentDate()
  }
  
  private func updateCalendarDisplay() {
    // Update month label
    dateFormatter.dateFormat = "MMMM yyyy"
    let components = DateComponents(year: currentYear, month: currentMonth, day: 1)
    if let date = calendar.date(from: components) {
      monthLabel.stringValue = dateFormatter.string(from: date)
    }
    
    // Clear existing day buttons
    for subview in gridStackView.arrangedSubviews {
      gridStackView.removeArrangedSubview(subview)
      subview.removeFromSuperview()
    }
    
    // Get first day of month and number of days
    var startComponents = DateComponents()
    startComponents.year = currentYear
    startComponents.month = currentMonth
    startComponents.day = 1
    
    guard let firstDayOfMonth = calendar.date(from: startComponents),
          let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
      return
    }
    
    let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) // 1 = Sunday
    let numberOfDays = range.count
    
    // Get today's date for highlighting
    let today = Date()
    let todayYear = calendar.component(.year, from: today)
    let todayMonth = calendar.component(.month, from: today)
    let todayDay = calendar.component(.day, from: today)
    
    // Create 6 weeks of rows
    var dayCounter = 1
    for week in 0..<6 {
      let rowStack = NSStackView()
      rowStack.orientation = .horizontal
      rowStack.distribution = .fillEqually
      rowStack.spacing = 0  // Match weekday header spacing
      rowStack.translatesAutoresizingMaskIntoConstraints = false
      
      for weekday in 1...7 {
        let cellIndex = week * 7 + weekday
        let dayNumber: Int?
        
        if cellIndex < firstWeekday || dayCounter > numberOfDays {
          dayNumber = nil
        } else {
          dayNumber = dayCounter
          dayCounter += 1
        }
        
        let button = createDayButton(
          day: dayNumber,
          isToday: dayNumber != nil &&
                   currentYear == todayYear &&
                   currentMonth == todayMonth &&
                   dayNumber == todayDay
        )
        rowStack.addArrangedSubview(button)
      }
      
      gridStackView.addArrangedSubview(rowStack)
      
      // Constrain row to fill the grid width (match weekday header)
      NSLayoutConstraint.activate([
        rowStack.leadingAnchor.constraint(equalTo: gridStackView.leadingAnchor),
        rowStack.trailingAnchor.constraint(equalTo: gridStackView.trailingAnchor)
      ])
      
      // Stop if we've rendered all days and completed the week
      if dayCounter > numberOfDays && week >= 3 {
        break
      }
    }
  }
  
  private func createDayButton(day: Int?, isToday: Bool) -> NSButton {
    let button = NSButton()
    button.bezelStyle = .inline
    button.isBordered = false
    
    if let day = day {
      button.title = "\(day)"
      button.target = self
      button.action = #selector(dayClicked(_:))
      button.tag = day
      
      if isToday {
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        button.layer?.cornerRadius = 8
        button.contentTintColor = NSColor.white
      }
    } else {
      button.title = ""
      button.isEnabled = false
    }
    
    button.font = NSFont.systemFont(ofSize: 16)
    return button
  }
  
  @objc private func dayClicked(_ sender: NSButton) {
    let day = sender.tag
    
    // Create the date for the clicked day
    var components = DateComponents()
    components.year = currentYear
    components.month = currentMonth
    components.day = day
    components.hour = 12 // Noon to avoid timezone issues
    
    guard let clickedDate = calendar.date(from: components) else { return }
    
    // Open system Calendar app at the clicked date
    let timestamp = clickedDate.timeIntervalSinceReferenceDate
    if let url = URL(string: "calshow:\(timestamp)") {
      NSWorkspace.shared.open(url)
    }
    
    // Close the popover
    if let popover = (NSApp.delegate as? AppDelegate)?.calendarPopover {
      popover.performClose(nil)
    }
  }
}
