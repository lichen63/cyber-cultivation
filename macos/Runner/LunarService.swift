import Foundation

/// Describes a lunar date with text representations and optional festival/solar term.
struct LunarDateDescriptor {
  let year: Int
  let month: Int
  let day: Int
  let isLeapMonth: Bool
  let yearText: String
  let monthText: String
  let dayText: String
  let festivalName: String?
  let solarTermName: String?

  /// Returns the best display text for a calendar cell.
  /// Priority: festival name > solar term > (month name if 初一) > day text.
  func displayText() -> String {
    if let festivalName { return festivalName }
    if let solarTermName { return solarTermName }
    return day == 1 ? monthText : dayText
  }

  /// Whether the display text represents a special item (festival or solar term).
  var isSpecial: Bool {
    festivalName != nil || solarTermName != nil
  }

  /// Whether the display text is a festival.
  var isFestival: Bool {
    festivalName != nil
  }
}

/// Converts Gregorian dates to Chinese lunar dates with festival and solar term resolution.
struct LunarService {
  private var chineseCalendar: Calendar
  private let festivalResolver: TraditionalFestivalResolver
  private let solarTermResolver: SolarTermResolver

  init() {
    var calendar = Calendar(identifier: .chinese)
    calendar.locale = Locale(identifier: "zh_Hans_CN")
    chineseCalendar = calendar
    festivalResolver = TraditionalFestivalResolver()
    solarTermResolver = SolarTermResolver()
  }

  /// Describes the lunar date for a given Gregorian date.
  func describe(date: Date) -> LunarDateDescriptor {
    let components = chineseCalendar.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 1
    let month = components.month ?? 1
    let day = components.day ?? 1
    // isLeapMonth requires macOS 14+; use a workaround for older versions
    let isLeapMonth = Self.isLeapMonth(date: date, calendar: chineseCalendar)

    let yearText = Self.yearText(for: year)
    let monthText = Self.monthText(for: month, isLeapMonth: isLeapMonth)
    let dayText = Self.dayText(for: day)

    // Check for 除夕 first (special case: last day of lunar year)
    let isChuxi = festivalResolver.isLunarNewYearsEve(date: date)

    let festival: String?
    if isChuxi {
      festival = "除夕"
    } else {
      festival = festivalResolver.festivalName(month: month, day: day, isLeapMonth: isLeapMonth)
    }

    let solarTerm = solarTermResolver.solarTermName(for: date)

    return LunarDateDescriptor(
      year: year,
      month: month,
      day: day,
      isLeapMonth: isLeapMonth,
      yearText: yearText,
      monthText: monthText,
      dayText: dayText,
      festivalName: festival,
      solarTermName: solarTerm
    )
  }

  // MARK: - Text Conversion

  /// Determines if the given date falls in a lunar leap month.
  /// Uses monthSymbols to detect "闰" prefix without requiring macOS 14+ isLeapMonth.
  private static func isLeapMonth(date: Date, calendar: Calendar) -> Bool {
    let monthSymbol = calendar.monthSymbols[calendar.component(.month, from: date) - 1]
    return monthSymbol.hasPrefix("闰")
  }

  private static func yearText(for year: Int) -> String {
    let gan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    let zhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

    let ganIndex = (year - 4) % 10
    let zhiIndex = (year - 4) % 12

    return gan[max(0, min(9, ganIndex))] + zhi[max(0, min(11, zhiIndex))] + "年"
  }

  private static func monthText(for month: Int, isLeapMonth: Bool) -> String {
    let monthNames = [
      "正月", "二月", "三月", "四月", "五月", "六月",
      "七月", "八月", "九月", "十月", "冬月", "腊月",
    ]

    let resolvedMonth = monthNames[max(0, min(monthNames.count - 1, month - 1))]
    return isLeapMonth ? "闰\(resolvedMonth)" : resolvedMonth
  }

  private static func dayText(for day: Int) -> String {
    let dayNames = [
      "初一", "初二", "初三", "初四", "初五",
      "初六", "初七", "初八", "初九", "初十",
      "十一", "十二", "十三", "十四", "十五",
      "十六", "十七", "十八", "十九", "二十",
      "廿一", "廿二", "廿三", "廿四", "廿五",
      "廿六", "廿七", "廿八", "廿九", "三十",
    ]

    return dayNames[max(0, min(dayNames.count - 1, day - 1))]
  }
}
