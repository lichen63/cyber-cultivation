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

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsHistoryTrends => 'History Trends';

  @override
  String get statsLast7Days => 'Last 7 Days';

  @override
  String get statsLast30Days => 'Last 30 Days';

  @override
  String get statsKeyboard => 'Keyboard';

  @override
  String get statsClicks => 'Clicks';

  @override
  String get statsDistance => 'Distance';

  @override
  String get statsTodaysActivity => 'Today\'s Activity';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get statsClearData => 'Clear Stats';

  @override
  String get statsClearConfirmTitle => 'Clear All Stats?';

  @override
  String get statsClearConfirmContent =>
      'All saved activity data will be permanently deleted. This action cannot be undone.';

  @override
  String get themeMode => 'Theme';

  @override
  String get darkMode => 'Dark';

  @override
  String get lightMode => 'Light';

  @override
  String get autoStartText => 'Auto Start at Login';

  @override
  String get accessibilityDialogTitle => 'Accessibility Permission Required';

  @override
  String get accessibilityDialogContent =>
      'This app needs accessibility permission to monitor keyboard and mouse activity for the cultivation experience.';

  @override
  String get accessibilityDialogInstructions =>
      'Please enable accessibility for this app in System Settings → Privacy & Security → Accessibility.';

  @override
  String get accessibilityDialogOpenSettings => 'Open Settings';

  @override
  String get accessibilityDialogLater => 'Later';

  @override
  String get todoTitle => 'Todo';

  @override
  String get todoStatusTodo => 'Todo';

  @override
  String get todoStatusDoing => 'Doing';

  @override
  String get todoStatusDone => 'Done';

  @override
  String get todoAddNew => 'Add Todo';

  @override
  String get todoNewPlaceholder => 'Enter new todo...';

  @override
  String get todoEmpty => 'No todos yet';

  @override
  String get todoDeleteConfirmTitle => 'Delete Todo?';

  @override
  String get todoDeleteConfirmContent =>
      'This todo will be permanently removed.';

  @override
  String get deleteButtonText => 'Delete';

  @override
  String get gamesTitle => 'Games';

  @override
  String get snakeGameTitle => 'Snake';

  @override
  String get snakeGameDescription =>
      'Classic snake game. Eat food to grow and earn EXP!';

  @override
  String get gameScore => 'Score';

  @override
  String get gameOver => 'Game Over';

  @override
  String gameExpGained(int exp) {
    return 'EXP Gained: $exp';
  }

  @override
  String get gamePlayAgain => 'Play Again';

  @override
  String get gamePressToStart => 'Press SPACE or tap to start';

  @override
  String get gameUseArrowKeys => 'Use arrow keys or swipe to move';

  @override
  String get flappyBirdTitle => 'Flappy Bird';

  @override
  String get flappyBirdDescription =>
      'Tap to fly through the pipes and earn EXP!';

  @override
  String get flappyBirdTapToFlap => 'Tap or press SPACE to flap';

  @override
  String get sudokuTitle => 'Sudoku';

  @override
  String get sudokuDescription =>
      'Classic number puzzle. Fill the grid and earn EXP!';

  @override
  String get sudokuSelectNumber => 'Select a number below or use keys 1-9';

  @override
  String get sudokuNewGame => 'New Game';

  @override
  String get sudokuEasy => 'Easy';

  @override
  String get sudokuMedium => 'Medium';

  @override
  String get sudokuHard => 'Hard';

  @override
  String sudokuMistakes(int count, int max) {
    return 'Mistakes: $count/$max';
  }

  @override
  String get sudokuCompleted => 'Puzzle Completed!';

  @override
  String get sudokuTooManyMistakes => 'Too Many Mistakes!';

  @override
  String sudokuTime(String time) {
    return 'Time: $time';
  }
}
