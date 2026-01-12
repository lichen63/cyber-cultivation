import 'daily_stats.dart';
import 'todo_item.dart';
import '../constants.dart';

class GameData {
  final int level;
  final double currentExp;
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final bool isAutoStartEnabled;
  final double? windowWidth;
  final double? windowHeight;
  final String? userId;
  final String? language;
  final AppThemeMode themeMode;
  final Map<String, DailyStats> dailyStats;
  final List<TodoItem> todos;

  GameData({
    required this.level,
    required this.currentExp,
    this.isAlwaysOnTop = true,
    this.isAntiSleepEnabled = false,
    this.isAlwaysShowActionButtons = false,
    this.isAutoStartEnabled = false,
    this.windowWidth,
    this.windowHeight,
    this.userId,
    this.language,
    this.themeMode = AppThemeMode.dark,
    Map<String, DailyStats>? dailyStats,
    List<TodoItem>? todos,
  })  : dailyStats = dailyStats ?? {},
        todos = todos ?? [];

  // Convert a GameData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentExp': currentExp.isInfinite ? 0 : currentExp.toInt(),
      'isAlwaysOnTop': isAlwaysOnTop,
      'isAntiSleepEnabled': isAntiSleepEnabled,
      'isAlwaysShowActionButtons': isAlwaysShowActionButtons,
      'isAutoStartEnabled': isAutoStartEnabled,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'userId': userId,
      'language': language,
      'themeMode': themeMode.name,
      'dailyStats': dailyStats.map((k, v) => MapEntry(k, v.toJson())),
      'todos': todos.map((t) => t.toJson()).toList(),
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
      isAutoStartEnabled: json['isAutoStartEnabled'] as bool? ?? false,
      windowWidth: (json['windowWidth'] as num?)?.toDouble(),
      windowHeight: (json['windowHeight'] as num?)?.toDouble(),
      userId: json['userId'] as String?,
      language: json['language'] as String?,
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      dailyStats:
          (json['dailyStats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DailyStats.fromJson(v)),
          ) ??
          {},
      todos: (json['todos'] as List<dynamic>?)
              ?.map((t) => TodoItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static AppThemeMode _parseThemeMode(String? value) {
    if (value == 'light') return AppThemeMode.light;
    return AppThemeMode.dark;
  }

  GameData copyWith({
    int? level,
    double? currentExp,
    bool? isAlwaysOnTop,
    bool? isAntiSleepEnabled,
    bool? isAlwaysShowActionButtons,
    bool? isAutoStartEnabled,
    double? windowWidth,
    double? windowHeight,
    String? userId,
    String? language,
    AppThemeMode? themeMode,
    Map<String, DailyStats>? dailyStats,
    List<TodoItem>? todos,
  }) {
    return GameData(
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      isAntiSleepEnabled: isAntiSleepEnabled ?? this.isAntiSleepEnabled,
      isAlwaysShowActionButtons:
          isAlwaysShowActionButtons ?? this.isAlwaysShowActionButtons,
      isAutoStartEnabled: isAutoStartEnabled ?? this.isAutoStartEnabled,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      userId: userId ?? this.userId,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      dailyStats: dailyStats ?? this.dailyStats,
      todos: todos ?? this.todos,
    );
  }
}
