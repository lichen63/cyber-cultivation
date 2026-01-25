/// Enum for different menu bar info types
enum MenuBarInfoType {
  trayIcon,
  focus,
  todo,
  levelExp,
  cpu,
  gpu,
  ram,
  disk,
  network,
  keyboard,
  mouse,
  systemTime,
  battery,
}

/// Settings for menu bar display
class MenuBarSettings {
  /// Whether to show the tray icon
  final bool showTrayIcon;

  /// List of enabled menu bar info items
  final Set<MenuBarInfoType> enabledInfoTypes;

  const MenuBarSettings({
    this.showTrayIcon = true,
    Set<MenuBarInfoType>? enabledInfoTypes,
  }) : enabledInfoTypes = enabledInfoTypes ?? const {};

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'showTrayIcon': showTrayIcon,
      'enabledInfoTypes': enabledInfoTypes.map((e) => e.name).toList(),
    };
  }

  /// Create from JSON
  factory MenuBarSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MenuBarSettings();
    }
    return MenuBarSettings(
      showTrayIcon: json['showTrayIcon'] as bool? ?? true,
      enabledInfoTypes: _parseEnabledTypes(json['enabledInfoTypes'] as List?),
    );
  }

  static Set<MenuBarInfoType> _parseEnabledTypes(List? list) {
    if (list == null) return {};
    return list
        .map((e) => _parseInfoType(e as String))
        .whereType<MenuBarInfoType>()
        .toSet();
  }

  static MenuBarInfoType? _parseInfoType(String name) {
    return MenuBarInfoType.values.where((e) => e.name == name).firstOrNull;
  }

  /// Create a copy with updated fields
  MenuBarSettings copyWith({
    bool? showTrayIcon,
    Set<MenuBarInfoType>? enabledInfoTypes,
  }) {
    return MenuBarSettings(
      showTrayIcon: showTrayIcon ?? this.showTrayIcon,
      enabledInfoTypes: enabledInfoTypes ?? this.enabledInfoTypes,
    );
  }

  /// Check if a specific info type is enabled
  bool isEnabled(MenuBarInfoType type) => enabledInfoTypes.contains(type);

  /// Toggle a specific info type
  MenuBarSettings toggleType(MenuBarInfoType type) {
    final newSet = Set<MenuBarInfoType>.from(enabledInfoTypes);
    if (newSet.contains(type)) {
      newSet.remove(type);
    } else {
      newSet.add(type);
    }
    return copyWith(enabledInfoTypes: newSet);
  }
}
