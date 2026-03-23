import '../constants.dart';

/// Represents a modifier + key combination (e.g., Command+Tab)
class KeyCombo {
  final String modifier;
  final String key;

  const KeyCombo({required this.modifier, required this.key});

  Map<String, dynamic> toJson() => {'modifier': modifier, 'key': key};

  factory KeyCombo.fromJson(Map<String, dynamic> json) {
    return KeyCombo(
      modifier: json['modifier'] as String? ?? 'command',
      key: json['key'] as String? ?? 'tab',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyCombo && modifier == other.modifier && key == other.key;

  @override
  int get hashCode => Object.hash(modifier, key);

  @override
  String toString() =>
      '${KeyShieldConstants.modifierSymbols[modifier] ?? modifier}+$key';
}

/// Per-app Key Shield rule with optional overrides
class AppKeyShieldRule {
  final String bundleId;
  final String appName;
  final bool autoActivate;

  /// null = use global defaults
  final List<String>? blockedModifiers;

  /// null = use global defaults
  final List<KeyCombo>? allowedCombos;

  const AppKeyShieldRule({
    required this.bundleId,
    required this.appName,
    this.autoActivate = true,
    this.blockedModifiers,
    this.allowedCombos,
  });

  Map<String, dynamic> toJson() => {
    'bundleId': bundleId,
    'appName': appName,
    'autoActivate': autoActivate,
    'blockedModifiers': blockedModifiers,
    'allowedCombos': allowedCombos?.map((c) => c.toJson()).toList(),
  };

  factory AppKeyShieldRule.fromJson(Map<String, dynamic> json) {
    return AppKeyShieldRule(
      bundleId: json['bundleId'] as String? ?? '',
      appName: json['appName'] as String? ?? '',
      autoActivate: json['autoActivate'] as bool? ?? true,
      blockedModifiers: (json['blockedModifiers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      allowedCombos: (json['allowedCombos'] as List<dynamic>?)
          ?.map((e) => KeyCombo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Whether this rule uses custom settings or global defaults
  bool get hasCustomRules => blockedModifiers != null || allowedCombos != null;

  AppKeyShieldRule copyWith({
    String? bundleId,
    String? appName,
    bool? autoActivate,
    List<String>? blockedModifiers,
    List<KeyCombo>? allowedCombos,
    bool clearBlockedModifiers = false,
    bool clearAllowedCombos = false,
  }) {
    return AppKeyShieldRule(
      bundleId: bundleId ?? this.bundleId,
      appName: appName ?? this.appName,
      autoActivate: autoActivate ?? this.autoActivate,
      blockedModifiers: clearBlockedModifiers
          ? null
          : (blockedModifiers ?? this.blockedModifiers),
      allowedCombos: clearAllowedCombos
          ? null
          : (allowedCombos ?? this.allowedCombos),
    );
  }
}

/// Global Key Shield configuration
class KeyShieldConfig {
  final bool isEnabled;
  final List<String> globalBlockedModifiers;
  final List<KeyCombo> globalAllowedCombos;
  final Map<String, AppKeyShieldRule> appRules;
  final String feedbackMode;

  const KeyShieldConfig({
    this.isEnabled = false,
    this.globalBlockedModifiers = const [],
    this.globalAllowedCombos = const [],
    this.appRules = const {},
    this.feedbackMode = KeyShieldConstants.feedbackNone,
  });

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'globalBlockedModifiers': globalBlockedModifiers,
    'globalAllowedCombos': globalAllowedCombos.map((c) => c.toJson()).toList(),
    'appRules': appRules.map((k, v) => MapEntry(k, v.toJson())),
    'feedbackMode': feedbackMode,
  };

  factory KeyShieldConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KeyShieldConfig();
    return KeyShieldConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      globalBlockedModifiers:
          (json['globalBlockedModifiers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      globalAllowedCombos:
          (json['globalAllowedCombos'] as List<dynamic>?)
              ?.map((e) => KeyCombo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      appRules:
          (json['appRules'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              AppKeyShieldRule.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
      feedbackMode:
          json['feedbackMode'] as String? ?? KeyShieldConstants.feedbackNone,
    );
  }

  /// Get effective blocked modifiers for a given app (per-app override or global)
  List<String> effectiveBlockedModifiers(String bundleId) {
    final rule = appRules[bundleId];
    return rule?.blockedModifiers ?? globalBlockedModifiers;
  }

  /// Get effective allowed combos for a given app (per-app override or global)
  List<KeyCombo> effectiveAllowedCombos(String bundleId) {
    final rule = appRules[bundleId];
    return rule?.allowedCombos ?? globalAllowedCombos;
  }

  KeyShieldConfig copyWith({
    bool? isEnabled,
    List<String>? globalBlockedModifiers,
    List<KeyCombo>? globalAllowedCombos,
    Map<String, AppKeyShieldRule>? appRules,
    String? feedbackMode,
  }) {
    return KeyShieldConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      globalBlockedModifiers:
          globalBlockedModifiers ?? this.globalBlockedModifiers,
      globalAllowedCombos: globalAllowedCombos ?? this.globalAllowedCombos,
      appRules: appRules ?? this.appRules,
      feedbackMode: feedbackMode ?? this.feedbackMode,
    );
  }
}
