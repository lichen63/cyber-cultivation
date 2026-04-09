import Foundation

/// Represents a single holiday or adjustment workday entry.
struct HolidayEntry {
  let date: String
  let name: String
  let kind: HolidayKind

  enum HolidayKind: String, Decodable {
    case statutoryHoliday
    case workingAdjustmentDay
  }
}

/// Loads and queries Chinese statutory holidays and adjustment workdays.
/// Priority: online API (timor.tech) → disk cache → bundled JSON fallback.
class HolidayService {
  static let shared = HolidayService()

  /// In-memory cache: year -> (dateString -> HolidayEntry)
  private var memoryCache: [Int: [String: HolidayEntry]] = [:]
  /// Track years currently being fetched to avoid duplicate requests
  private var fetchingYears: Set<Int> = []
  private let dateFormatter: DateFormatter
  /// Cache expiry: 30 days
  private let cacheMaxAge: TimeInterval = 30 * 24 * 3600
  /// Callback when holiday data is loaded asynchronously
  var onDataUpdated: (() -> Void)?

  private init() {
    dateFormatter = DateFormatter()
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
    dateFormatter.dateFormat = "yyyy-MM-dd"
  }

  /// Returns the holiday entry for a given date, or nil.
  func holidayInfo(for date: Date) -> HolidayEntry? {
    let gregorian = Calendar(identifier: .gregorian)
    let year = gregorian.component(.year, from: date)
    let dateString = dateFormatter.string(from: date)

    let yearData = holidays(forYear: year)
    return yearData[dateString]
  }

  /// Returns all holidays for a year (synchronous: memory → disk cache → bundled).
  /// Also kicks off an async online fetch if disk cache is stale/missing.
  func holidays(forYear year: Int) -> [String: HolidayEntry] {
    if let cached = memoryCache[year] {
      return cached
    }

    // Try disk cache first
    if let diskData = loadFromDiskCache(forYear: year) {
      memoryCache[year] = diskData
      return diskData
    }

    // Try bundled JSON
    let bundled = loadFromBundle(forYear: year)
    if !bundled.isEmpty {
      memoryCache[year] = bundled
    }

    // Kick off async fetch from online API
    fetchFromAPIIfNeeded(year: year)

    return bundled
  }

  /// Prefetch holiday data for the given years (call when calendar is shown).
  func prefetch(years: [Int]) {
    for year in years {
      fetchFromAPIIfNeeded(year: year)
    }
  }

  // MARK: - Online API (timor.tech)

  private func fetchFromAPIIfNeeded(year: Int) {
    guard !fetchingYears.contains(year) else { return }

    // Skip if disk cache is fresh
    if isDiskCacheFresh(forYear: year) { return }

    fetchingYears.insert(year)

    let urlString = "https://timor.tech/api/holiday/year/\(year)/"
    guard let url = URL(string: urlString) else {
      fetchingYears.remove(year)
      return
    }

    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      defer { self?.fetchingYears.remove(year) }

      guard let self = self,
        let data = data,
        error == nil,
        let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        return
      }

      guard let parsed = self.parseTimorResponse(data: data, year: year) else {
        return
      }

      // Save to disk cache
      self.saveToDiskCache(entries: parsed, forYear: year)

      // Update memory cache and notify
      DispatchQueue.main.async {
        self.memoryCache[year] = parsed
        self.onDataUpdated?()
      }
    }
    task.resume()
  }

  /// Parse the timor.tech API response into our HolidayEntry format.
  private func parseTimorResponse(data: Data, year: Int) -> [String: HolidayEntry]? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let code = json["code"] as? Int, code == 0,
      let holidays = json["holiday"] as? [String: Any]
    else {
      return nil
    }

    var result: [String: HolidayEntry] = [:]

    for (_, value) in holidays {
      guard let info = value as? [String: Any],
        let dateStr = info["date"] as? String,
        let name = info["name"] as? String,
        let isHoliday = info["holiday"] as? Bool
      else {
        continue
      }

      let kind: HolidayEntry.HolidayKind = isHoliday ? .statutoryHoliday : .workingAdjustmentDay
      // Clean up name: "元旦后补班" → "元旦"
      let cleanName: String
      if !isHoliday {
        cleanName = name
          .replacingOccurrences(of: "前补班", with: "调休上班")
          .replacingOccurrences(of: "后补班", with: "调休上班")
      } else {
        cleanName = name
      }

      result[dateStr] = HolidayEntry(date: dateStr, name: cleanName, kind: kind)
    }

    return result.isEmpty ? nil : result
  }

  // MARK: - Disk Cache

  private var cacheDirectory: URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dir = appSupport.appendingPathComponent("CyberCultivation/holiday-cache", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private func cacheFileURL(forYear year: Int) -> URL {
    cacheDirectory.appendingPathComponent("holidays-\(year).json")
  }

  private func isDiskCacheFresh(forYear year: Int) -> Bool {
    let fileURL = cacheFileURL(forYear: year)
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
      let modDate = attrs[.modificationDate] as? Date
    else {
      return false
    }
    return Date().timeIntervalSince(modDate) < cacheMaxAge
  }

  private func loadFromDiskCache(forYear year: Int) -> [String: HolidayEntry]? {
    let fileURL = cacheFileURL(forYear: year)
    guard FileManager.default.fileExists(atPath: fileURL.path),
      let data = try? Data(contentsOf: fileURL),
      let records = try? JSONDecoder().decode([CachedHolidayRecord].self, from: data)
    else {
      return nil
    }

    var dict: [String: HolidayEntry] = [:]
    for record in records {
      let kind: HolidayEntry.HolidayKind =
        record.kind == "workingAdjustmentDay" ? .workingAdjustmentDay : .statutoryHoliday
      dict[record.date] = HolidayEntry(date: record.date, name: record.name, kind: kind)
    }
    return dict.isEmpty ? nil : dict
  }

  private func saveToDiskCache(entries: [String: HolidayEntry], forYear year: Int) {
    let records = entries.values.map { entry in
      CachedHolidayRecord(date: entry.date, name: entry.name, kind: entry.kind.rawValue)
    }.sorted { $0.date < $1.date }

    guard let data = try? JSONEncoder().encode(records) else { return }
    let fileURL = cacheFileURL(forYear: year)
    try? data.write(to: fileURL, options: .atomic)
  }

  // MARK: - Bundled JSON Fallback

  private func loadFromBundle(forYear year: Int) -> [String: HolidayEntry] {
    let resourceName = "mainland-cn-\(year)"

    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
      return [:]
    }

    do {
      let data = try Data(contentsOf: url)
      let entries = try JSONDecoder().decode([BundledHolidayRecord].self, from: data)
      var dict: [String: HolidayEntry] = [:]
      for entry in entries {
        let kind: HolidayEntry.HolidayKind =
          entry.kind == "workingAdjustmentDay" ? .workingAdjustmentDay : .statutoryHoliday
        dict[entry.date] = HolidayEntry(date: entry.date, name: entry.name, kind: kind)
      }
      return dict
    } catch {
      NSLog("HolidayService: Failed to load \(resourceName).json: \(error)")
      return [:]
    }
  }
}

// MARK: - Codable Records

private struct CachedHolidayRecord: Codable {
  let date: String
  let name: String
  let kind: String
}

private struct BundledHolidayRecord: Decodable {
  let date: String
  let name: String
  let kind: String
}
