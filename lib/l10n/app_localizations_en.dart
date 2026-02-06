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
  String get hideWindowText => 'Hide Window';

  @override
  String get compactModeText => 'Compact Mode';

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
  String get pomodoroSaveAsDefaultButtonText => 'Save as Default';

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
  String get idleState => 'Idle';

  @override
  String get focusPopupStatus => 'Status';

  @override
  String get focusPopupTimeRemaining => 'Time Remaining';

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
  String get showSystemStatsText => 'Show System Stats';

  @override
  String get showKeyboardTrackText => 'Show Keyboard Track';

  @override
  String get showMouseTrackText => 'Show Mouse Track';

  @override
  String get systemStatsRefreshText => 'Stats Refresh Interval';

  @override
  String systemStatsRefreshSeconds(int seconds) {
    return '${seconds}s';
  }

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
  String get snakeGameDescription => 'Classic snake game. Eat food to grow!';

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
  String get flappyBirdDescription => 'Tap to fly through the pipes!';

  @override
  String get flappyBirdTapToFlap => 'Tap or press SPACE to flap';

  @override
  String get sudokuTitle => 'Sudoku';

  @override
  String get sudokuDescription => 'Classic number puzzle. Fill the grid!';

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

  @override
  String get resetLevelExpText => 'Reset Level & EXP';

  @override
  String get resetLevelExpConfirmTitle => 'Reset Progress?';

  @override
  String get resetLevelExpConfirmContent =>
      'Your level and experience will be reset to the beginning. This action cannot be undone.';

  @override
  String get resetButtonText => 'Reset';

  @override
  String get menuBarSettingsTitle => 'Menu Bar Info';

  @override
  String get menuBarSettingsDescription =>
      'Configure what info to show in the menu bar';

  @override
  String get menuBarShowTrayIcon => 'Show Tray Icon';

  @override
  String get menuBarInfoFocus => 'Focus Timer';

  @override
  String get menuBarInfoTodo => 'Todo';

  @override
  String get menuBarInfoLevelExp => 'Level & EXP';

  @override
  String get menuBarInfoCpu => 'CPU';

  @override
  String get menuBarInfoGpu => 'GPU';

  @override
  String get menuBarInfoRam => 'RAM';

  @override
  String get menuBarInfoDisk => 'Disk';

  @override
  String get menuBarInfoNetwork => 'Network';

  @override
  String get menuBarInfoBattery => 'Battery';

  @override
  String get menuBarInfoKeyboard => 'Keyboard';

  @override
  String get menuBarInfoMouse => 'Mouse';

  @override
  String get menuBarInfoSystemTime => 'Time';

  @override
  String get menuBarSectionSystem => 'System Stats';

  @override
  String get menuBarSectionTracking => 'Input Tracking';

  @override
  String get menuBarSectionApp => 'App Info';

  @override
  String get menuBarFocusText => 'Focus';

  @override
  String get menuBarKeyboardText => 'Key';

  @override
  String get menuBarMouseText => 'Mouse';

  @override
  String get menuBarLevelText => 'Lv.';

  @override
  String get openSaveFolderText => 'Save Data Location';

  @override
  String get menuBarShowWindow => 'Show Window';

  @override
  String get menuBarHideWindow => 'Hide Window';

  @override
  String get menuBarExit => 'Exit';

  @override
  String get cpuPopupHeaderProcess => 'Process';

  @override
  String get cpuPopupHeaderPid => 'PID';

  @override
  String get cpuPopupHeaderUsage => 'Usage';

  @override
  String get diskPopupHeaderRead => 'Read';

  @override
  String get diskPopupHeaderWrite => 'Write';

  @override
  String get networkPopupHeaderDownload => '↓Down';

  @override
  String get networkPopupHeaderUpload => '↑Up';

  @override
  String get networkInfoInterface => 'Interface';

  @override
  String get networkInfoNetworkName => 'Network';

  @override
  String get networkInfoLocalIp => 'Local IP';

  @override
  String get networkInfoPublicIp => 'Public IP';

  @override
  String get networkInfoMacAddress => 'MAC';

  @override
  String get networkInfoGateway => 'Gateway';

  @override
  String get networkInfoProcesses => 'Top Processes';

  @override
  String get debugMenu => 'Debug';

  @override
  String get debugSetLevelExp => 'Set Level & EXP';

  @override
  String get debugSetLevelExpTitle => 'Set Level & EXP';

  @override
  String get debugLevelLabel => 'Level';

  @override
  String get debugExpLabel => 'Current EXP';

  @override
  String get debugMaxExpLabel => 'Max EXP to level up';

  @override
  String get debugApplyButton => 'Apply';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreControlsHint => 'WASD to move • Scroll to zoom';

  @override
  String get exploreExitConfirmTitle => 'Leave Exploration?';

  @override
  String get exploreExitConfirmContent =>
      'Your exploration progress will be lost.';

  @override
  String get exploreExitButton => 'Leave';

  @override
  String get exploreSaveAndLeaveButton => 'Save & Leave';

  @override
  String get exploreLegendMountain => 'Mountain';

  @override
  String get exploreLegendRiver => 'River';

  @override
  String get exploreLegendHouse => 'House';

  @override
  String get exploreLegendMonster => 'Monster';

  @override
  String get exploreLegendBoss => 'Boss';

  @override
  String get exploreLegendNpc => 'NPC';

  @override
  String get exploreLegendPlayer => 'Player';

  @override
  String get exploreLocatePlayer => 'Locate Player';

  @override
  String get battleEncounterTitle => 'Battle!';

  @override
  String get battleEncounterMonster => 'A monster blocks your path!';

  @override
  String get battleEncounterBoss => 'A powerful boss appears!';

  @override
  String get battleYourPower => 'Your Power';

  @override
  String get battleEnemyPower => 'Enemy Power';

  @override
  String get battleFightButton => 'Fight!';

  @override
  String get battleFleeButton => 'Flee';

  @override
  String get battleFleeSuccess => 'You escaped safely!';

  @override
  String get battleFleeFailed => 'Failed to escape! The enemy attacks!';

  @override
  String get battleResultVictory => 'Victory!';

  @override
  String get battleResultDefeat => 'Defeat!';

  @override
  String battleExpGained(String exp) {
    return '+$exp EXP';
  }

  @override
  String battleExpLost(String exp) {
    return '-$exp EXP';
  }

  @override
  String get battleOkButton => 'OK';

  @override
  String get exploreApLabel => 'AP';

  @override
  String get exploreApExhaustedTitle => 'Action Points Exhausted';

  @override
  String get exploreApExhaustedContent =>
      'You have no action points left. Leave to start a new exploration next time.';

  @override
  String exploreHouseRestoreAp(int ap) {
    return 'Rested at the house. +$ap AP restored.';
  }

  @override
  String get exploreHouseAlreadyUsed => 'This house has already been used.';

  @override
  String get exploreNotEnoughAp => 'Not enough action points.';

  @override
  String get exploreDebugTitle => 'Debug Tools';

  @override
  String get exploreDebugToggleFog => 'Reveal Map';

  @override
  String get exploreDebugFogOn => 'Fog ON';

  @override
  String get exploreDebugFogOff => 'Fog OFF';

  @override
  String get exploreDebugModifyAp => 'Set AP';

  @override
  String get exploreDebugApHint => 'Enter AP value';

  @override
  String get exploreDebugTeleport => 'Teleport';

  @override
  String get exploreDebugTeleportX => 'X';

  @override
  String get exploreDebugTeleportY => 'Y';

  @override
  String get exploreDebugTeleportGo => 'Go';

  @override
  String get exploreDebugTeleportInvalid =>
      'Invalid position or non-walkable cell.';

  @override
  String get exploreDebugBattleMode => 'Battle Mode';

  @override
  String get exploreDebugBattleNormal => 'Normal';

  @override
  String get exploreDebugBattleAutoWin => 'Auto Win';

  @override
  String get exploreDebugBattleAutoLose => 'Auto Lose';

  @override
  String get exploreDebugResetHouses => 'Reset Houses';

  @override
  String get exploreDebugHousesReset => 'All houses reset.';

  @override
  String get exploreDebugRegenerateMap => 'Regenerate Map';

  @override
  String get exploreDebugMapRegenerated => 'Map regenerated.';

  @override
  String get npcEncounterTitle => 'NPC Encounter';

  @override
  String get npcEffectPositive => 'A traveler shares their blessing with you!';

  @override
  String get npcEffectNegative => 'A traveler places a curse upon you!';

  @override
  String npcEffectExpGiftPositive(String amount) {
    return 'EXP Gift: +$amount EXP';
  }

  @override
  String npcEffectExpStealNegative(String amount) {
    return 'EXP Stolen: -$amount EXP';
  }

  @override
  String npcEffectExpMultiplierPositive(int count) {
    return 'EXP Boost: Next $count battles give 2x EXP!';
  }

  @override
  String npcEffectExpMultiplierNegative(int count) {
    return 'EXP Curse: Next $count battles give 0.5x EXP!';
  }

  @override
  String get npcEffectExpInsurancePositive =>
      'EXP Insurance: Next loss will have no EXP penalty!';

  @override
  String get npcEffectExpInsuranceNegative =>
      'EXP Curse: Next win will give no EXP reward!';

  @override
  String npcEffectExpFloorPositive(int count) {
    return 'EXP Shield: EXP can\'t drop below current value for $count battles!';
  }

  @override
  String npcEffectExpFloorNegative(int count) {
    return 'EXP Ceiling: EXP can\'t gain above current value for $count battles!';
  }

  @override
  String get npcEffectExpGamblePositive => 'Lucky Gamble: EXP doubled!';

  @override
  String get npcEffectExpGambleNegative => 'Unlucky Gamble: EXP halved!';

  @override
  String get npcEffectsButtonTooltip => 'Active Effects';

  @override
  String get npcEffectsDialogTitle => 'Active Effects';

  @override
  String get npcEffectsEmpty => 'No active effects.';

  @override
  String npcEffectRemainingBattles(int count) {
    return '$count battles remaining';
  }

  @override
  String get npcEffectNameExpMultiplier => 'EXP Multiplier';

  @override
  String get npcEffectNameExpInsurance => 'EXP Insurance';

  @override
  String get npcEffectNameExpFloor => 'EXP Floor';

  @override
  String get npcEffectDescMultiplierPositive => '2x EXP from battles';

  @override
  String get npcEffectDescMultiplierNegative => '0.5x EXP from battles';

  @override
  String get npcEffectDescInsurancePositive => 'No EXP penalty on next loss';

  @override
  String get npcEffectDescInsuranceNegative => 'No EXP reward on next win';

  @override
  String npcEffectDescFloorPositive(String value) {
    return 'EXP can\'t drop below $value';
  }

  @override
  String npcEffectDescFloorNegative(String value) {
    return 'EXP can\'t gain above $value';
  }
}
