import Cocoa

/// Manages Key Shield state: blocks modifier key combos when configured apps are in the foreground.
class KeyShieldHandler {
  static let shared = KeyShieldHandler()
  
  private(set) var isEnabled: Bool = false
  private var globalBlockedModifiers: Set<String> = []  // "command", "option", "control"
  private var globalAllowedCombos: Set<AllowedCombo> = []
  private var appRules: [String: AppRule] = [:]  // bundleId -> rule
  private var feedbackMode: String = "none"
  
  private(set) var frontmostBundleId: String?
  private(set) var frontmostAppName: String?
  
  private var workspaceObserver: NSObjectProtocol?
  
  /// A combo that should always pass through even when blocking
  struct AllowedCombo: Hashable {
    let modifier: String
    let key: String
  }
  
  /// Per-app rule
  struct AppRule {
    let bundleId: String
    let appName: String
    let autoActivate: Bool
    let blockedModifiers: Set<String>?  // nil = use global
    let allowedCombos: Set<AllowedCombo>?  // nil = use global
  }
  
  /// Modifier string to CGEventFlags mapping
  private static let modifierMap: [String: CGEventFlags] = [
    "command": .maskCommand,
    "option": .maskAlternate,
    "control": .maskControl,
  ]
  
  /// Keycode to string mapping for allowed combo matching
  private static let keyCodeToString: [Int64: String] = [
    // Letters
    0: "a", 11: "b", 8: "c", 2: "d", 14: "e", 3: "f", 5: "g", 4: "h",
    34: "i", 38: "j", 40: "k", 37: "l", 46: "m", 45: "n", 31: "o", 35: "p",
    12: "q", 15: "r", 1: "s", 17: "t", 32: "u", 9: "v", 13: "w", 7: "x",
    16: "y", 6: "z",
    // Special keys
    48: "tab", 49: "space", 36: "enter", 51: "backspace", 53: "esc",
    123: "left", 124: "right", 125: "down", 126: "up",
    // Numbers
    18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
    22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
    // Function keys
    122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6",
    98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
    // Punctuation
    27: "-", 24: "=", 33: "[", 30: "]", 42: "\\",
    41: ";", 39: "'", 43: ",", 47: ".", 44: "/", 50: "`",
    117: "delete", 115: "home", 119: "end", 116: "pageup", 121: "pagedown",
  ]
  
  private init() {
    startObservingFrontmostApp()
  }
  
  deinit {
    if let observer = workspaceObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }
  
  // MARK: - Configuration
  
  /// Update configuration from Flutter
  func updateConfig(_ config: [String: Any]) {
    isEnabled = config["isEnabled"] as? Bool ?? false
    
    if let modifiers = config["globalBlockedModifiers"] as? [String] {
      globalBlockedModifiers = Set(modifiers)
    }
    
    if let combos = config["globalAllowedCombos"] as? [[String: Any]] {
      globalAllowedCombos = Set(combos.compactMap { dict -> AllowedCombo? in
        guard let modifier = dict["modifier"] as? String,
              let key = dict["key"] as? String else { return nil }
        return AllowedCombo(modifier: modifier, key: key)
      })
    }
    
    if let rules = config["appRules"] as? [String: [String: Any]] {
      appRules = [:]
      for (bundleId, ruleDict) in rules {
        let blockedMods: Set<String>? = (ruleDict["blockedModifiers"] as? [String]).map { Set($0) }
        let allowedCmbs: Set<AllowedCombo>? = (ruleDict["allowedCombos"] as? [[String: Any]])?.reduce(into: Set<AllowedCombo>()) { result, dict in
          if let modifier = dict["modifier"] as? String,
             let key = dict["key"] as? String {
            result.insert(AllowedCombo(modifier: modifier, key: key))
          }
        }
        
        appRules[bundleId] = AppRule(
          bundleId: bundleId,
          appName: ruleDict["appName"] as? String ?? "",
          autoActivate: ruleDict["autoActivate"] as? Bool ?? true,
          blockedModifiers: blockedMods,
          allowedCombos: allowedCmbs
        )
      }
    }
    
    feedbackMode = config["feedbackMode"] as? String ?? "none"
  }
  
  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
  }
  
  // MARK: - Event Blocking
  
  /// Determine whether a CGEvent should be blocked
  /// Returns true if the event should be blocked (caller returns nil from tap callback)
  func shouldBlockEvent(_ event: CGEvent, type: CGEventType) -> Bool {
    guard isEnabled else { return false }
    
    // Skip blocking for our own app
    if frontmostBundleId == Bundle.main.bundleIdentifier { return false }
    
    let effectiveBlocked: Set<String>
    let effectiveAllowed: Set<AllowedCombo>
    
    if appRules.isEmpty {
      // No protected apps configured — block globally for all apps
      effectiveBlocked = globalBlockedModifiers
      effectiveAllowed = globalAllowedCombos
    } else if let bundleId = frontmostBundleId,
              let rule = appRules[bundleId],
              rule.autoActivate {
      // Frontmost app is in the protected list
      effectiveBlocked = rule.blockedModifiers ?? globalBlockedModifiers
      effectiveAllowed = rule.allowedCombos ?? globalAllowedCombos
    } else {
      // Frontmost app is not in the protected list
      return false
    }
    
    // Check if any blocked modifier is active
    let flags = event.flags
    var hasBlockedModifier = false
    var activeModifier: String?
    
    for modifier in effectiveBlocked {
      if let flag = KeyShieldHandler.modifierMap[modifier], flags.contains(flag) {
        hasBlockedModifier = true
        activeModifier = modifier
        break
      }
    }
    
    guard hasBlockedModifier, let modifier = activeModifier else { return false }
    
    if type == .keyDown {
      // Check if this combo is in the allowed list
      let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
      if let keyString = KeyShieldHandler.keyCodeToString[keyCode] {
        let combo = AllowedCombo(modifier: modifier, key: keyString)
        if effectiveAllowed.contains(combo) {
          return false  // Allow this combo through
        }
      }
      
      // Block the event
      if feedbackMode == "visual" {
        triggerVisualFeedback()
      }
      return true
    } else if type == .flagsChanged {
      // Don't block pure modifier key presses/releases — only block combos
      return false
    }
    
    return false
  }
  
  /// Whether Key Shield is currently actively blocking for the frontmost app
  var isActivelyBlocking: Bool {
    guard isEnabled else { return false }
    // Skip our own app
    if frontmostBundleId == Bundle.main.bundleIdentifier { return false }
    if appRules.isEmpty {
      // No protected apps — blocking globally
      return true
    }
    guard let bundleId = frontmostBundleId,
          let rule = appRules[bundleId] else { return false }
    return rule.autoActivate
  }
  
  // MARK: - Foreground App Detection
  
  private func startObservingFrontmostApp() {
    // Initialize with current frontmost app
    updateFrontmostApp()
    
    workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.updateFrontmostApp()
    }
  }
  
  private func updateFrontmostApp() {
    let app = NSWorkspace.shared.frontmostApplication
    frontmostBundleId = app?.bundleIdentifier
    frontmostAppName = app?.localizedName
  }
  
  // MARK: - Running Apps
  
  /// Get list of all running GUI applications
  func getRunningApps() -> [[String: String]] {
    let apps = NSWorkspace.shared.runningApplications
    var result: [[String: String]] = []
    
    for app in apps {
      // Only include regular GUI apps (not background agents, etc.)
      guard app.activationPolicy == .regular,
            let bundleId = app.bundleIdentifier,
            let name = app.localizedName else { continue }
      
      // Skip our own app
      if bundleId == Bundle.main.bundleIdentifier { continue }
      
      result.append([
        "bundleId": bundleId,
        "name": name,
      ])
    }
    
    // Sort by name
    result.sort { ($0["name"] ?? "") < ($1["name"] ?? "") }
    return result
  }
  
  /// Get current status as dictionary for Flutter
  func getStatus() -> [String: Any] {
    return [
      "isEnabled": isEnabled,
      "isActivelyBlocking": isActivelyBlocking,
      "frontmostBundleId": frontmostBundleId as Any,
      "frontmostAppName": frontmostAppName as Any,
    ]
  }
  
  // MARK: - Visual Feedback
  
  private func triggerVisualFeedback() {
    // Flash the screen edges briefly to indicate a blocked key
    DispatchQueue.main.async {
      guard let screen = NSScreen.main else { return }
      let frame = screen.frame
      
      let flashWindow = NSWindow(
        contentRect: frame,
        styleMask: .borderless,
        backing: .buffered,
        defer: false
      )
      flashWindow.backgroundColor = NSColor.red.withAlphaComponent(0.15)
      flashWindow.isOpaque = false
      flashWindow.level = .screenSaver
      flashWindow.ignoresMouseEvents = true
      flashWindow.orderFront(nil)
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        flashWindow.orderOut(nil)
      }
    }
  }
}
