import Foundation

/// Resolves traditional Chinese festivals based on lunar month and day.
struct TraditionalFestivalResolver {
  private let chineseCalendar: Calendar

  init() {
    var cal = Calendar(identifier: .chinese)
    cal.locale = Locale(identifier: "zh_Hans_CN")
    chineseCalendar = cal
  }

  /// Returns the festival name for the given lunar month and day, or nil.
  func festivalName(month: Int, day: Int, isLeapMonth: Bool) -> String? {
    guard !isLeapMonth else { return nil }

    switch (month, day) {
    case (1, 1):
      return "春节"
    case (1, 15):
      return "元宵节"
    case (5, 5):
      return "端午节"
    case (7, 7):
      return "七夕"
    case (7, 15):
      return "中元节"
    case (8, 15):
      return "中秋节"
    case (9, 9):
      return "重阳节"
    case (12, 8):
      return "腊八节"
    default:
      return nil
    }
  }

  /// Check if a given Gregorian date is 除夕 (Lunar New Year's Eve).
  /// 除夕 is the last day of lunar month 12 — either 三十 or 廿九.
  func isLunarNewYearsEve(date: Date) -> Bool {
    let nextDay = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date)!
    let nextDayComponents = chineseCalendar.dateComponents([.month, .day], from: nextDay)
    // If the next day is lunar month 1, day 1, then today is 除夕
    return nextDayComponents.month == 1 && nextDayComponents.day == 1
  }
}
