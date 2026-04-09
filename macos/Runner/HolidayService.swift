import Foundation

/// Represents a single holiday or adjustment workday entry.
struct HolidayEntry: Decodable {
  let date: String
  let name: String
  let kind: HolidayKind

  enum HolidayKind: String, Decodable {
    case statutoryHoliday
    case workingAdjustmentDay
  }
}

/// Loads and queries Chinese statutory holidays and adjustment workdays from bundled JSON.
class HolidayService {
  static let shared = HolidayService()

  /// Cache: year -> (dateString -> HolidayEntry)
  private var cache: [Int: [String: HolidayEntry]] = [:]
  private let dateFormatter: DateFormatter

  private init() {
    dateFormatter = DateFormatter()
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
    dateFormatter.dateFormat = "yyyy-MM-dd"
  }

  /// Returns the holiday entry for a given date, or nil if not a holiday/adjustment day.
  func holidayInfo(for date: Date) -> HolidayEntry? {
    let gregorian = Calendar(identifier: .gregorian)
    let year = gregorian.component(.year, from: date)
    let dateString = dateFormatter.string(from: date)

    let yearData = holidays(forYear: year)
    return yearData[dateString]
  }

  /// Returns all holidays for a given year, keyed by date string.
  func holidays(forYear year: Int) -> [String: HolidayEntry] {
    if let cached = cache[year] {
      return cached
    }

    let loaded = loadHolidays(forYear: year)
    cache[year] = loaded
    return loaded
  }

  private func loadHolidays(forYear year: Int) -> [String: HolidayEntry] {
    let resourceName = "mainland-cn-\(year)"

    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
      return [:]
    }

    do {
      let data = try Data(contentsOf: url)
      let entries = try JSONDecoder().decode([HolidayEntry].self, from: data)
      var dict: [String: HolidayEntry] = [:]
      for entry in entries {
        dict[entry.date] = entry
      }
      return dict
    } catch {
      NSLog("HolidayService: Failed to load \(resourceName).json: \(error)")
      return [:]
    }
  }
}
