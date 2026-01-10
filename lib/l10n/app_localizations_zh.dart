// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '赛博修仙';

  @override
  String get defaultKeyText => '按键';

  @override
  String get forceForegroundText => '窗口置顶';

  @override
  String get antiSleepText => '防休眠';

  @override
  String get exitGameText => '退出游戏';

  @override
  String get pomodoroDialogTitle => '番茄钟';

  @override
  String get pomodoroDurationLabel => '专注 (分):';

  @override
  String get pomodoroRelaxLabel => '休息 (分):';

  @override
  String get pomodoroLoopsLabel => '循环次数:';

  @override
  String get pomodoroExpectedExpLabel => '预计经验: ';

  @override
  String get pomodoroStartButtonText => '开始';

  @override
  String get cancelButtonText => '取消';

  @override
  String get confirmStopTitle => '停止专注?';

  @override
  String get confirmStopContent => '当前的专注进度将丢失。';

  @override
  String get stopButtonText => '停止';

  @override
  String get invalidInputErrorText => '无效';

  @override
  String get settingsTitle => '设置';

  @override
  String get closeButtonText => '关闭';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '系统默认';

  @override
  String get focusState => '专注';

  @override
  String get relaxState => '休息';

  @override
  String get alwaysShowActionsText => '总是显示操作按钮';

  @override
  String get statsTitle => '统计';

  @override
  String get statsHistoryTrends => '历史趋势';

  @override
  String get statsLast7Days => '最近 7 天';

  @override
  String get statsLast30Days => '最近 30 天';

  @override
  String get statsKeyboard => '按键';

  @override
  String get statsClicks => '点击';

  @override
  String get statsDistance => '距离';

  @override
  String get statsTodaysActivity => '今日活动';

  @override
  String get noDataAvailable => '暂无数据';
}
