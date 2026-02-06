import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Cyber Cultivation'**
  String get appTitle;

  /// Label for the default key
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get defaultKeyText;

  /// Option to force the window to the foreground
  ///
  /// In en, this message translates to:
  /// **'Force Foreground'**
  String get forceForegroundText;

  /// Option to prevent the system from sleeping
  ///
  /// In en, this message translates to:
  /// **'Anti-Sleep'**
  String get antiSleepText;

  /// Option to hide the game window
  ///
  /// In en, this message translates to:
  /// **'Hide Window'**
  String get hideWindowText;

  /// Option to enable compact mode where the window shrinks to a small circle
  ///
  /// In en, this message translates to:
  /// **'Compact Mode'**
  String get compactModeText;

  /// Option to exit the game
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGameText;

  /// Title of the Pomodoro dialog
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Clock'**
  String get pomodoroDialogTitle;

  /// Label for the focus duration input
  ///
  /// In en, this message translates to:
  /// **'Focus (min):'**
  String get pomodoroDurationLabel;

  /// Label for the relax duration input
  ///
  /// In en, this message translates to:
  /// **'Relax (min):'**
  String get pomodoroRelaxLabel;

  /// Label for the loops input
  ///
  /// In en, this message translates to:
  /// **'Loops:'**
  String get pomodoroLoopsLabel;

  /// Label for expected experience points
  ///
  /// In en, this message translates to:
  /// **'Expected Exp: '**
  String get pomodoroExpectedExpLabel;

  /// Text for the start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pomodoroStartButtonText;

  /// Text for saving current pomodoro values as default
  ///
  /// In en, this message translates to:
  /// **'Save as Default'**
  String get pomodoroSaveAsDefaultButtonText;

  /// Text for the cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonText;

  /// Title for the stop confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Stop Focus?'**
  String get confirmStopTitle;

  /// Content for the stop confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Current focus progress will be lost.'**
  String get confirmStopContent;

  /// Text for the stop button
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButtonText;

  /// Error text for invalid input
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalidInputErrorText;

  /// Title for the settings dialog
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Text for the close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButtonText;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for system language option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// Label for focus state
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusState;

  /// Label for relax state
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get relaxState;

  /// Label for idle state
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idleState;

  /// Label for focus popup status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get focusPopupStatus;

  /// Label for focus popup time remaining
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get focusPopupTimeRemaining;

  /// Option to always show action buttons
  ///
  /// In en, this message translates to:
  /// **'Always Show Actions'**
  String get alwaysShowActionsText;

  /// Title for the stats button
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// Section title for history trends
  ///
  /// In en, this message translates to:
  /// **'History Trends'**
  String get statsHistoryTrends;

  /// Button label for last 7 days stats
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get statsLast7Days;

  /// Button label for last 30 days stats
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get statsLast30Days;

  /// Label for keyboard stats
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get statsKeyboard;

  /// Label for click stats
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get statsClicks;

  /// Label for mouse distance stats
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statsDistance;

  /// Section title for today's activity
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get statsTodaysActivity;

  /// Text shown when there is no data
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Tooltip for clear stats button
  ///
  /// In en, this message translates to:
  /// **'Clear Stats'**
  String get statsClearData;

  /// Title for clear stats confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear All Stats?'**
  String get statsClearConfirmTitle;

  /// Content for clear stats confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'All saved activity data will be permanently deleted. This action cannot be undone.'**
  String get statsClearConfirmContent;

  /// Label for theme mode selection
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// Label for dark theme mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// Label for light theme mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// Option to auto start the app at login
  ///
  /// In en, this message translates to:
  /// **'Auto Start at Login'**
  String get autoStartText;

  /// Option to show system stats panel
  ///
  /// In en, this message translates to:
  /// **'Show System Stats'**
  String get showSystemStatsText;

  /// Option to show keyboard track area
  ///
  /// In en, this message translates to:
  /// **'Show Keyboard Track'**
  String get showKeyboardTrackText;

  /// Option to show mouse track area
  ///
  /// In en, this message translates to:
  /// **'Show Mouse Track'**
  String get showMouseTrackText;

  /// Label for system stats refresh interval setting
  ///
  /// In en, this message translates to:
  /// **'Stats Refresh Interval'**
  String get systemStatsRefreshText;

  /// Seconds format for refresh interval
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String systemStatsRefreshSeconds(int seconds);

  /// Title for the accessibility permission dialog
  ///
  /// In en, this message translates to:
  /// **'Accessibility Permission Required'**
  String get accessibilityDialogTitle;

  /// Content explaining why accessibility is needed
  ///
  /// In en, this message translates to:
  /// **'This app needs accessibility permission to monitor keyboard and mouse activity for the cultivation experience.'**
  String get accessibilityDialogContent;

  /// Instructions for granting accessibility permission
  ///
  /// In en, this message translates to:
  /// **'Please enable accessibility for this app in System Settings → Privacy & Security → Accessibility.'**
  String get accessibilityDialogInstructions;

  /// Button to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get accessibilityDialogOpenSettings;

  /// Button to dismiss and do later
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get accessibilityDialogLater;

  /// Title for todo button and dialog
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get todoTitle;

  /// Status label for todo items
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get todoStatusTodo;

  /// Status label for in-progress items
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get todoStatusDoing;

  /// Status label for completed items
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todoStatusDone;

  /// Button to add new todo
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get todoAddNew;

  /// Placeholder for new todo input
  ///
  /// In en, this message translates to:
  /// **'Enter new todo...'**
  String get todoNewPlaceholder;

  /// Message when todo list is empty
  ///
  /// In en, this message translates to:
  /// **'No todos yet'**
  String get todoEmpty;

  /// Title for delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Todo?'**
  String get todoDeleteConfirmTitle;

  /// Content for delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This todo will be permanently removed.'**
  String get todoDeleteConfirmContent;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButtonText;

  /// Title for games list
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesTitle;

  /// Title for snake game
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get snakeGameTitle;

  /// Description for snake game
  ///
  /// In en, this message translates to:
  /// **'Classic snake game. Eat food to grow!'**
  String get snakeGameDescription;

  /// Score label in games
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameScore;

  /// Game over text
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// EXP gained text
  ///
  /// In en, this message translates to:
  /// **'EXP Gained: {exp}'**
  String gameExpGained(int exp);

  /// Play again button text
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get gamePlayAgain;

  /// Press to start instruction
  ///
  /// In en, this message translates to:
  /// **'Press SPACE or tap to start'**
  String get gamePressToStart;

  /// Control instructions
  ///
  /// In en, this message translates to:
  /// **'Use arrow keys or swipe to move'**
  String get gameUseArrowKeys;

  /// Title for flappy bird game
  ///
  /// In en, this message translates to:
  /// **'Flappy Bird'**
  String get flappyBirdTitle;

  /// Description for flappy bird game
  ///
  /// In en, this message translates to:
  /// **'Tap to fly through the pipes!'**
  String get flappyBirdDescription;

  /// Control instructions for flappy bird
  ///
  /// In en, this message translates to:
  /// **'Tap or press SPACE to flap'**
  String get flappyBirdTapToFlap;

  /// Title for sudoku game
  ///
  /// In en, this message translates to:
  /// **'Sudoku'**
  String get sudokuTitle;

  /// Description for sudoku game
  ///
  /// In en, this message translates to:
  /// **'Classic number puzzle. Fill the grid!'**
  String get sudokuDescription;

  /// Control instructions for sudoku
  ///
  /// In en, this message translates to:
  /// **'Select a number below or use keys 1-9'**
  String get sudokuSelectNumber;

  /// New game button text
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get sudokuNewGame;

  /// Easy difficulty
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get sudokuEasy;

  /// Medium difficulty
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sudokuMedium;

  /// Hard difficulty
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get sudokuHard;

  /// Mistakes counter
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {count}/{max}'**
  String sudokuMistakes(int count, int max);

  /// Puzzle completed text
  ///
  /// In en, this message translates to:
  /// **'Puzzle Completed!'**
  String get sudokuCompleted;

  /// Too many mistakes text
  ///
  /// In en, this message translates to:
  /// **'Too Many Mistakes!'**
  String get sudokuTooManyMistakes;

  /// Time display
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String sudokuTime(String time);

  /// Button text to reset level and experience
  ///
  /// In en, this message translates to:
  /// **'Reset Level & EXP'**
  String get resetLevelExpText;

  /// Title for reset level confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Progress?'**
  String get resetLevelExpConfirmTitle;

  /// Content for reset level confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Your level and experience will be reset to the beginning. This action cannot be undone.'**
  String get resetLevelExpConfirmContent;

  /// Text for reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButtonText;

  /// Title for menu bar settings
  ///
  /// In en, this message translates to:
  /// **'Menu Bar Info'**
  String get menuBarSettingsTitle;

  /// Description for menu bar settings
  ///
  /// In en, this message translates to:
  /// **'Configure what info to show in the menu bar'**
  String get menuBarSettingsDescription;

  /// Option to show/hide tray icon
  ///
  /// In en, this message translates to:
  /// **'Show Tray Icon'**
  String get menuBarShowTrayIcon;

  /// Focus timer info option
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get menuBarInfoFocus;

  /// Todo info option
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get menuBarInfoTodo;

  /// Level and EXP info option
  ///
  /// In en, this message translates to:
  /// **'Level & EXP'**
  String get menuBarInfoLevelExp;

  /// CPU info option
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get menuBarInfoCpu;

  /// GPU info option
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get menuBarInfoGpu;

  /// RAM info option
  ///
  /// In en, this message translates to:
  /// **'RAM'**
  String get menuBarInfoRam;

  /// Disk info option
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get menuBarInfoDisk;

  /// Network speed info option
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get menuBarInfoNetwork;

  /// Battery info option
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get menuBarInfoBattery;

  /// Keyboard tracking info option
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get menuBarInfoKeyboard;

  /// Mouse tracking info option
  ///
  /// In en, this message translates to:
  /// **'Mouse'**
  String get menuBarInfoMouse;

  /// Time info option
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get menuBarInfoSystemTime;

  /// Section title for system stats
  ///
  /// In en, this message translates to:
  /// **'System Stats'**
  String get menuBarSectionSystem;

  /// Section title for input tracking
  ///
  /// In en, this message translates to:
  /// **'Input Tracking'**
  String get menuBarSectionTracking;

  /// Section title for app info
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get menuBarSectionApp;

  /// Focus label in menu bar
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get menuBarFocusText;

  /// Keyboard label in menu bar
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get menuBarKeyboardText;

  /// Mouse label in menu bar
  ///
  /// In en, this message translates to:
  /// **'Mouse'**
  String get menuBarMouseText;

  /// Level label in menu bar
  ///
  /// In en, this message translates to:
  /// **'Lv.'**
  String get menuBarLevelText;

  /// Button to open the folder containing save data
  ///
  /// In en, this message translates to:
  /// **'Save Data Location'**
  String get openSaveFolderText;

  /// Menu bar popup item to show the main window
  ///
  /// In en, this message translates to:
  /// **'Show Window'**
  String get menuBarShowWindow;

  /// Menu bar popup item to hide the main window
  ///
  /// In en, this message translates to:
  /// **'Hide Window'**
  String get menuBarHideWindow;

  /// Menu bar popup item to exit the application
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get menuBarExit;

  /// Column header for process name in CPU popup
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get cpuPopupHeaderProcess;

  /// Column header for process ID in popup
  ///
  /// In en, this message translates to:
  /// **'PID'**
  String get cpuPopupHeaderPid;

  /// Column header for CPU usage in CPU popup
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get cpuPopupHeaderUsage;

  /// Column header for disk read in popup
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get diskPopupHeaderRead;

  /// Column header for disk write in popup
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get diskPopupHeaderWrite;

  /// Column header for network download in popup
  ///
  /// In en, this message translates to:
  /// **'↓Down'**
  String get networkPopupHeaderDownload;

  /// Column header for network upload in popup
  ///
  /// In en, this message translates to:
  /// **'↑Up'**
  String get networkPopupHeaderUpload;

  /// Label for network interface type
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get networkInfoInterface;

  /// Label for network name (SSID or interface)
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkInfoNetworkName;

  /// Label for local IP address
  ///
  /// In en, this message translates to:
  /// **'Local IP'**
  String get networkInfoLocalIp;

  /// Label for public IP address
  ///
  /// In en, this message translates to:
  /// **'Public IP'**
  String get networkInfoPublicIp;

  /// Label for MAC address
  ///
  /// In en, this message translates to:
  /// **'MAC'**
  String get networkInfoMacAddress;

  /// Label for gateway IP address
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get networkInfoGateway;

  /// Header for top network processes section
  ///
  /// In en, this message translates to:
  /// **'Top Processes'**
  String get networkInfoProcesses;

  /// Debug menu item label
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debugMenu;

  /// Debug menu item to set level and exp
  ///
  /// In en, this message translates to:
  /// **'Set Level & EXP'**
  String get debugSetLevelExp;

  /// Title for debug set level/exp dialog
  ///
  /// In en, this message translates to:
  /// **'Set Level & EXP'**
  String get debugSetLevelExpTitle;

  /// Label for level input
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get debugLevelLabel;

  /// Label for current exp input
  ///
  /// In en, this message translates to:
  /// **'Current EXP'**
  String get debugExpLabel;

  /// Label showing max exp needed for next level
  ///
  /// In en, this message translates to:
  /// **'Max EXP to level up'**
  String get debugMaxExpLabel;

  /// Button to apply debug changes
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get debugApplyButton;

  /// Title for the explore window
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// Control hints for explore window
  ///
  /// In en, this message translates to:
  /// **'WASD to move • Scroll to zoom'**
  String get exploreControlsHint;

  /// Title for explore exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Leave Exploration?'**
  String get exploreExitConfirmTitle;

  /// Content for explore exit confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Your exploration progress will be lost.'**
  String get exploreExitConfirmContent;

  /// Button to confirm leaving explore window without saving
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get exploreExitButton;

  /// Button to save progress and leave explore window
  ///
  /// In en, this message translates to:
  /// **'Save & Leave'**
  String get exploreSaveAndLeaveButton;

  /// Legend label for mountain cells
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get exploreLegendMountain;

  /// Legend label for river cells
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get exploreLegendRiver;

  /// Legend label for house cells
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get exploreLegendHouse;

  /// Legend label for monster cells
  ///
  /// In en, this message translates to:
  /// **'Monster'**
  String get exploreLegendMonster;

  /// Legend label for boss cells
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get exploreLegendBoss;

  /// Legend label for NPC cells
  ///
  /// In en, this message translates to:
  /// **'NPC'**
  String get exploreLegendNpc;

  /// Legend label for player cell
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get exploreLegendPlayer;

  /// Tooltip for button to center view on player
  ///
  /// In en, this message translates to:
  /// **'Locate Player'**
  String get exploreLocatePlayer;

  /// Title for battle encounter dialog
  ///
  /// In en, this message translates to:
  /// **'Battle!'**
  String get battleEncounterTitle;

  /// Subtitle when encountering a monster
  ///
  /// In en, this message translates to:
  /// **'A monster blocks your path!'**
  String get battleEncounterMonster;

  /// Subtitle when encountering a boss
  ///
  /// In en, this message translates to:
  /// **'A powerful boss appears!'**
  String get battleEncounterBoss;

  /// Label for player's fighting capacity
  ///
  /// In en, this message translates to:
  /// **'Your Power'**
  String get battleYourPower;

  /// Label for enemy's fighting capacity
  ///
  /// In en, this message translates to:
  /// **'Enemy Power'**
  String get battleEnemyPower;

  /// Button to start the battle
  ///
  /// In en, this message translates to:
  /// **'Fight!'**
  String get battleFightButton;

  /// Button to attempt fleeing
  ///
  /// In en, this message translates to:
  /// **'Flee'**
  String get battleFleeButton;

  /// Message when flee succeeds
  ///
  /// In en, this message translates to:
  /// **'You escaped safely!'**
  String get battleFleeSuccess;

  /// Message when flee fails
  ///
  /// In en, this message translates to:
  /// **'Failed to escape! The enemy attacks!'**
  String get battleFleeFailed;

  /// Title when player wins the battle
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get battleResultVictory;

  /// Title when player loses the battle
  ///
  /// In en, this message translates to:
  /// **'Defeat!'**
  String get battleResultDefeat;

  /// EXP gained message
  ///
  /// In en, this message translates to:
  /// **'+{exp} EXP'**
  String battleExpGained(String exp);

  /// EXP lost message
  ///
  /// In en, this message translates to:
  /// **'-{exp} EXP'**
  String battleExpLost(String exp);

  /// OK button in battle dialogs
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get battleOkButton;

  /// Label for action points display
  ///
  /// In en, this message translates to:
  /// **'AP'**
  String get exploreApLabel;

  /// Title for AP exhausted dialog
  ///
  /// In en, this message translates to:
  /// **'Action Points Exhausted'**
  String get exploreApExhaustedTitle;

  /// Content for AP exhausted dialog
  ///
  /// In en, this message translates to:
  /// **'You have no action points left. Leave to start a new exploration next time.'**
  String get exploreApExhaustedContent;

  /// Message when player restores AP at a house
  ///
  /// In en, this message translates to:
  /// **'Rested at the house. +{ap} AP restored.'**
  String exploreHouseRestoreAp(int ap);

  /// Message when house has already been used this session
  ///
  /// In en, this message translates to:
  /// **'This house has already been used.'**
  String get exploreHouseAlreadyUsed;

  /// Message when player lacks AP for an action
  ///
  /// In en, this message translates to:
  /// **'Not enough action points.'**
  String get exploreNotEnoughAp;

  /// Title for explore debug dialog
  ///
  /// In en, this message translates to:
  /// **'Debug Tools'**
  String get exploreDebugTitle;

  /// Toggle to reveal or hide fog of war
  ///
  /// In en, this message translates to:
  /// **'Reveal Map'**
  String get exploreDebugToggleFog;

  /// Status when fog is enabled
  ///
  /// In en, this message translates to:
  /// **'Fog ON'**
  String get exploreDebugFogOn;

  /// Status when fog is disabled (map revealed)
  ///
  /// In en, this message translates to:
  /// **'Fog OFF'**
  String get exploreDebugFogOff;

  /// Label for modify action points
  ///
  /// In en, this message translates to:
  /// **'Set AP'**
  String get exploreDebugModifyAp;

  /// Hint for AP input field
  ///
  /// In en, this message translates to:
  /// **'Enter AP value'**
  String get exploreDebugApHint;

  /// Label for teleport feature
  ///
  /// In en, this message translates to:
  /// **'Teleport'**
  String get exploreDebugTeleport;

  /// Label for X coordinate input
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get exploreDebugTeleportX;

  /// Label for Y coordinate input
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get exploreDebugTeleportY;

  /// Button to execute teleport
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get exploreDebugTeleportGo;

  /// Error when teleport target is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid position or non-walkable cell.'**
  String get exploreDebugTeleportInvalid;

  /// Label for battle mode toggle
  ///
  /// In en, this message translates to:
  /// **'Battle Mode'**
  String get exploreDebugBattleMode;

  /// Normal battle mode
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get exploreDebugBattleNormal;

  /// Auto win battle mode
  ///
  /// In en, this message translates to:
  /// **'Auto Win'**
  String get exploreDebugBattleAutoWin;

  /// Auto lose battle mode
  ///
  /// In en, this message translates to:
  /// **'Auto Lose'**
  String get exploreDebugBattleAutoLose;

  /// Button to reset all used houses
  ///
  /// In en, this message translates to:
  /// **'Reset Houses'**
  String get exploreDebugResetHouses;

  /// Message when houses have been reset
  ///
  /// In en, this message translates to:
  /// **'All houses reset.'**
  String get exploreDebugHousesReset;

  /// Button to regenerate the map
  ///
  /// In en, this message translates to:
  /// **'Regenerate Map'**
  String get exploreDebugRegenerateMap;

  /// Message when map has been regenerated
  ///
  /// In en, this message translates to:
  /// **'Map regenerated.'**
  String get exploreDebugMapRegenerated;

  /// Title for NPC encounter dialog
  ///
  /// In en, this message translates to:
  /// **'NPC Encounter'**
  String get npcEncounterTitle;

  /// Message when NPC gives positive effect
  ///
  /// In en, this message translates to:
  /// **'A traveler shares their blessing with you!'**
  String get npcEffectPositive;

  /// Message when NPC gives negative effect
  ///
  /// In en, this message translates to:
  /// **'A traveler places a curse upon you!'**
  String get npcEffectNegative;

  /// Positive EXP gift effect
  ///
  /// In en, this message translates to:
  /// **'EXP Gift: +{amount} EXP'**
  String npcEffectExpGiftPositive(String amount);

  /// Negative EXP steal effect
  ///
  /// In en, this message translates to:
  /// **'EXP Stolen: -{amount} EXP'**
  String npcEffectExpStealNegative(String amount);

  /// Positive EXP multiplier effect
  ///
  /// In en, this message translates to:
  /// **'EXP Boost: Next {count} battles give 2x EXP!'**
  String npcEffectExpMultiplierPositive(int count);

  /// Negative EXP multiplier effect
  ///
  /// In en, this message translates to:
  /// **'EXP Curse: Next {count} battles give 0.5x EXP!'**
  String npcEffectExpMultiplierNegative(int count);

  /// Positive EXP insurance effect
  ///
  /// In en, this message translates to:
  /// **'EXP Insurance: Next loss will have no EXP penalty!'**
  String get npcEffectExpInsurancePositive;

  /// Negative EXP insurance effect
  ///
  /// In en, this message translates to:
  /// **'EXP Curse: Next win will give no EXP reward!'**
  String get npcEffectExpInsuranceNegative;

  /// Positive EXP floor effect
  ///
  /// In en, this message translates to:
  /// **'EXP Shield: EXP can\'t drop below current value for {count} battles!'**
  String npcEffectExpFloorPositive(int count);

  /// Negative EXP floor effect
  ///
  /// In en, this message translates to:
  /// **'EXP Ceiling: EXP can\'t gain above current value for {count} battles!'**
  String npcEffectExpFloorNegative(int count);

  /// Positive EXP gamble effect
  ///
  /// In en, this message translates to:
  /// **'Lucky Gamble: EXP doubled!'**
  String get npcEffectExpGamblePositive;

  /// Negative EXP gamble effect
  ///
  /// In en, this message translates to:
  /// **'Unlucky Gamble: EXP halved!'**
  String get npcEffectExpGambleNegative;

  /// Tooltip for the effects button in bottom panel
  ///
  /// In en, this message translates to:
  /// **'Active Effects'**
  String get npcEffectsButtonTooltip;

  /// Title for the active effects dialog
  ///
  /// In en, this message translates to:
  /// **'Active Effects'**
  String get npcEffectsDialogTitle;

  /// Message when there are no active effects
  ///
  /// In en, this message translates to:
  /// **'No active effects.'**
  String get npcEffectsEmpty;

  /// Shows remaining battles for duration-based effects
  ///
  /// In en, this message translates to:
  /// **'{count} battles remaining'**
  String npcEffectRemainingBattles(int count);

  /// Name for EXP multiplier effect
  ///
  /// In en, this message translates to:
  /// **'EXP Multiplier'**
  String get npcEffectNameExpMultiplier;

  /// Name for EXP insurance effect
  ///
  /// In en, this message translates to:
  /// **'EXP Insurance'**
  String get npcEffectNameExpInsurance;

  /// Name for EXP floor effect
  ///
  /// In en, this message translates to:
  /// **'EXP Floor'**
  String get npcEffectNameExpFloor;

  /// Description for positive multiplier effect
  ///
  /// In en, this message translates to:
  /// **'2x EXP from battles'**
  String get npcEffectDescMultiplierPositive;

  /// Description for negative multiplier effect
  ///
  /// In en, this message translates to:
  /// **'0.5x EXP from battles'**
  String get npcEffectDescMultiplierNegative;

  /// Description for positive insurance effect
  ///
  /// In en, this message translates to:
  /// **'No EXP penalty on next loss'**
  String get npcEffectDescInsurancePositive;

  /// Description for negative insurance effect
  ///
  /// In en, this message translates to:
  /// **'No EXP reward on next win'**
  String get npcEffectDescInsuranceNegative;

  /// Description for positive floor effect
  ///
  /// In en, this message translates to:
  /// **'EXP can\'t drop below {value}'**
  String npcEffectDescFloorPositive(String value);

  /// Description for negative floor effect
  ///
  /// In en, this message translates to:
  /// **'EXP can\'t gain above {value}'**
  String npcEffectDescFloorNegative(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
