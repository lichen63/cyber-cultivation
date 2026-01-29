import Cocoa

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
  
  // Theme mode: true = dark, false = light
  var isDarkMode: Bool = true {
    didSet {
      if isViewLoaded {
        updateAppearance()
      }
    }
  }
  
  // Colors based on theme mode
  private var borderColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.3, alpha: 1.0)
      : NSColor(white: 0.75, alpha: 1.0)
  }
  
  private var calendarBackgroundColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.15, alpha: 1.0)
      : NSColor(white: 0.97, alpha: 1.0)
  }
  
  private var titleBarBackgroundColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.12, alpha: 1.0)
      : NSColor(white: 0.92, alpha: 1.0)
  }
  
  private var timeContainerBackgroundColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.1, alpha: 1.0)
      : NSColor(white: 0.95, alpha: 1.0)
  }
  
  private var primaryTextColor: NSColor {
    isDarkMode ? .white : .black
  }
  
  private var secondaryTextColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.6, alpha: 1.0)
      : NSColor(white: 0.4, alpha: 1.0)
  }
  
  private var dimmedTextColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.4, alpha: 1.0)
      : NSColor(white: 0.65, alpha: 1.0)
  }
  
  private var iconTintColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.6, alpha: 1.0)
      : NSColor(white: 0.4, alpha: 1.0)
  }
  
  // View references for theme updates
  private var mainContainer: NSView!
  private var titleBar: NSView!
  private var titleLabel: NSTextField!
  private var calendarButton: NSButton!
  private var calendarContainer: NSStackView!
  private var timeContainer: NSView!
  private var prevButton: NSButton!
  private var nextButton: NSButton!
  private var todayButton: NSButton!
  
  deinit {
    timeTimer?.invalidate()
  }
  
  private func updateAppearance() {
    // Update container backgrounds
    mainContainer?.layer?.borderColor = borderColor.cgColor
    titleBar?.layer?.backgroundColor = titleBarBackgroundColor.cgColor
    calendarContainer?.layer?.backgroundColor = calendarBackgroundColor.cgColor
    timeContainer?.layer?.backgroundColor = timeContainerBackgroundColor.cgColor
    
    // Update text colors
    titleLabel?.textColor = primaryTextColor
    calendarButton?.contentTintColor = iconTintColor
    monthLabel?.textColor = primaryTextColor
    timeLabel?.textColor = primaryTextColor
    prevButton?.contentTintColor = primaryTextColor
    nextButton?.contentTintColor = primaryTextColor
    todayButton?.contentTintColor = primaryTextColor
    
    // Refresh calendar to update day cell colors
    updateCalendarDisplay()
  }
  
  override func loadView() {
    // Main container with border
    mainContainer = NSView()
    mainContainer.wantsLayer = true
    mainContainer.layer?.cornerRadius = 10
    mainContainer.layer?.borderColor = borderColor.cgColor
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
    titleBar = createTitleBar()
    mainStack.addArrangedSubview(titleBar)
    
    // Calendar section
    calendarContainer = NSStackView()
    calendarContainer.orientation = .vertical
    calendarContainer.spacing = 8
    calendarContainer.wantsLayer = true
    calendarContainer.layer?.backgroundColor = calendarBackgroundColor.cgColor
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
    timeContainer = NSView()
    timeContainer.wantsLayer = true
    timeContainer.layer?.backgroundColor = timeContainerBackgroundColor.cgColor
    timeContainer.translatesAutoresizingMaskIntoConstraints = false
    
    timeLabel = NSTextField(labelWithString: "")
    timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .light)
    timeLabel.alignment = .center
    timeLabel.textColor = primaryTextColor
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
    monthLabel.textColor = primaryTextColor
    
    // Buttons container
    let buttons = NSStackView()
    buttons.orientation = .horizontal
    buttons.spacing = 4
    
    prevButton = createNavButton(title: "◀", action: #selector(previousMonth))
    nextButton = createNavButton(title: "▶", action: #selector(nextMonth))
    todayButton = createNavButton(title: "Today", action: #selector(goToToday))
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
    let bar = NSView()
    bar.wantsLayer = true
    bar.layer?.backgroundColor = titleBarBackgroundColor.cgColor
    bar.translatesAutoresizingMaskIntoConstraints = false
    
    // Calendar icon button on left edge
    calendarButton = NSButton()
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
    calendarButton.contentTintColor = iconTintColor
    
    // Centered title
    titleLabel = NSTextField(labelWithString: "Clock")
    titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
    titleLabel.alignment = .center
    titleLabel.textColor = primaryTextColor
    titleLabel.backgroundColor = .clear
    titleLabel.drawsBackground = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    bar.addSubview(calendarButton)
    bar.addSubview(titleLabel)
    
    NSLayoutConstraint.activate([
      bar.heightAnchor.constraint(equalToConstant: 32),
      
      // Calendar button on left edge
      calendarButton.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
      calendarButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      
      // Title centered in the title bar
      titleLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor)
    ])
    
    return bar
  }
  
  @objc private func openCalendarApp() {
    let calendarPath = "/System/Applications/Calendar.app"
    NSWorkspace.shared.open(URL(fileURLWithPath: calendarPath))
    
    // Close the popover that contains this view controller
    if let popover = self.view.window?.parent as? NSPopover {
      popover.performClose(self)
    } else {
      // Alternative: find any open popover containing this view
      self.dismiss(self)
    }
  }
  
  private func createNavButton(title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: self, action: action)
    button.bezelStyle = .inline
    button.isBordered = false
    button.font = NSFont.systemFont(ofSize: 14)
    button.contentTintColor = primaryTextColor
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
        return createDayCell(day: day.day ?? 0, isToday: isToday, isCurrentMonth: isCurrentMonth)
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
    field.textColor = secondaryTextColor
    field.alignment = .center
    field.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(field)
    
    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: container.centerYAnchor)
    ])
    
    return container
  }
  
  private func createDayCell(day: Int, isToday: Bool, isCurrentMonth: Bool) -> NSView {
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
      field.textColor = dimmedTextColor
    } else {
      field.textColor = primaryTextColor
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
