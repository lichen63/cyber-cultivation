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
  String get exploreNpcAlreadyMet => 'You\'ve already met this NPC.';

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
  String get exploreDebugAddEffects => 'Add NPC Effects';

  @override
  String get exploreDebugApplyEffects => 'Apply Selected';

  @override
  String exploreDebugEffectsAdded(int count) {
    return '$count effect(s) added.';
  }

  @override
  String get exploreDebugEffectPositive => 'Positive';

  @override
  String get exploreDebugEffectNegative => 'Negative';

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
  String get npcEffectNameExpGiftSteal => 'EXP Gift/Steal';

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

  @override
  String get npcEffectNameExpGamble => 'EXP Gamble';

  @override
  String npcEffectRemainingMoves(int count) {
    return '$count moves remaining';
  }

  @override
  String get npcEffectNameFcBuff => 'FC Buff';

  @override
  String npcEffectFcBuffPositive(int count) {
    return 'FC Boost: +20% Fighting Capacity for next $count battles!';
  }

  @override
  String npcEffectFcBuffNegative(int count) {
    return 'FC Curse: -20% Fighting Capacity for next $count battles!';
  }

  @override
  String get npcEffectDescFcBuffPositive => '+20% FC in battles';

  @override
  String get npcEffectDescFcBuffNegative => '-20% FC in battles';

  @override
  String get npcEffectNameGuaranteedOutcome => 'Fate Seal';

  @override
  String get npcEffectGuaranteedOutcomePositive =>
      'Victory Seal: Next battle is a guaranteed win!';

  @override
  String get npcEffectGuaranteedOutcomeNegative =>
      'Doom Seal: Next battle is a guaranteed loss!';

  @override
  String get npcEffectDescGuaranteedOutcomePositive =>
      'Next battle: guaranteed win';

  @override
  String get npcEffectDescGuaranteedOutcomeNegative =>
      'Next battle: guaranteed loss';

  @override
  String get npcEffectNameFleeMastery => 'Flee Mastery';

  @override
  String npcEffectFleeMasteryPositive(int count) {
    return 'Escape Artist: Next $count flee attempts always succeed!';
  }

  @override
  String npcEffectFleeMasteryNegative(int count) {
    return 'Trapped: Next $count flee attempts always fail!';
  }

  @override
  String get npcEffectDescFleeMasteryPositive => 'Flee always succeeds';

  @override
  String get npcEffectDescFleeMasteryNegative => 'Flee always fails';

  @override
  String get npcEffectNameFirstStrike => 'First Strike';

  @override
  String get npcEffectFirstStrikePositive =>
      'First Strike: Enemy FC counted at 50% in next battle!';

  @override
  String get npcEffectFirstStrikeNegative =>
      'Ambushed: Your FC counted at 50% in next battle!';

  @override
  String get npcEffectDescFirstStrikePositive => 'Enemy FC at 50%';

  @override
  String get npcEffectDescFirstStrikeNegative => 'Your FC at 50%';

  @override
  String get npcEffectNameGlassCannon => 'Glass Cannon';

  @override
  String get npcEffectGlassCannonPositive =>
      'Glass Cannon: +50% FC for next battle!';

  @override
  String get npcEffectGlassCannonNegative =>
      'Weakened: -50% FC for next battle!';

  @override
  String get npcEffectDescGlassCannonPositive => '+50% FC next battle';

  @override
  String get npcEffectDescGlassCannonNegative => '-50% FC next battle';

  @override
  String get npcEffectNamePathClearing => 'Path Clearing';

  @override
  String npcEffectPathClearingPositive(int count) {
    return 'Path Cleared: $count mountains removed!';
  }

  @override
  String npcEffectPathClearingNegative(int count) {
    return 'Landslide: $count new mountains appeared!';
  }

  @override
  String get npcEffectNameRiverBridge => 'River Bridge';

  @override
  String npcEffectRiverBridgePositive(int count) {
    return 'River Crossed: $count river cells bridged!';
  }

  @override
  String npcEffectRiverBridgeNegative(int count) {
    return 'Flood: $count new river cells appeared!';
  }

  @override
  String get npcEffectNameMonsterCleanse => 'Monster Cleanse';

  @override
  String npcEffectMonsterCleansePositive(int count) {
    return 'Monster Cleanse: $count nearby monsters vanished!';
  }

  @override
  String npcEffectMonsterCleanseNegative(int count) {
    return 'Monster Surge: $count new monsters appeared!';
  }

  @override
  String get npcEffectNameBossShift => 'Boss Shift';

  @override
  String get npcEffectBossShiftPositive =>
      'Boss Banished: Nearest boss removed!';

  @override
  String get npcEffectBossShiftNegative =>
      'Boss Summoned: A new boss appeared!';

  @override
  String get npcEffectNameSafeZone => 'Safe Zone';

  @override
  String get npcEffectSafeZonePositive =>
      'Safe Zone: Area around you cleared of dangers!';

  @override
  String get npcEffectSafeZoneNegative =>
      'Danger Zone: Monsters spawned around you!';

  @override
  String get npcEffectNameTerrainSwap => 'Terrain Swap';

  @override
  String npcEffectTerrainSwapPositive(int count) {
    return 'Terrain Cleared: $count mountains converted to paths!';
  }

  @override
  String npcEffectTerrainSwapNegative(int count) {
    return 'Terrain Blocked: $count paths turned to mountains!';
  }

  @override
  String get npcEffectNameFovModify => 'Vision';

  @override
  String npcEffectFovModifyPositive(int amount) {
    return 'Far Sight: Field of view increased by $amount tiles!';
  }

  @override
  String npcEffectFovModifyNegative(int amount) {
    return 'Blinded: Field of view decreased by $amount tiles!';
  }

  @override
  String npcEffectDescFovModifyPositive(int amount) {
    return '+$amount FOV';
  }

  @override
  String npcEffectDescFovModifyNegative(int amount) {
    return '-$amount FOV';
  }

  @override
  String get npcEffectNameBossRadar => 'Boss Radar';

  @override
  String get npcEffectBossRadarPositive =>
      'Boss Radar: Nearest boss location revealed!';

  @override
  String get npcEffectBossRadarNegative =>
      'Boss Cloaked: Boss cells hidden until stepped on!';

  @override
  String get npcEffectDescBossRadarNegative => 'Bosses appear as blank';

  @override
  String get npcEffectNameNpcRadar => 'NPC Radar';

  @override
  String get npcEffectNpcRadarPositive =>
      'NPC Radar: Nearest NPC location revealed!';

  @override
  String get npcEffectNpcRadarNegative =>
      'NPC Cloaked: NPC cells hidden until stepped on!';

  @override
  String get npcEffectDescNpcRadarNegative => 'NPCs appear as blank';

  @override
  String get npcEffectNameMapReveal => 'Map Reveal';

  @override
  String get npcEffectMapRevealPositive =>
      'Cartographer: 20% of unexplored map revealed!';

  @override
  String npcEffectMapRevealNegative(int count) {
    return 'Fog of War: FOV shrunk to 1 tile for $count moves!';
  }

  @override
  String get npcEffectDescMapRevealNegative => 'FOV limited to 1 tile';

  @override
  String get npcEffectNameMonsterRadar => 'Monster Radar';

  @override
  String get npcEffectMonsterRadarPositive =>
      'Monster Radar: All monsters within 10 tiles revealed!';

  @override
  String get npcEffectMonsterRadarNegative =>
      'Monster Cloak: Monsters within 10 tiles now invisible!';

  @override
  String get npcEffectDescMonsterRadarNegative => 'Nearby monsters invisible';

  @override
  String get npcEffectNameHouseRadar => 'House Radar';

  @override
  String get npcEffectHouseRadarPositive =>
      'House Radar: Nearest house location revealed!';

  @override
  String get npcEffectHouseRadarNegative =>
      'Houses Cloaked: House cells hidden until stepped on!';

  @override
  String get npcEffectDescHouseRadarNegative => 'Houses appear as blank';

  @override
  String get npcEffectNameTeleport => 'Teleport';

  @override
  String get npcEffectTeleportPositive =>
      'Far Teleport: Teleported to a distant location!';

  @override
  String get npcEffectTeleportNegative =>
      'Return: Teleported back to spawn point!';

  @override
  String get npcEffectNameSpeedBoost => 'Speed Boost';

  @override
  String npcEffectSpeedBoostPositive(int count) {
    return 'Speed Boost: Move 2 cells per step for $count moves!';
  }

  @override
  String npcEffectSpeedBoostNegative(int count) {
    return 'Slow: Move only every 2 key presses for $count moves!';
  }

  @override
  String get npcEffectDescSpeedBoostPositive => 'Move 2 cells per step';

  @override
  String get npcEffectDescSpeedBoostNegative => 'Move every 2 presses';

  @override
  String get npcEffectNameTeleportHouse => 'Teleport to House';

  @override
  String get npcEffectTeleportHousePositive =>
      'House Teleport: Teleported to nearest house!';

  @override
  String get npcEffectTeleportHouseNegative =>
      'Boss Teleport: Teleported to nearest boss!';

  @override
  String get npcEffectNamePathfinder => 'Pathfinder';

  @override
  String get npcEffectPathfinderPositive =>
      'Pathfinder: Shortest path to nearest house revealed!';

  @override
  String get npcEffectPathfinderNegative =>
      'Lost: All houses removed from map!';

  @override
  String get npcEffectNameWeakenEnemies => 'Weaken Enemies';

  @override
  String get npcEffectWeakenEnemiesPositive =>
      'Weaken Aura: Monsters in 10-tile radius get -30% FC!';

  @override
  String get npcEffectWeakenEnemiesNegative =>
      'Rage Aura: Monsters in 10-tile radius get +30% FC!';

  @override
  String get npcEffectNameMonsterConversion => 'Monster Conversion';

  @override
  String npcEffectMonsterConversionPositive(int count) {
    return 'Taming: $count nearest monsters became NPCs!';
  }

  @override
  String npcEffectMonsterConversionNegative(int count) {
    return 'Corruption: $count nearest NPCs became monsters!';
  }

  @override
  String get npcEffectNameBossDowngrade => 'Boss Downgrade';

  @override
  String get npcEffectBossDowngradePositive =>
      'Demotion: Nearest boss became regular monster!';

  @override
  String get npcEffectBossDowngradeNegative =>
      'Promotion: Nearest monster became boss!';

  @override
  String get npcEffectNameMonsterFreeze => 'Monster Freeze';

  @override
  String get npcEffectMonsterFreezePositive =>
      'Fear Aura: Next monster will flee on contact!';

  @override
  String get npcEffectMonsterFreezeNegative =>
      'Enrage: Next monster gets +50% FC!';

  @override
  String get npcEffectDescMonsterFreezePositive => 'Next monster flees';

  @override
  String get npcEffectDescMonsterFreezeNegative => 'Next monster +50% FC';

  @override
  String get npcEffectNameClearWave => 'Clear Wave';

  @override
  String get npcEffectClearWavePositive =>
      'Purge: Monsters in 3-tile radius eliminated!';

  @override
  String get npcEffectClearWaveNegative =>
      'Infestation: Monsters spawned in 3-tile radius!';

  @override
  String get npcEffectNameMonsterMagnet => 'Monster Magnet';

  @override
  String get npcEffectMonsterMagnetPositive =>
      'Repel: Monsters in 5-tile radius moved away!';

  @override
  String get npcEffectMonsterMagnetNegative =>
      'Attract: Monsters in 5-tile radius moved closer!';

  @override
  String get npcEffectNameNpcBlessingChain => 'NPC Blessing Chain';

  @override
  String get npcEffectNpcBlessingChainPositive =>
      'Blessing Chain: Next NPC encounter guaranteed positive!';

  @override
  String get npcEffectNpcBlessingChainNegative =>
      'Curse Chain: Next NPC encounter guaranteed negative!';

  @override
  String get npcEffectDescNpcBlessingChainPositive => 'Next NPC is positive';

  @override
  String get npcEffectDescNpcBlessingChainNegative => 'Next NPC is negative';

  @override
  String get npcEffectNameNpcSpawn => 'NPC Spawn';

  @override
  String npcEffectNpcSpawnPositive(int count) {
    return 'NPC Spawn: $count new NPCs appeared on the map!';
  }

  @override
  String npcEffectNpcSpawnNegative(int count) {
    return 'NPC Removal: $count NPCs vanished from the map!';
  }

  @override
  String get npcEffectNameNpcUpgrade => 'NPC Upgrade';

  @override
  String get npcEffectNpcUpgradePositive =>
      'Double Effect: Next NPC effect is doubled!';

  @override
  String get npcEffectNpcUpgradeNegative =>
      'Reverse: Next NPC effect is reversed!';

  @override
  String get npcEffectDescNpcUpgradePositive => 'Next NPC effect 2x';

  @override
  String get npcEffectDescNpcUpgradeNegative => 'Next NPC effect reversed';

  @override
  String get npcEffectNameHouseSpawn => 'House Spawn';

  @override
  String get npcEffectHouseSpawnPositive =>
      'New Shelter: A house appeared nearby!';

  @override
  String get npcEffectHouseSpawnNegative =>
      'House Destroyed: Nearest house removed!';

  @override
  String get npcEffectNameHouseUpgrade => 'House Upgrade';

  @override
  String get npcEffectHouseUpgradePositive =>
      'Enhanced Rest: Next house visit gives 2x benefit!';

  @override
  String get npcEffectHouseUpgradeNegative =>
      'Poor Rest: Next house visit gives 0.5x benefit!';

  @override
  String get npcEffectDescHouseUpgradePositive => 'Next house 2x benefit';

  @override
  String get npcEffectDescHouseUpgradeNegative => 'Next house 0.5x benefit';

  @override
  String get npcEffectNameRiskReward => 'Risk/Reward';

  @override
  String npcEffectRiskRewardPositive(int count) {
    return 'Risk Taker: +50% EXP but -20% FC for $count battles!';
  }

  @override
  String npcEffectRiskRewardNegative(int count) {
    return 'Safe Play: +20% FC but -50% EXP for $count battles!';
  }

  @override
  String get npcEffectDescRiskRewardPositive => '+50% EXP, -20% FC';

  @override
  String get npcEffectDescRiskRewardNegative => '+20% FC, -50% EXP';

  @override
  String get npcEffectNameSacrifice => 'Sacrifice';

  @override
  String npcEffectSacrificePositive(int count) {
    return 'Sacrifice: Lose 5% EXP now, +30% FC for $count battles!';
  }

  @override
  String npcEffectSacrificeNegative(int count) {
    return 'Dark Deal: Gain 5% EXP now, -30% FC for $count battles!';
  }

  @override
  String get npcEffectDescSacrificePositive => '+30% FC';

  @override
  String get npcEffectDescSacrificeNegative => '-30% FC';

  @override
  String get npcEffectNameAllIn => 'All-In';

  @override
  String get npcEffectAllInPositive =>
      'Purification: Monsters in 5 tiles cleared + bonus EXP!';

  @override
  String get npcEffectAllInNegative =>
      'Catastrophe: Extra boss spawned + EXP lost!';

  @override
  String get npcEffectNameMirror => 'Mirror';

  @override
  String get npcEffectMirrorPositive =>
      'Mirror: Your FC doubled for next fight!';

  @override
  String get npcEffectMirrorNegative =>
      'Mirror: Next enemy copies your FC (50/50 chance)!';

  @override
  String get npcEffectDescMirrorPositive => '2x FC next fight';

  @override
  String get npcEffectDescMirrorNegative => 'Enemy has your FC';

  @override
  String get npcEffectNameCounterStack => 'Counter Stack';

  @override
  String npcEffectCounterStackPositive(int count) {
    return 'Momentum: Each step gives +1% FC up to $count steps!';
  }

  @override
  String npcEffectCounterStackNegative(int count) {
    return 'Fatigue: Each step gives -1% FC for $count steps!';
  }

  @override
  String npcEffectDescCounterStackPositive(int percent, int count) {
    return '+$percent% FC ($count stacks)';
  }

  @override
  String npcEffectDescCounterStackNegative(int percent, int count) {
    return '-$percent% FC ($count steps left)';
  }

  @override
  String get npcEffectNameMapScramble => 'Map Scramble';

  @override
  String get npcEffectMapScramblePositive =>
      'Monster Shuffle: All monsters moved to new positions!';

  @override
  String get npcEffectMapScrambleNegative =>
      'NPC Shuffle: All NPCs moved to new positions!';

  @override
  String get npcEffectNameCellCounter => 'Cell Counter';

  @override
  String npcEffectCellCounterPositive(int count) {
    return 'Monster Count: $count monsters remaining on map!';
  }

  @override
  String npcEffectCellCounterNegative(int count) {
    return 'Confused Count: Roughly $count monsters on map (maybe)!';
  }

  @override
  String get npcEffectNameProgressBoost => 'Progress Boost';

  @override
  String npcEffectProgressBoostPositive(int count) {
    return 'Explorer: $count random cells marked as explored!';
  }

  @override
  String npcEffectProgressBoostNegative(int count) {
    return 'Amnesia: $count explored cells forgotten!';
  }
}
