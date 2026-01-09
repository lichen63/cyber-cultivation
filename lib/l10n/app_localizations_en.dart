// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cyber Cultivation';

  @override
  String get defaultKeyText => 'Key';

  @override
  String get forceForegroundText => 'Force Foreground';

  @override
  String get antiSleepText => 'Anti-Sleep';

  @override
  String get exitGameText => 'Exit Game';

  @override
  String get pomodoroDialogTitle => 'Pomodoro Clock';

  @override
  String get pomodoroDurationLabel => 'Focus (min):';

  @override
  String get pomodoroRelaxLabel => 'Relax (min):';

  @override
  String get pomodoroLoopsLabel => 'Loops:';

  @override
  String get pomodoroExpectedExpLabel => 'Expected Exp: ';

  @override
  String get pomodoroStartButtonText => 'Start';

  @override
  String get cancelButtonText => 'Cancel';

  @override
  String get confirmStopTitle => 'Stop Focus?';

  @override
  String get confirmStopContent => 'Current focus progress will be lost.';

  @override
  String get stopButtonText => 'Stop';

  @override
  String get invalidInputErrorText => 'Invalid';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get closeButtonText => 'Close';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get focusState => 'Focus';

  @override
  String get relaxState => 'Relax';

  @override
  String get alwaysShowActionsText => 'Always Show Actions';
}
