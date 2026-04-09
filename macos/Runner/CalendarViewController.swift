import Cocoa

class CalendarViewController: NSViewController {
  private var currentYear: Int = 0
  private var currentMonth: Int = 0

  private let calendar = Calendar.current
  private let dateFormatter = DateFormatter()
  private let lunarService = LunarService()
  private let holidayService = HolidayService.shared

  private var monthLabel: NSTextField!
  private var calendarGrid: NSGridView!
  private var timeLabel: NSTextField!
  private var timeTimer: Timer?

  /// Cell size: wider/taller to fit two lines (solar date + lunar text) + badge
  private let itemSize: CGSize = CGSize(width: 55, height: 48)
  private let headerHeight: CGFloat = 24.0

  /// Localized labels from Flutter (via _buildNativeLabels)
  var labels: [String: String] = [:] {
    didSet {
      if isViewLoaded {
        updateCalendarDisplay()
      }
    }
  }

  // Theme mode: true = dark, false = light
  var isDarkMode: Bool = true {
    didSet {
      if isViewLoaded {
        updateAppearance()
      }
    }
  }

  // MARK: - Theme Colors

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

  private var dimmedLunarTextColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.35, alpha: 1.0)
      : NSColor(white: 0.7, alpha: 1.0)
  }

  private var iconTintColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.6, alpha: 1.0)
      : NSColor(white: 0.4, alpha: 1.0)
  }

  /// Weekend header text color (red)
  private var weekendHeaderColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
      : NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
  }

  /// Weekend date number color (red)
  private var weekendTextColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
      : NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
  }

  /// Festival / solar term text color (red/orange)
  private var festivalTextColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.95, green: 0.4, blue: 0.35, alpha: 1.0)
      : NSColor(red: 0.85, green: 0.25, blue: 0.2, alpha: 1.0)
  }

  /// Solar term text color (slightly different from festival)
  private var solarTermTextColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.3, green: 0.75, blue: 0.55, alpha: 1.0)
      : NSColor(red: 0.15, green: 0.55, blue: 0.35, alpha: 1.0)
  }

  /// Today highlight background (gold/amber)
  private var todayBackgroundColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.7, green: 0.6, blue: 0.15, alpha: 0.5)
      : NSColor(red: 0.95, green: 0.85, blue: 0.4, alpha: 0.5)
  }

  /// Holiday background (light pink/red)
  private var holidayBackgroundColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 0.35)
      : NSColor(red: 1.0, green: 0.85, blue: 0.85, alpha: 1.0)
  }

  /// Badge colors
  private var holidayBadgeColor: NSColor {
    NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
  }

  private var adjustmentBadgeColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.3, green: 0.4, blue: 0.85, alpha: 1.0)
      : NSColor(red: 0.2, green: 0.35, blue: 0.8, alpha: 1.0)
  }

  private var todayBadgeColor: NSColor {
    isDarkMode
      ? NSColor(red: 0.85, green: 0.65, blue: 0.1, alpha: 1.0)
      : NSColor(red: 0.75, green: 0.55, blue: 0.0, alpha: 1.0)
  }

  private var navButtonBorderColor: NSColor {
    isDarkMode
      ? NSColor(white: 0.4, alpha: 1.0)
      : NSColor(white: 0.7, alpha: 1.0)
  }

  // MARK: - View References

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

  // MARK: - Appearance

  private func updateAppearance() {
    mainContainer?.layer?.borderColor = borderColor.cgColor
    titleBar?.layer?.backgroundColor = titleBarBackgroundColor.cgColor
    calendarContainer?.layer?.backgroundColor = calendarBackgroundColor.cgColor
    timeContainer?.layer?.backgroundColor = timeContainerBackgroundColor.cgColor

    titleLabel?.textColor = primaryTextColor
    calendarButton?.contentTintColor = iconTintColor
    monthLabel?.textColor = primaryTextColor
    timeLabel?.textColor = primaryTextColor

    updateNavButtonAppearance(prevButton)
    updateNavButtonAppearance(nextButton)
    todayButton?.contentTintColor = primaryTextColor
    todayButton?.layer?.borderColor = navButtonBorderColor.cgColor

    updateCalendarDisplay()
  }

  private func updateNavButtonAppearance(_ button: NSButton?) {
    button?.contentTintColor = primaryTextColor
    button?.layer?.borderColor = navButtonBorderColor.cgColor
  }

  // MARK: - View Setup

  override func loadView() {
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
      mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
    ])

    // Title bar
    titleBar = createTitleBar()
    mainStack.addArrangedSubview(titleBar)

    // Calendar section
    calendarContainer = NSStackView()
    calendarContainer.orientation = .vertical
    calendarContainer.spacing = 4
    calendarContainer.wantsLayer = true
    calendarContainer.layer?.backgroundColor = calendarBackgroundColor.cgColor
    calendarContainer.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

    let headerView = createNavigationHeader()
    calendarContainer.addArrangedSubview(headerView)

    calendarGrid = NSGridView()
    calendarGrid.rowSpacing = 1
    calendarGrid.columnSpacing = 1
    calendarGrid.translatesAutoresizingMaskIntoConstraints = false
    calendarContainer.addArrangedSubview(calendarGrid)

    mainStack.addArrangedSubview(calendarContainer)

    // Bottom section: time display
    timeContainer = NSView()
    timeContainer.wantsLayer = true
    timeContainer.layer?.backgroundColor = timeContainerBackgroundColor.cgColor
    timeContainer.translatesAutoresizingMaskIntoConstraints = false

    timeLabel = NSTextField(labelWithString: "")
    timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .light)
    timeLabel.alignment = .center
    timeLabel.textColor = primaryTextColor
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeContainer.addSubview(timeLabel)

    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: timeContainer.topAnchor, constant: 8),
      timeLabel.bottomAnchor.constraint(equalTo: timeContainer.bottomAnchor, constant: -8),
      timeLabel.leadingAnchor.constraint(equalTo: timeContainer.leadingAnchor),
      timeLabel.trailingAnchor.constraint(equalTo: timeContainer.trailingAnchor),
    ])

    mainStack.addArrangedSubview(timeContainer)

    NSLayoutConstraint.activate([
      timeContainer.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
      timeContainer.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
    ])

    self.view = mainContainer
  }

  // MARK: - Navigation Header

  private func createNavigationHeader() -> NSView {
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false

    prevButton = createNavButton(title: "<", action: #selector(previousMonth))
    nextButton = createNavButton(title: ">", action: #selector(nextMonth))
    let todayLabel = labels["calendarToday"] ?? "今"
    todayButton = createNavButton(title: todayLabel, action: #selector(goToToday))

    monthLabel = NSTextField(labelWithString: "")
    monthLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
    monthLabel.alignment = .center
    monthLabel.textColor = primaryTextColor
    monthLabel.translatesAutoresizingMaskIntoConstraints = false

    prevButton.translatesAutoresizingMaskIntoConstraints = false
    nextButton.translatesAutoresizingMaskIntoConstraints = false
    todayButton.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(prevButton)
    container.addSubview(monthLabel)
    container.addSubview(todayButton)
    container.addSubview(nextButton)

    NSLayoutConstraint.activate([
      container.heightAnchor.constraint(equalToConstant: 28),

      // < pinned to left edge
      prevButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      prevButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      // > pinned to right edge
      nextButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      nextButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      // Today button left of >
      todayButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -4),
      todayButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      // Month label centered
      monthLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      monthLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    return container
  }

  // MARK: - Title Bar

  private func createTitleBar() -> NSView {
    let bar = NSView()
    bar.wantsLayer = true
    bar.layer?.backgroundColor = titleBarBackgroundColor.cgColor
    bar.translatesAutoresizingMaskIntoConstraints = false

    calendarButton = NSButton()
    calendarButton.bezelStyle = .inline
    calendarButton.isBordered = false
    calendarButton.target = self
    calendarButton.action = #selector(openCalendarApp)
    calendarButton.toolTip = labels["calendarOpenCalendar"] ?? "Open Calendar"
    calendarButton.translatesAutoresizingMaskIntoConstraints = false

    if #available(macOS 11.0, *) {
      let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
      if let icon = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendar") {
        calendarButton.image = icon.withSymbolConfiguration(config)
      }
    } else {
      calendarButton.title = "📅"
    }
    calendarButton.contentTintColor = iconTintColor

    titleLabel = NSTextField(labelWithString: labels["calendarTitle"] ?? "Calendar")
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
      calendarButton.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
      calendarButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      titleLabel.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
    ])

    return bar
  }

  @objc private func openCalendarApp() {
    let calendarPath = "/System/Applications/Calendar.app"
    NSWorkspace.shared.open(URL(fileURLWithPath: calendarPath))

    if let popover = self.view.window?.parent as? NSPopover {
      popover.performClose(self)
    } else {
      self.dismiss(self)
    }
  }

  // MARK: - Navigation Button

  private func createNavButton(title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: self, action: action)
    button.bezelStyle = .inline
    button.isBordered = false
    button.font = NSFont.systemFont(ofSize: 16, weight: .medium)
    button.contentTintColor = primaryTextColor
    button.wantsLayer = true
    button.layer?.cornerRadius = 4
    button.layer?.borderWidth = 1
    button.layer?.borderColor = navButtonBorderColor.cgColor

    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
      button.heightAnchor.constraint(equalToConstant: 28),
    ])

    return button
  }

  // MARK: - Lifecycle

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
    let weekdayNames = (labels["calendarWeekdays"] ?? "Sun,Mon,Tue,Wed,Thu,Fri,Sat").split(separator: ",").map(String.init)
    let weekday = calendar.component(.weekday, from: now)
    let weekdayStr = weekdayNames[max(0, min(weekdayNames.count - 1, weekday - 1))]
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateStr = dateFormatter.string(from: now)
    dateFormatter.dateFormat = "HH:mm:ss"
    let timeStr = dateFormatter.string(from: now)
    timeLabel.stringValue = "\(dateStr) \(weekdayStr) \(timeStr)"
  }

  // MARK: - Navigation Actions

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

  // MARK: - Calendar Display

  /// Build the localized month title string
  private func localizedMonthTitle() -> String {
    let monthNames = (labels["calendarMonths"] ?? "January,February,March,April,May,June,July,August,September,October,November,December").split(separator: ",").map(String.init)
    let monthName = monthNames[max(0, min(monthNames.count - 1, currentMonth - 1))]
    let template = labels["calendarYearMonth"] ?? "{year} {month}"
    return template
      .replacingOccurrences(of: "{year}", with: "\(currentYear)")
      .replacingOccurrences(of: "{month}", with: monthName)
  }

  private func updateCalendarDisplay() {
    monthLabel.stringValue = localizedMonthTitle()

    // Clear grid
    for subview in calendarGrid.subviews {
      subview.removeFromSuperview()
    }
    while calendarGrid.numberOfRows > 0 {
      calendarGrid.removeRow(at: 0)
    }

    // Weekday headers: Monday first, Sat/Sun in red
    let weekdays = [
      labels["calendarWeekMon"] ?? "Mon",
      labels["calendarWeekTue"] ?? "Tue",
      labels["calendarWeekWed"] ?? "Wed",
      labels["calendarWeekThu"] ?? "Thu",
      labels["calendarWeekFri"] ?? "Fri",
      labels["calendarWeekSat"] ?? "Sat",
      labels["calendarWeekSun"] ?? "Sun",
    ]
    let isWeekendHeader = [false, false, false, false, false, true, true]
    let headerViews = zip(weekdays, isWeekendHeader).map { createHeaderCell($0.0, isWeekend: $0.1) }
    calendarGrid.addRow(with: headerViews)

    // Generate days (Monday-first)
    let weeks = generateDays(for: currentMonth, in: currentYear)

    let today = Date()
    let todayYear = calendar.component(.year, from: today)
    let todayMonth = calendar.component(.month, from: today)
    let todayDay = calendar.component(.day, from: today)

    for week in weeks {
      let dayViews = week.map { day -> NSView in
        let isToday = day.year == todayYear && day.month == todayMonth && day.day == todayDay
        let isCurrentMonth = day.month == currentMonth

        // Build the Date for lunar/holiday lookup
        guard let date = calendar.date(from: day) else {
          return createEmptyCell()
        }

        let lunarDescriptor = lunarService.describe(date: date)
        let holiday = holidayService.holidayInfo(for: date)

        // Determine if weekend (column index 5 or 6 in Monday-first grid)
        let weekdayValue = calendar.component(.weekday, from: date)
        let isWeekend = (weekdayValue == 1 || weekdayValue == 7) // Sunday=1, Saturday=7

        return createDayCell(
          day: day.day ?? 0,
          isToday: isToday,
          isCurrentMonth: isCurrentMonth,
          isWeekend: isWeekend,
          lunarDescriptor: lunarDescriptor,
          holiday: holiday
        )
      }
      calendarGrid.addRow(with: dayViews)
    }

    // Set column widths
    for i in 0..<calendarGrid.numberOfColumns {
      let column = calendarGrid.column(at: i)
      column.width = itemSize.width
      column.xPlacement = .center
    }

    // Set row heights
    for i in 0..<calendarGrid.numberOfRows {
      let row = calendarGrid.row(at: i)
      row.height = (i == 0) ? headerHeight : itemSize.height
      row.yPlacement = .center
    }
  }

  // MARK: - Header Cell

  private func createHeaderCell(_ text: String, isWeekend: Bool) -> NSView {
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false

    let field = NSTextField(labelWithString: text)
    field.font = NSFont.systemFont(ofSize: 12, weight: .medium)
    field.textColor = isWeekend ? weekendHeaderColor : secondaryTextColor
    field.alignment = .center
    field.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(field)

    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    return container
  }

  // MARK: - Day Cell

  private func createEmptyCell() -> NSView {
    let container = NSView()
    container.translatesAutoresizingMaskIntoConstraints = false
    return container
  }

  private func createDayCell(
    day: Int,
    isToday: Bool,
    isCurrentMonth: Bool,
    isWeekend: Bool,
    lunarDescriptor: LunarDateDescriptor,
    holiday: HolidayEntry?
  ) -> NSView {
    let container = NSView()
    container.wantsLayer = true
    container.translatesAutoresizingMaskIntoConstraints = false

    // Background rounded rectangle
    let backgroundView = NSView()
    backgroundView.wantsLayer = true
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.layer?.cornerRadius = 6

    if isToday {
      backgroundView.layer?.backgroundColor = todayBackgroundColor.cgColor
    } else if holiday?.kind == .statutoryHoliday {
      backgroundView.layer?.backgroundColor = holidayBackgroundColor.cgColor
    }

    container.addSubview(backgroundView)

    // Solar date text (top line)
    let dayText = day > 0 ? "\(day)" : ""
    let dayField = NSTextField(labelWithString: dayText)
    dayField.font = NSFont.systemFont(ofSize: 14, weight: .medium)
    dayField.alignment = .center
    dayField.isBezeled = false
    dayField.drawsBackground = false
    dayField.isEditable = false
    dayField.isSelectable = false
    dayField.translatesAutoresizingMaskIntoConstraints = false

    // Day text color
    if !isCurrentMonth {
      dayField.textColor = dimmedTextColor
    } else if isWeekend {
      dayField.textColor = weekendTextColor
    } else {
      dayField.textColor = primaryTextColor
    }

    container.addSubview(dayField)

    // Lunar text (bottom line)
    let lunarText = lunarDescriptor.displayText()
    let lunarField = NSTextField(labelWithString: lunarText)
    lunarField.font = NSFont.systemFont(ofSize: 9, weight: .regular)
    lunarField.alignment = .center
    lunarField.isBezeled = false
    lunarField.drawsBackground = false
    lunarField.isEditable = false
    lunarField.isSelectable = false
    lunarField.translatesAutoresizingMaskIntoConstraints = false

    // Lunar text color based on type
    if !isCurrentMonth {
      lunarField.textColor = dimmedLunarTextColor
    } else if lunarDescriptor.isFestival {
      lunarField.textColor = festivalTextColor
    } else if lunarDescriptor.solarTermName != nil {
      lunarField.textColor = solarTermTextColor
    } else {
      lunarField.textColor = secondaryTextColor
    }

    // If holiday name exists, show holiday name instead of lunar text
    if let holiday = holiday {
      let holidayName = holiday.name.replacingOccurrences(of: "调休上班", with: "")
      if holiday.kind == .statutoryHoliday {
        lunarField.stringValue = holidayName
        lunarField.textColor = festivalTextColor
      }
    }

    container.addSubview(lunarField)

    // Layout: background fills the cell, day text on top, lunar text below
    let cellWidth: CGFloat = itemSize.width - 2
    let cellHeight: CGFloat = itemSize.height - 2

    NSLayoutConstraint.activate([
      backgroundView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      backgroundView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      backgroundView.widthAnchor.constraint(equalToConstant: cellWidth),
      backgroundView.heightAnchor.constraint(equalToConstant: cellHeight),

      dayField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      dayField.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 4),

      lunarField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      lunarField.topAnchor.constraint(equalTo: dayField.bottomAnchor, constant: 0),
      lunarField.widthAnchor.constraint(lessThanOrEqualToConstant: cellWidth - 2),
    ])

    // Badge (top-right corner): 今 / 休 / 班
    var badgeText: String?
    var badgeColor: NSColor?

    if isToday {
      badgeText = "今"
      badgeColor = todayBadgeColor
    } else if let holiday = holiday {
      switch holiday.kind {
      case .statutoryHoliday:
        badgeText = "休"
        badgeColor = holidayBadgeColor
      case .workingAdjustmentDay:
        badgeText = "班"
        badgeColor = adjustmentBadgeColor
      }
    }

    if let text = badgeText, let color = badgeColor {
      let badge = createBadge(text: text, color: color)
      container.addSubview(badge)

      NSLayoutConstraint.activate([
        badge.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 1),
        badge.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -1),
      ])
    }

    return container
  }

  // MARK: - Badge

  private func createBadge(text: String, color: NSColor) -> NSView {
    let badgeSize: CGFloat = 14
    let container = NSView()
    container.wantsLayer = true
    container.layer?.cornerRadius = badgeSize / 2
    container.layer?.backgroundColor = color.withAlphaComponent(0.2).cgColor
    container.translatesAutoresizingMaskIntoConstraints = false

    let label = NSTextField(labelWithString: text)
    label.font = NSFont.systemFont(ofSize: 8, weight: .bold)
    label.textColor = color
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)

    NSLayoutConstraint.activate([
      container.widthAnchor.constraint(equalToConstant: badgeSize),
      container.heightAnchor.constraint(equalToConstant: badgeSize),
      label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    return container
  }

  // MARK: - Day Generation (Monday-first)

  private func generateDays(for month: Int, in year: Int) -> [[DateComponents]] {
    let dateComponents = DateComponents(year: year, month: month)

    guard let range = calendar.range(of: .day, in: .month, for: calendar.date(from: dateComponents)!),
      let firstDayOfMonth = calendar.date(from: dateComponents),
      let firstWeekdayOfMonth = calendar.dateComponents([.weekday], from: firstDayOfMonth).weekday
    else {
      return []
    }

    // Convert Sunday=1..Saturday=7 to Monday=0..Sunday=6
    let mondayBasedWeekday = (firstWeekdayOfMonth + 5) % 7
    let daysFromPreviousMonth = mondayBasedWeekday

    // Previous month info
    var previousMonthComponents = dateComponents
    previousMonthComponents.month = (month == 1) ? 12 : month - 1
    previousMonthComponents.year = (month == 1) ? year - 1 : year
    let previousMonthDate = calendar.date(from: previousMonthComponents)!
    let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonthDate)!.count

    var allDays: [DateComponents] = []

    // Previous month days
    for i in 0..<daysFromPreviousMonth {
      let day = previousMonthDays - daysFromPreviousMonth + i + 1
      allDays.append(DateComponents(
        year: previousMonthComponents.year,
        month: previousMonthComponents.month,
        day: day
      ))
    }

    // Current month days
    for day in range {
      allDays.append(DateComponents(year: year, month: month, day: day))
    }

    // Next month days to fill remaining slots
    let nextMonth = (month == 12) ? 1 : month + 1
    let nextYear = (month == 12) ? year + 1 : year
    var nextDay = 1
    while allDays.count < 42 {
      allDays.append(DateComponents(year: nextYear, month: nextMonth, day: nextDay))
      nextDay += 1
    }

    // Split into weeks
    var weeks: [[DateComponents]] = []
    for i in stride(from: 0, to: allDays.count, by: 7) {
      let week = Array(allDays[i..<min(i + 7, allDays.count)])
      weeks.append(week)
      if let lastDay = week.last, lastDay.month != month && weeks.count >= 4 {
        break
      }
    }

    return weeks
  }
}
