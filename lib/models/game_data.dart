import 'daily_stats.dart';
import 'menu_bar_settings.dart';
import 'todo_item.dart';
import '../constants.dart';

class GameData {
  final int level;
  final double currentExp;
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final bool isAutoStartEnabled;
  final bool isShowSystemStats;
  final bool isShowKeyboardTrack;
  final bool isShowMouseTrack;
  final bool isCompactModeEnabled;
  final int systemStatsRefreshSeconds;
  final double? windowWidth;
  final double? windowHeight;
  final double? windowX;
  final double? windowY;
  final String? userId;
  final String? language;
  final AppThemeMode themeMode;
  final Map<String, DailyStats> dailyStats;
  final List<TodoItem> todos;
  final MenuBarSettings menuBarSettings;
  final int defaultPomodoroDuration;
  final int defaultPomodoroRelax;
  final int defaultPomodoroLoops;

  GameData({
    required this.level,
    required this.currentExp,
    this.isAlwaysOnTop = true,
    this.isAntiSleepEnabled = false,
    this.isAlwaysShowActionButtons = false,
    this.isAutoStartEnabled = false,
    this.isShowSystemStats = true,
    this.isShowKeyboardTrack = true,
    this.isShowMouseTrack = true,
    this.isCompactModeEnabled = false,
    this.systemStatsRefreshSeconds =
        AppConstants.defaultSystemStatsRefreshSeconds,
    this.windowWidth,
    this.windowHeight,
    this.windowX,
    this.windowY,
    this.userId,
    this.language,
    this.themeMode = AppThemeMode.dark,
    Map<String, DailyStats>? dailyStats,
    List<TodoItem>? todos,
    MenuBarSettings? menuBarSettings,
    this.defaultPomodoroDuration = AppConstants.defaultPomodoroDuration,
    this.defaultPomodoroRelax = AppConstants.defaultRelaxDuration,
    this.defaultPomodoroLoops = AppConstants.defaultPomodoroLoops,
  }) : dailyStats = dailyStats ?? {},
       todos = todos ?? [],
       menuBarSettings = menuBarSettings ?? const MenuBarSettings();

  // Convert a GameData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentExp': currentExp.isInfinite ? 0 : currentExp.toInt(),
      'isAlwaysOnTop': isAlwaysOnTop,
      'isAntiSleepEnabled': isAntiSleepEnabled,
      'isAlwaysShowActionButtons': isAlwaysShowActionButtons,
      'isAutoStartEnabled': isAutoStartEnabled,
      'isShowSystemStats': isShowSystemStats,
      'isShowKeyboardTrack': isShowKeyboardTrack,
      'isShowMouseTrack': isShowMouseTrack,
      'isCompactModeEnabled': isCompactModeEnabled,
      'systemStatsRefreshSeconds': systemStatsRefreshSeconds,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'windowX': windowX,
      'windowY': windowY,
      'userId': userId,
      'language': language,
      'themeMode': themeMode.name,
      'dailyStats': dailyStats.map((k, v) => MapEntry(k, v.toJson())),
      'todos': todos.map((t) => t.toJson()).toList(),
      'menuBarSettings': menuBarSettings.toJson(),
      'defaultPomodoroDuration': defaultPomodoroDuration,
      'defaultPomodoroRelax': defaultPomodoroRelax,
      'defaultPomodoroLoops': defaultPomodoroLoops,
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
      isShowSystemStats: json['isShowSystemStats'] as bool? ?? true,
      isShowKeyboardTrack: json['isShowKeyboardTrack'] as bool? ?? true,
      isShowMouseTrack: json['isShowMouseTrack'] as bool? ?? true,
      isCompactModeEnabled: json['isCompactModeEnabled'] as bool? ?? false,
      systemStatsRefreshSeconds:
          json['systemStatsRefreshSeconds'] as int? ??
          AppConstants.defaultSystemStatsRefreshSeconds,
      windowWidth: (json['windowWidth'] as num?)?.toDouble(),
      windowHeight: (json['windowHeight'] as num?)?.toDouble(),
      windowX: (json['windowX'] as num?)?.toDouble(),
      windowY: (json['windowY'] as num?)?.toDouble(),
      userId: json['userId'] as String?,
      language: json['language'] as String?,
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      dailyStats:
          (json['dailyStats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DailyStats.fromJson(v)),
          ) ??
          {},
      todos:
          (json['todos'] as List<dynamic>?)
              ?.map((t) => TodoItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      menuBarSettings: MenuBarSettings.fromJson(
        json['menuBarSettings'] as Map<String, dynamic>?,
      ),
      defaultPomodoroDuration:
          json['defaultPomodoroDuration'] as int? ??
          AppConstants.defaultPomodoroDuration,
      defaultPomodoroRelax:
          json['defaultPomodoroRelax'] as int? ??
          AppConstants.defaultRelaxDuration,
      defaultPomodoroLoops:
          json['defaultPomodoroLoops'] as int? ??
          AppConstants.defaultPomodoroLoops,
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
    bool? isShowSystemStats,
    bool? isShowKeyboardTrack,
    bool? isShowMouseTrack,
    bool? isCompactModeEnabled,
    int? systemStatsRefreshSeconds,
    double? windowWidth,
    double? windowHeight,
    double? windowX,
    double? windowY,
    String? userId,
    String? language,
    AppThemeMode? themeMode,
    Map<String, DailyStats>? dailyStats,
    List<TodoItem>? todos,
    MenuBarSettings? menuBarSettings,
    int? defaultPomodoroDuration,
    int? defaultPomodoroRelax,
    int? defaultPomodoroLoops,
  }) {
    return GameData(
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      isAntiSleepEnabled: isAntiSleepEnabled ?? this.isAntiSleepEnabled,
      isAlwaysShowActionButtons:
          isAlwaysShowActionButtons ?? this.isAlwaysShowActionButtons,
      isAutoStartEnabled: isAutoStartEnabled ?? this.isAutoStartEnabled,
      isShowSystemStats: isShowSystemStats ?? this.isShowSystemStats,
      isShowKeyboardTrack: isShowKeyboardTrack ?? this.isShowKeyboardTrack,
      isShowMouseTrack: isShowMouseTrack ?? this.isShowMouseTrack,
      isCompactModeEnabled: isCompactModeEnabled ?? this.isCompactModeEnabled,
      systemStatsRefreshSeconds:
          systemStatsRefreshSeconds ?? this.systemStatsRefreshSeconds,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowX: windowX ?? this.windowX,
      windowY: windowY ?? this.windowY,
      userId: userId ?? this.userId,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      dailyStats: dailyStats ?? this.dailyStats,
      todos: todos ?? this.todos,
      menuBarSettings: menuBarSettings ?? this.menuBarSettings,
      defaultPomodoroDuration:
          defaultPomodoroDuration ?? this.defaultPomodoroDuration,
      defaultPomodoroRelax: defaultPomodoroRelax ?? this.defaultPomodoroRelax,
      defaultPomodoroLoops: defaultPomodoroLoops ?? this.defaultPomodoroLoops,
    );
  }
}
