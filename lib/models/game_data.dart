import 'daily_stats.dart';

class GameData {
  final int level;
  final double currentExp;
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final double? windowWidth;
  final double? windowHeight;
  final String? userId;
  final String? language;
  final Map<String, DailyStats> dailyStats;

  GameData({
    required this.level,
    required this.currentExp,
    this.isAlwaysOnTop = true,
    this.isAntiSleepEnabled = false,
    this.isAlwaysShowActionButtons = false,
    this.windowWidth,
    this.windowHeight,
    this.userId,
    this.language,
    Map<String, DailyStats>? dailyStats,
  }) : dailyStats = dailyStats ?? {};

  // Convert a GameData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentExp': currentExp.isInfinite ? 0 : currentExp.toInt(),
      'isAlwaysOnTop': isAlwaysOnTop,
      'isAntiSleepEnabled': isAntiSleepEnabled,
      'isAlwaysShowActionButtons': isAlwaysShowActionButtons,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'userId': userId,
      'language': language,
      'dailyStats': dailyStats.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  // Convert a Map object into a GameData object
  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      level: json['level'] as int,
      currentExp: (json['currentExp'] as num).toDouble(),
      isAlwaysOnTop: json['isAlwaysOnTop'] as bool? ?? true,
      isAntiSleepEnabled: json['isAntiSleepEnabled'] as bool? ?? false,
      isAlwaysShowActionButtons:
          json['isAlwaysShowActionButtons'] as bool? ?? false,
      windowWidth: (json['windowWidth'] as num?)?.toDouble(),
      windowHeight: (json['windowHeight'] as num?)?.toDouble(),
      userId: json['userId'] as String?,
      language: json['language'] as String?,
      dailyStats:
          (json['dailyStats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DailyStats.fromJson(v)),
          ) ??
          {},
    );
  }

  GameData copyWith({
    int? level,
    double? currentExp,
    bool? isAlwaysOnTop,
    bool? isAntiSleepEnabled,
    bool? isAlwaysShowActionButtons,
    double? windowWidth,
    double? windowHeight,
    String? userId,
    String? language,
    Map<String, DailyStats>? dailyStats,
  }) {
    return GameData(
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      isAntiSleepEnabled: isAntiSleepEnabled ?? this.isAntiSleepEnabled,
      isAlwaysShowActionButtons:
          isAlwaysShowActionButtons ?? this.isAlwaysShowActionButtons,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      userId: userId ?? this.userId,
      language: language ?? this.language,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }
}
