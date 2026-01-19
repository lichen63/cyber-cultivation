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

// MARK: - Calendar View Controller

class CalendarViewController: NSViewController {
  private var currentYear: Int = 0
  private var currentMonth: Int = 0
  
  private let calendar = Calendar.current
  private let dateFormatter = DateFormatter()
  
  private var monthLabel: NSTextField!
  private var calendarGrid: NSGridView!
  private var timeLabel: NSTextField!
  private var timeTimer: Timer?
  
  private let itemSize: CGSize = CGSize(width: 36, height: 28)
  
  deinit {
    timeTimer?.invalidate()
  }
  
  override func loadView() {
    // Main container with border
    let mainContainer = NSView()
    mainContainer.wantsLayer = true
    mainContainer.layer?.cornerRadius = 10
    mainContainer.layer?.borderColor = NSColor(white: 0.3, alpha: 1.0).cgColor
    mainContainer.layer?.borderWidth = 1
    mainContainer.layer?.masksToBounds = true
    mainContainer.translatesAutoresizingMaskIntoConstraints = false
    
    let mainStack = NSStackView()
    mainStack.orientation = .vertical
    mainStack.spacing = 0
    mainStack.translatesAutoresizingMaskIntoConstraints = false
    mainContainer.addSubview(mainStack)
    
    NSLayoutConstraint.activate([
      mainStack.topAnchor.constraint(equalTo: mainContainer.topAnchor),
      mainStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
      mainStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
      mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor)
    ])
    
    // Title bar with calendar icon and "Clock" title
    let titleBar = createTitleBar()
    mainStack.addArrangedSubview(titleBar)
    
    // Calendar section
    let calendarContainer = NSStackView()
    calendarContainer.orientation = .vertical
    calendarContainer.spacing = 8
    calendarContainer.wantsLayer = true
    calendarContainer.layer?.backgroundColor = NSColor(white: 0.15, alpha: 1.0).cgColor
    calendarContainer.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    
    // Navigation header
    let headerView = createNavigationHeader()
    calendarContainer.addArrangedSubview(headerView)
    
    // Calendar grid (weekday headers + days)
    calendarGrid = NSGridView()
    calendarGrid.rowSpacing = 2
    calendarGrid.columnSpacing = 0
    calendarGrid.translatesAutoresizingMaskIntoConstraints = false
    calendarContainer.addArrangedSubview(calendarGrid)
    
    mainStack.addArrangedSubview(calendarContainer)
    
    // Time section
    let timeContainer = NSView()
    timeContainer.wantsLayer = true
    timeContainer.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1.0).cgColor
    timeContainer.translatesAutoresizingMaskIntoConstraints = false
    
    timeLabel = NSTextField(labelWithString: "")
    timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .light)
    timeLabel.alignment = .center
    timeLabel.textColor = .white
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeContainer.addSubview(timeLabel)
    
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 10),
      timeLabel.bottomAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: -10),
      timeLabel.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
      timeLabel.trailingAnchor.constraint(equalTo: timeContainer.trailingAnchor)
    ])
    
    mainStack.addArrangedSubview(timeContainer)
    
    // Constrain time container width
    NSLayoutConstraint.activate([
      timeContainer.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
      timeContainer.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
    ])
    
    self.view = mainContainer
  }
  
  private func createNavigationHeader() -> NSView {
    let view = NSStackView()
    view.orientation = .horizontal
    view.distribution = .fill
    view.spacing = 8
    
    // Month/Year label
    monthLabel = NSTextField(labelWithString: "")
    monthLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
    monthLabel.alignment = .left
    monthLabel.textColor = .white
    
    // Buttons container
    let buttons = NSStackView()
    buttons.orientation = .horizontal
    buttons.spacing = 4
    
    let prevButton = createNavButton(title: "◀", action: #selector(previousMonth))
    let nextButton = createNavButton(title: "▶", action: #selector(nextMonth))
    let todayButton = createNavButton(title: "Today", action: #selector(goToToday))
    todayButton.font = NSFont.systemFont(ofSize: 12)
    
    buttons.addArrangedSubview(prevButton)
    buttons.addArrangedSubview(nextButton)
    buttons.addArrangedSubview(todayButton)
    
    view.addArrangedSubview(monthLabel)
    view.addArrangedSubview(NSView()) // Spacer
    view.addArrangedSubview(buttons)
    
    view.heightAnchor.constraint(equalToConstant: 24).isActive = true
    
    return view
  }
  
  private func createTitleBar() -> NSView {
    let titleBar = NSView()
    titleBar.wantsLayer = true
    titleBar.layer?.backgroundColor = NSColor(white: 0.12, alpha: 1.0).cgColor
    titleBar.translatesAutoresizingMaskIntoConstraints = false
    
    // Calendar icon button on left edge
    let calendarButton = NSButton()
    calendarButton.bezelStyle = .inline
    calendarButton.isBordered = false
    calendarButton.target = self
    calendarButton.action = #selector(openCalendarApp)
    calendarButton.toolTip = "Open Calendar"
    calendarButton.translatesAutoresizingMaskIntoConstraints = false
    
    // Use SF Symbol for calendar icon
    if #available(macOS 11.0, *) {
      let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
      if let icon = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar") {
        calendarButton.image = icon.withSymbolConfiguration(config)
      }
    } else {
      calendarButton.title = "📅"
    }
    calendarButton.contentTintColor = NSColor(white: 0.6, alpha: 1.0)
    
    // Centered title
    let titleLabel = NSTextField(labelWithString: "Clock")
    titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
    titleLabel.alignment = .center
    titleLabel.textColor = .white
    titleLabel.backgroundColor = .clear
    titleLabel.drawsBackground = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    titleBar.addSubview(calendarButton)
    titleBar.addSubview(titleLabel)
    
    NSLayoutConstraint.activate([
      titleBar.heightAnchor.constraint(equalToConstant: 32),
      
      // Calendar button on left edge
      calendarButton.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor, constant: 8),
      calendarButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
      
      // Title centered in the title bar
      titleLabel.centerXAnchor.constraint(equalTo: titleBar.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor)
    ])
    
    return titleBar
  }
  
  @objc private func openCalendarApp() {
    let calendarPath = "/System/Applications/Calendar.app"
    NSWorkspace.shared.open(URL(fileURLWithPath: calendarPath))
    
    // Close popover
    if let popover = (NSApp.delegate as? AppDelegate)?.calendarPopover {
      popover.performClose(nil)
    }
  }
  
  private func createNavButton(title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: self, action: action)
    button.bezelStyle = .inline
    button.isBordered = false
    button.font = NSFont.systemFont(ofSize: 14)
    button.contentTintColor = .white
    return button
  }
  
  func updateToCurrentDate() {
    _ = self.view
    
    let now = Date()
    currentYear = calendar.component(.year, from: now)
    currentMonth = calendar.component(.month, from: now)
    updateCalendarDisplay()
    startTimeTimer()
  }
  
  private func startTimeTimer() {
    timeTimer?.invalidate()
    updateTimeLabel()
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
    let now = Date()
    currentYear = calendar.component(.year, from: now)
    currentMonth = calendar.component(.month, from: now)
    updateCalendarDisplay()
  }
  
  private func updateCalendarDisplay() {
    // Update month label
    monthLabel.stringValue = "\(calendar.standaloneMonthSymbols[currentMonth - 1]) \(currentYear)"
    
    // Clear all subviews from the grid first
    for subview in calendarGrid.subviews {
      subview.removeFromSuperview()
    }
    
    // Clear existing rows
    while calendarGrid.numberOfRows > 0 {
      calendarGrid.removeRow(at: 0)
    }
    
    // Add weekday headers
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let headerViews = weekdays.map { createHeaderCell($0) }
    calendarGrid.addRow(with: headerViews)
    
    // Generate days for the month
    let weeks = generateDays(for: currentMonth, in: currentYear)
    
    // Get today's date
    let today = Date()
    let todayYear = calendar.component(.year, from: today)
    let todayMonth = calendar.component(.month, from: today)
    let todayDay = calendar.component(.day, from: today)
    
    // Add day rows
    for week in weeks {
      let dayViews = week.map { day -> NSView in
        let isToday = day.year == todayYear && day.month == todayMonth && day.day == todayDay
        let isCurrentMonth = day.month == currentMonth
        return createDayCell(day: day.day ?? 0, isToday: isToday, isCurrentMonth: isCurrentMonth, components: day)
      }
      calendarGrid.addRow(with: dayViews)
    }
    
    // Set column widths and center alignment
    for i in 0..<calendarGrid.numberOfColumns {
      let column = calendarGrid.column(at: i)
      column.width = itemSize.width
      column.xPlacement = .center
    }
    
    // Set row heights and center alignment
    for i in 0..<calendarGrid.numberOfRows {
      let row = calendarGrid.row(at: i)
      row.height = itemSize.height
      row.yPlacement = .center
    }
  }
  
  private func createHeaderCell(_ text: String) -> NSView {
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false
    
    let field = NSTextField(labelWithString: text)
    field.font = NSFont.systemFont(ofSize: 11, weight: .medium)
    field.textColor = NSColor(white: 0.6, alpha: 1.0)
    field.alignment = .center
    field.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(field)
    
    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])
    
    return container
  }
  
  private func createDayCell(day: Int, isToday: Bool, isCurrentMonth: Bool, components: DateComponents) -> NSView {
    let container = NSView()
    container.wantsLayer = true
    container.translatesAutoresizingMaskIntoConstraints = false
    
    // Create background circle for today
    let backgroundView = NSView()
    backgroundView.wantsLayer = true
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    if isToday {
      backgroundView.layer?.backgroundColor = NSColor.systemRed.cgColor
    }
    container.addSubview(backgroundView)
    
    let field = NSTextField(labelWithString: day > 0 ? "\(day)" : "")
    field.font = NSFont.systemFont(ofSize: 13)
    field.alignment = .center
    field.isBezeled = false
    field.drawsBackground = false
    field.isEditable = false
    field.isSelectable = false
    
    if isToday {
      field.textColor = .white
    } else if !isCurrentMonth {
      field.textColor = NSColor(white: 0.4, alpha: 1.0)
    } else {
      field.textColor = .white
    }
    
    field.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(field)
    
    // Size for the circle background
    let circleSize: CGFloat = 26
    
    NSLayoutConstraint.activate([
      // Center the background circle
      backgroundView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      backgroundView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      backgroundView.widthAnchor.constraint(equalToConstant: circleSize),
      backgroundView.heightAnchor.constraint(equalToConstant: circleSize),
      
      // Center the text
      field.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])
    
    // Set corner radius after layout
    if isToday {
      backgroundView.layer?.cornerRadius = circleSize / 2
    }
    
    return container
  }
  
  private func generateDays(for month: Int, in year: Int) -> [[DateComponents]] {
    let dateComponents = DateComponents(year: year, month: month)
    
    guard let range = calendar.range(of: .day, in: .month, for: calendar.date(from: dateComponents)!),
          let firstDayOfMonth = calendar.date(from: dateComponents),
          let firstWeekdayOfMonth = calendar.dateComponents([.weekday], from: firstDayOfMonth).weekday else {
      return []
    }
    
    let daysFromPreviousMonth = firstWeekdayOfMonth - 1
    
    // Get previous month info
    var previousMonthComponents = dateComponents
    previousMonthComponents.month = (month == 1) ? 12 : month - 1
    previousMonthComponents.year = (month == 1) ? year - 1 : year
    let previousMonthDate = calendar.date(from: previousMonthComponents)!
    let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonthDate)!.count
    
    var allDays: [DateComponents] = []
    
    // Previous month days
    for i in 0..<daysFromPreviousMonth {
      let day = previousMonthDays - daysFromPreviousMonth + i + 1
      allDays.append(DateComponents(year: previousMonthComponents.year, month: previousMonthComponents.month, day: day))
    }
    
    // Current month days
    for day in range {
      allDays.append(DateComponents(year: year, month: month, day: day))
    }
    
    // Next month days to fill remaining slots
    let nextMonth = (month == 12) ? 1 : month + 1
    let nextYear = (month == 12) ? year + 1 : year
    var nextDay = 1
    while allDays.count < 42 { // 6 weeks * 7 days
      allDays.append(DateComponents(year: nextYear, month: nextMonth, day: nextDay))
      nextDay += 1
    }
    
    // Split into weeks
    var weeks: [[DateComponents]] = []
    for i in stride(from: 0, to: allDays.count, by: 7) {
      let week = Array(allDays[i..<min(i+7, allDays.count)])
      weeks.append(week)
      // Stop if we've shown all current month days and completed the week
      if let lastDay = week.last, lastDay.month != month && weeks.count >= 4 {
        break
      }
    }
    
    return weeks
  }
}
