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
}
