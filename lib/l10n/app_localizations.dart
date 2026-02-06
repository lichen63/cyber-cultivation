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

  /// Message when NPC has already been interacted with this session
  ///
  /// In en, this message translates to:
  /// **'You\'ve already met this NPC.'**
  String get exploreNpcAlreadyMet;

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

  /// Section label for adding NPC effects in debug dialog
  ///
  /// In en, this message translates to:
  /// **'Add NPC Effects'**
  String get exploreDebugAddEffects;

  /// Button to apply selected effects
  ///
  /// In en, this message translates to:
  /// **'Apply Selected'**
  String get exploreDebugApplyEffects;

  /// Message when effects have been added
  ///
  /// In en, this message translates to:
  /// **'{count} effect(s) added.'**
  String exploreDebugEffectsAdded(int count);

  /// Positive effect toggle label
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get exploreDebugEffectPositive;

  /// Negative effect toggle label
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get exploreDebugEffectNegative;

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

  /// Name for EXP gift/steal effect
  ///
  /// In en, this message translates to:
  /// **'EXP Gift/Steal'**
  String get npcEffectNameExpGiftSteal;

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

  /// Name for EXP gamble effect
  ///
  /// In en, this message translates to:
  /// **'EXP Gamble'**
  String get npcEffectNameExpGamble;

  /// Shows remaining moves for move-duration effects
  ///
  /// In en, this message translates to:
  /// **'{count} moves remaining'**
  String npcEffectRemainingMoves(int count);

  /// Name for FC buff/debuff effect
  ///
  /// In en, this message translates to:
  /// **'FC Buff'**
  String get npcEffectNameFcBuff;

  /// Positive FC buff effect
  ///
  /// In en, this message translates to:
  /// **'FC Boost: +20% Fighting Capacity for next {count} battles!'**
  String npcEffectFcBuffPositive(int count);

  /// Negative FC debuff effect
  ///
  /// In en, this message translates to:
  /// **'FC Curse: -20% Fighting Capacity for next {count} battles!'**
  String npcEffectFcBuffNegative(int count);

  /// Description for positive FC buff
  ///
  /// In en, this message translates to:
  /// **'+20% FC in battles'**
  String get npcEffectDescFcBuffPositive;

  /// Description for negative FC debuff
  ///
  /// In en, this message translates to:
  /// **'-20% FC in battles'**
  String get npcEffectDescFcBuffNegative;

  /// Name for guaranteed outcome effect
  ///
  /// In en, this message translates to:
  /// **'Fate Seal'**
  String get npcEffectNameGuaranteedOutcome;

  /// Positive guaranteed win effect
  ///
  /// In en, this message translates to:
  /// **'Victory Seal: Next battle is a guaranteed win!'**
  String get npcEffectGuaranteedOutcomePositive;

  /// Negative guaranteed loss effect
  ///
  /// In en, this message translates to:
  /// **'Doom Seal: Next battle is a guaranteed loss!'**
  String get npcEffectGuaranteedOutcomeNegative;

  /// Description for positive guaranteed outcome
  ///
  /// In en, this message translates to:
  /// **'Next battle: guaranteed win'**
  String get npcEffectDescGuaranteedOutcomePositive;

  /// Description for negative guaranteed outcome
  ///
  /// In en, this message translates to:
  /// **'Next battle: guaranteed loss'**
  String get npcEffectDescGuaranteedOutcomeNegative;

  /// Name for flee mastery effect
  ///
  /// In en, this message translates to:
  /// **'Flee Mastery'**
  String get npcEffectNameFleeMastery;

  /// Positive flee mastery effect
  ///
  /// In en, this message translates to:
  /// **'Escape Artist: Next {count} flee attempts always succeed!'**
  String npcEffectFleeMasteryPositive(int count);

  /// Negative flee mastery effect
  ///
  /// In en, this message translates to:
  /// **'Trapped: Next {count} flee attempts always fail!'**
  String npcEffectFleeMasteryNegative(int count);

  /// Description for positive flee mastery
  ///
  /// In en, this message translates to:
  /// **'Flee always succeeds'**
  String get npcEffectDescFleeMasteryPositive;

  /// Description for negative flee mastery
  ///
  /// In en, this message translates to:
  /// **'Flee always fails'**
  String get npcEffectDescFleeMasteryNegative;

  /// Name for first strike effect
  ///
  /// In en, this message translates to:
  /// **'First Strike'**
  String get npcEffectNameFirstStrike;

  /// Positive first strike effect
  ///
  /// In en, this message translates to:
  /// **'First Strike: Enemy FC counted at 50% in next battle!'**
  String get npcEffectFirstStrikePositive;

  /// Negative first strike effect
  ///
  /// In en, this message translates to:
  /// **'Ambushed: Your FC counted at 50% in next battle!'**
  String get npcEffectFirstStrikeNegative;

  /// Description for positive first strike
  ///
  /// In en, this message translates to:
  /// **'Enemy FC at 50%'**
  String get npcEffectDescFirstStrikePositive;

  /// Description for negative first strike
  ///
  /// In en, this message translates to:
  /// **'Your FC at 50%'**
  String get npcEffectDescFirstStrikeNegative;

  /// Name for glass cannon effect
  ///
  /// In en, this message translates to:
  /// **'Glass Cannon'**
  String get npcEffectNameGlassCannon;

  /// Positive glass cannon effect
  ///
  /// In en, this message translates to:
  /// **'Glass Cannon: +50% FC for next battle!'**
  String get npcEffectGlassCannonPositive;

  /// Negative glass cannon effect
  ///
  /// In en, this message translates to:
  /// **'Weakened: -50% FC for next battle!'**
  String get npcEffectGlassCannonNegative;

  /// Description for positive glass cannon
  ///
  /// In en, this message translates to:
  /// **'+50% FC next battle'**
  String get npcEffectDescGlassCannonPositive;

  /// Description for negative glass cannon
  ///
  /// In en, this message translates to:
  /// **'-50% FC next battle'**
  String get npcEffectDescGlassCannonNegative;

  /// Name for path clearing effect
  ///
  /// In en, this message translates to:
  /// **'Path Clearing'**
  String get npcEffectNamePathClearing;

  /// Positive path clearing effect
  ///
  /// In en, this message translates to:
  /// **'Path Cleared: {count} mountains removed!'**
  String npcEffectPathClearingPositive(int count);

  /// Negative path clearing effect
  ///
  /// In en, this message translates to:
  /// **'Landslide: {count} new mountains appeared!'**
  String npcEffectPathClearingNegative(int count);

  /// Name for river bridge effect
  ///
  /// In en, this message translates to:
  /// **'River Bridge'**
  String get npcEffectNameRiverBridge;

  /// Positive river bridge effect
  ///
  /// In en, this message translates to:
  /// **'River Crossed: {count} river cells bridged!'**
  String npcEffectRiverBridgePositive(int count);

  /// Negative river bridge effect
  ///
  /// In en, this message translates to:
  /// **'Flood: {count} new river cells appeared!'**
  String npcEffectRiverBridgeNegative(int count);

  /// Name for monster cleanse effect
  ///
  /// In en, this message translates to:
  /// **'Monster Cleanse'**
  String get npcEffectNameMonsterCleanse;

  /// Positive monster cleanse effect
  ///
  /// In en, this message translates to:
  /// **'Monster Cleanse: {count} nearby monsters vanished!'**
  String npcEffectMonsterCleansePositive(int count);

  /// Negative monster cleanse effect
  ///
  /// In en, this message translates to:
  /// **'Monster Surge: {count} new monsters appeared!'**
  String npcEffectMonsterCleanseNegative(int count);

  /// Name for boss shift effect
  ///
  /// In en, this message translates to:
  /// **'Boss Shift'**
  String get npcEffectNameBossShift;

  /// Positive boss shift effect
  ///
  /// In en, this message translates to:
  /// **'Boss Banished: Nearest boss removed!'**
  String get npcEffectBossShiftPositive;

  /// Negative boss shift effect
  ///
  /// In en, this message translates to:
  /// **'Boss Summoned: A new boss appeared!'**
  String get npcEffectBossShiftNegative;

  /// Name for safe zone effect
  ///
  /// In en, this message translates to:
  /// **'Safe Zone'**
  String get npcEffectNameSafeZone;

  /// Positive safe zone effect
  ///
  /// In en, this message translates to:
  /// **'Safe Zone: Area around you cleared of dangers!'**
  String get npcEffectSafeZonePositive;

  /// Negative safe zone effect
  ///
  /// In en, this message translates to:
  /// **'Danger Zone: Monsters spawned around you!'**
  String get npcEffectSafeZoneNegative;

  /// Name for terrain swap effect
  ///
  /// In en, this message translates to:
  /// **'Terrain Swap'**
  String get npcEffectNameTerrainSwap;

  /// Positive terrain swap effect
  ///
  /// In en, this message translates to:
  /// **'Terrain Cleared: {count} mountains converted to paths!'**
  String npcEffectTerrainSwapPositive(int count);

  /// Negative terrain swap effect
  ///
  /// In en, this message translates to:
  /// **'Terrain Blocked: {count} paths turned to mountains!'**
  String npcEffectTerrainSwapNegative(int count);

  /// Name for FOV modify effect
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get npcEffectNameFovModify;

  /// Positive FOV modify effect
  ///
  /// In en, this message translates to:
  /// **'Far Sight: Field of view increased by {amount} tiles!'**
  String npcEffectFovModifyPositive(int amount);

  /// Negative FOV modify effect
  ///
  /// In en, this message translates to:
  /// **'Blinded: Field of view decreased by {amount} tiles!'**
  String npcEffectFovModifyNegative(int amount);

  /// Description for positive FOV modify
  ///
  /// In en, this message translates to:
  /// **'+{amount} FOV'**
  String npcEffectDescFovModifyPositive(int amount);

  /// Description for negative FOV modify
  ///
  /// In en, this message translates to:
  /// **'-{amount} FOV'**
  String npcEffectDescFovModifyNegative(int amount);

  /// Name for boss radar effect
  ///
  /// In en, this message translates to:
  /// **'Boss Radar'**
  String get npcEffectNameBossRadar;

  /// Positive boss radar effect
  ///
  /// In en, this message translates to:
  /// **'Boss Radar: Nearest boss location revealed!'**
  String get npcEffectBossRadarPositive;

  /// Negative boss radar effect
  ///
  /// In en, this message translates to:
  /// **'Boss Cloaked: Boss cells hidden until stepped on!'**
  String get npcEffectBossRadarNegative;

  /// Description for negative boss radar
  ///
  /// In en, this message translates to:
  /// **'Bosses appear as blank'**
  String get npcEffectDescBossRadarNegative;

  /// Name for NPC radar effect
  ///
  /// In en, this message translates to:
  /// **'NPC Radar'**
  String get npcEffectNameNpcRadar;

  /// Positive NPC radar effect
  ///
  /// In en, this message translates to:
  /// **'NPC Radar: Nearest NPC location revealed!'**
  String get npcEffectNpcRadarPositive;

  /// Negative NPC radar effect
  ///
  /// In en, this message translates to:
  /// **'NPC Cloaked: NPC cells hidden until stepped on!'**
  String get npcEffectNpcRadarNegative;

  /// Description for negative NPC radar
  ///
  /// In en, this message translates to:
  /// **'NPCs appear as blank'**
  String get npcEffectDescNpcRadarNegative;

  /// Name for map reveal effect
  ///
  /// In en, this message translates to:
  /// **'Map Reveal'**
  String get npcEffectNameMapReveal;

  /// Positive map reveal effect
  ///
  /// In en, this message translates to:
  /// **'Cartographer: 20% of unexplored map revealed!'**
  String get npcEffectMapRevealPositive;

  /// Negative map reveal effect
  ///
  /// In en, this message translates to:
  /// **'Fog of War: FOV shrunk to 1 tile for {count} moves!'**
  String npcEffectMapRevealNegative(int count);

  /// Description for negative map reveal
  ///
  /// In en, this message translates to:
  /// **'FOV limited to 1 tile'**
  String get npcEffectDescMapRevealNegative;

  /// Name for monster radar effect
  ///
  /// In en, this message translates to:
  /// **'Monster Radar'**
  String get npcEffectNameMonsterRadar;

  /// Positive monster radar effect
  ///
  /// In en, this message translates to:
  /// **'Monster Radar: All monsters within 10 tiles revealed!'**
  String get npcEffectMonsterRadarPositive;

  /// Negative monster radar effect
  ///
  /// In en, this message translates to:
  /// **'Monster Cloak: Monsters within 10 tiles now invisible!'**
  String get npcEffectMonsterRadarNegative;

  /// Description for negative monster radar
  ///
  /// In en, this message translates to:
  /// **'Nearby monsters invisible'**
  String get npcEffectDescMonsterRadarNegative;

  /// Name for house radar effect
  ///
  /// In en, this message translates to:
  /// **'House Radar'**
  String get npcEffectNameHouseRadar;

  /// Positive house radar effect
  ///
  /// In en, this message translates to:
  /// **'House Radar: Nearest house location revealed!'**
  String get npcEffectHouseRadarPositive;

  /// Negative house radar effect
  ///
  /// In en, this message translates to:
  /// **'Houses Cloaked: House cells hidden until stepped on!'**
  String get npcEffectHouseRadarNegative;

  /// Description for negative house radar
  ///
  /// In en, this message translates to:
  /// **'Houses appear as blank'**
  String get npcEffectDescHouseRadarNegative;

  /// Name for teleport effect
  ///
  /// In en, this message translates to:
  /// **'Teleport'**
  String get npcEffectNameTeleport;

  /// Positive teleport effect
  ///
  /// In en, this message translates to:
  /// **'Far Teleport: Teleported to a distant location!'**
  String get npcEffectTeleportPositive;

  /// Negative teleport effect
  ///
  /// In en, this message translates to:
  /// **'Return: Teleported back to spawn point!'**
  String get npcEffectTeleportNegative;

  /// Name for speed boost effect
  ///
  /// In en, this message translates to:
  /// **'Speed Boost'**
  String get npcEffectNameSpeedBoost;

  /// Positive speed boost effect
  ///
  /// In en, this message translates to:
  /// **'Speed Boost: Move 2 cells per step for {count} moves!'**
  String npcEffectSpeedBoostPositive(int count);

  /// Negative speed boost effect
  ///
  /// In en, this message translates to:
  /// **'Slow: Move only every 2 key presses for {count} moves!'**
  String npcEffectSpeedBoostNegative(int count);

  /// Description for positive speed boost
  ///
  /// In en, this message translates to:
  /// **'Move 2 cells per step'**
  String get npcEffectDescSpeedBoostPositive;

  /// Description for negative speed boost
  ///
  /// In en, this message translates to:
  /// **'Move every 2 presses'**
  String get npcEffectDescSpeedBoostNegative;

  /// Name for teleport to house effect
  ///
  /// In en, this message translates to:
  /// **'Teleport to House'**
  String get npcEffectNameTeleportHouse;

  /// Positive teleport to house effect
  ///
  /// In en, this message translates to:
  /// **'House Teleport: Teleported to nearest house!'**
  String get npcEffectTeleportHousePositive;

  /// Negative teleport to house effect
  ///
  /// In en, this message translates to:
  /// **'Boss Teleport: Teleported to nearest boss!'**
  String get npcEffectTeleportHouseNegative;

  /// Name for pathfinder effect
  ///
  /// In en, this message translates to:
  /// **'Pathfinder'**
  String get npcEffectNamePathfinder;

  /// Positive pathfinder effect
  ///
  /// In en, this message translates to:
  /// **'Pathfinder: Shortest path to nearest house revealed!'**
  String get npcEffectPathfinderPositive;

  /// Negative pathfinder effect
  ///
  /// In en, this message translates to:
  /// **'Lost: All houses removed from map!'**
  String get npcEffectPathfinderNegative;

  /// Name for weaken enemies effect
  ///
  /// In en, this message translates to:
  /// **'Weaken Enemies'**
  String get npcEffectNameWeakenEnemies;

  /// Positive weaken enemies effect
  ///
  /// In en, this message translates to:
  /// **'Weaken Aura: Monsters in 10-tile radius get -30% FC!'**
  String get npcEffectWeakenEnemiesPositive;

  /// Negative weaken enemies effect
  ///
  /// In en, this message translates to:
  /// **'Rage Aura: Monsters in 10-tile radius get +30% FC!'**
  String get npcEffectWeakenEnemiesNegative;

  /// Name for monster conversion effect
  ///
  /// In en, this message translates to:
  /// **'Monster Conversion'**
  String get npcEffectNameMonsterConversion;

  /// Positive monster conversion effect
  ///
  /// In en, this message translates to:
  /// **'Taming: {count} nearest monsters became NPCs!'**
  String npcEffectMonsterConversionPositive(int count);

  /// Negative monster conversion effect
  ///
  /// In en, this message translates to:
  /// **'Corruption: {count} nearest NPCs became monsters!'**
  String npcEffectMonsterConversionNegative(int count);

  /// Name for boss downgrade effect
  ///
  /// In en, this message translates to:
  /// **'Boss Downgrade'**
  String get npcEffectNameBossDowngrade;

  /// Positive boss downgrade effect
  ///
  /// In en, this message translates to:
  /// **'Demotion: Nearest boss became regular monster!'**
  String get npcEffectBossDowngradePositive;

  /// Negative boss downgrade effect
  ///
  /// In en, this message translates to:
  /// **'Promotion: Nearest monster became boss!'**
  String get npcEffectBossDowngradeNegative;

  /// Name for monster freeze effect
  ///
  /// In en, this message translates to:
  /// **'Monster Freeze'**
  String get npcEffectNameMonsterFreeze;

  /// Positive monster freeze effect
  ///
  /// In en, this message translates to:
  /// **'Fear Aura: Next monster will flee on contact!'**
  String get npcEffectMonsterFreezePositive;

  /// Negative monster freeze effect
  ///
  /// In en, this message translates to:
  /// **'Enrage: Next monster gets +50% FC!'**
  String get npcEffectMonsterFreezeNegative;

  /// Description for positive monster freeze
  ///
  /// In en, this message translates to:
  /// **'Next monster flees'**
  String get npcEffectDescMonsterFreezePositive;

  /// Description for negative monster freeze
  ///
  /// In en, this message translates to:
  /// **'Next monster +50% FC'**
  String get npcEffectDescMonsterFreezeNegative;

  /// Name for clear wave effect
  ///
  /// In en, this message translates to:
  /// **'Clear Wave'**
  String get npcEffectNameClearWave;

  /// Positive clear wave effect
  ///
  /// In en, this message translates to:
  /// **'Purge: Monsters in 3-tile radius eliminated!'**
  String get npcEffectClearWavePositive;

  /// Negative clear wave effect
  ///
  /// In en, this message translates to:
  /// **'Infestation: Monsters spawned in 3-tile radius!'**
  String get npcEffectClearWaveNegative;

  /// Name for monster magnet effect
  ///
  /// In en, this message translates to:
  /// **'Monster Magnet'**
  String get npcEffectNameMonsterMagnet;

  /// Positive monster magnet effect
  ///
  /// In en, this message translates to:
  /// **'Repel: Monsters in 5-tile radius moved away!'**
  String get npcEffectMonsterMagnetPositive;

  /// Negative monster magnet effect
  ///
  /// In en, this message translates to:
  /// **'Attract: Monsters in 5-tile radius moved closer!'**
  String get npcEffectMonsterMagnetNegative;

  /// Name for NPC blessing chain effect
  ///
  /// In en, this message translates to:
  /// **'NPC Blessing Chain'**
  String get npcEffectNameNpcBlessingChain;

  /// Positive NPC blessing chain effect
  ///
  /// In en, this message translates to:
  /// **'Blessing Chain: Next NPC encounter guaranteed positive!'**
  String get npcEffectNpcBlessingChainPositive;

  /// Negative NPC blessing chain effect
  ///
  /// In en, this message translates to:
  /// **'Curse Chain: Next NPC encounter guaranteed negative!'**
  String get npcEffectNpcBlessingChainNegative;

  /// Description for positive NPC blessing chain
  ///
  /// In en, this message translates to:
  /// **'Next NPC is positive'**
  String get npcEffectDescNpcBlessingChainPositive;

  /// Description for negative NPC blessing chain
  ///
  /// In en, this message translates to:
  /// **'Next NPC is negative'**
  String get npcEffectDescNpcBlessingChainNegative;

  /// Name for NPC spawn effect
  ///
  /// In en, this message translates to:
  /// **'NPC Spawn'**
  String get npcEffectNameNpcSpawn;

  /// Positive NPC spawn effect
  ///
  /// In en, this message translates to:
  /// **'NPC Spawn: {count} new NPCs appeared on the map!'**
  String npcEffectNpcSpawnPositive(int count);

  /// Negative NPC spawn effect
  ///
  /// In en, this message translates to:
  /// **'NPC Removal: {count} NPCs vanished from the map!'**
  String npcEffectNpcSpawnNegative(int count);

  /// Name for NPC upgrade effect
  ///
  /// In en, this message translates to:
  /// **'NPC Upgrade'**
  String get npcEffectNameNpcUpgrade;

  /// Positive NPC upgrade effect
  ///
  /// In en, this message translates to:
  /// **'Double Effect: Next NPC effect is doubled!'**
  String get npcEffectNpcUpgradePositive;

  /// Negative NPC upgrade effect
  ///
  /// In en, this message translates to:
  /// **'Reverse: Next NPC effect is reversed!'**
  String get npcEffectNpcUpgradeNegative;

  /// Description for positive NPC upgrade
  ///
  /// In en, this message translates to:
  /// **'Next NPC effect 2x'**
  String get npcEffectDescNpcUpgradePositive;

  /// Description for negative NPC upgrade
  ///
  /// In en, this message translates to:
  /// **'Next NPC effect reversed'**
  String get npcEffectDescNpcUpgradeNegative;

  /// Name for house spawn effect
  ///
  /// In en, this message translates to:
  /// **'House Spawn'**
  String get npcEffectNameHouseSpawn;

  /// Positive house spawn effect
  ///
  /// In en, this message translates to:
  /// **'New Shelter: A house appeared nearby!'**
  String get npcEffectHouseSpawnPositive;

  /// Negative house spawn effect
  ///
  /// In en, this message translates to:
  /// **'House Destroyed: Nearest house removed!'**
  String get npcEffectHouseSpawnNegative;

  /// Name for house upgrade effect
  ///
  /// In en, this message translates to:
  /// **'House Upgrade'**
  String get npcEffectNameHouseUpgrade;

  /// Positive house upgrade effect
  ///
  /// In en, this message translates to:
  /// **'Enhanced Rest: Next house visit gives 2x benefit!'**
  String get npcEffectHouseUpgradePositive;

  /// Negative house upgrade effect
  ///
  /// In en, this message translates to:
  /// **'Poor Rest: Next house visit gives 0.5x benefit!'**
  String get npcEffectHouseUpgradeNegative;

  /// Description for positive house upgrade
  ///
  /// In en, this message translates to:
  /// **'Next house 2x benefit'**
  String get npcEffectDescHouseUpgradePositive;

  /// Description for negative house upgrade
  ///
  /// In en, this message translates to:
  /// **'Next house 0.5x benefit'**
  String get npcEffectDescHouseUpgradeNegative;

  /// Name for risk/reward effect
  ///
  /// In en, this message translates to:
  /// **'Risk/Reward'**
  String get npcEffectNameRiskReward;

  /// Positive risk/reward effect
  ///
  /// In en, this message translates to:
  /// **'Risk Taker: +50% EXP but -20% FC for {count} battles!'**
  String npcEffectRiskRewardPositive(int count);

  /// Negative risk/reward effect
  ///
  /// In en, this message translates to:
  /// **'Safe Play: +20% FC but -50% EXP for {count} battles!'**
  String npcEffectRiskRewardNegative(int count);

  /// Description for positive risk/reward
  ///
  /// In en, this message translates to:
  /// **'+50% EXP, -20% FC'**
  String get npcEffectDescRiskRewardPositive;

  /// Description for negative risk/reward
  ///
  /// In en, this message translates to:
  /// **'+20% FC, -50% EXP'**
  String get npcEffectDescRiskRewardNegative;

  /// Name for sacrifice effect
  ///
  /// In en, this message translates to:
  /// **'Sacrifice'**
  String get npcEffectNameSacrifice;

  /// Positive sacrifice effect
  ///
  /// In en, this message translates to:
  /// **'Sacrifice: Lose 5% EXP now, +30% FC for {count} battles!'**
  String npcEffectSacrificePositive(int count);

  /// Negative sacrifice effect
  ///
  /// In en, this message translates to:
  /// **'Dark Deal: Gain 5% EXP now, -30% FC for {count} battles!'**
  String npcEffectSacrificeNegative(int count);

  /// Description for positive sacrifice
  ///
  /// In en, this message translates to:
  /// **'+30% FC'**
  String get npcEffectDescSacrificePositive;

  /// Description for negative sacrifice
  ///
  /// In en, this message translates to:
  /// **'-30% FC'**
  String get npcEffectDescSacrificeNegative;

  /// Name for all-in effect
  ///
  /// In en, this message translates to:
  /// **'All-In'**
  String get npcEffectNameAllIn;

  /// Positive all-in effect
  ///
  /// In en, this message translates to:
  /// **'Purification: Monsters in 5 tiles cleared + bonus EXP!'**
  String get npcEffectAllInPositive;

  /// Negative all-in effect
  ///
  /// In en, this message translates to:
  /// **'Catastrophe: Extra boss spawned + EXP lost!'**
  String get npcEffectAllInNegative;

  /// Name for mirror effect
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get npcEffectNameMirror;

  /// Positive mirror effect
  ///
  /// In en, this message translates to:
  /// **'Mirror: Your FC doubled for next fight!'**
  String get npcEffectMirrorPositive;

  /// Negative mirror effect
  ///
  /// In en, this message translates to:
  /// **'Mirror: Next enemy copies your FC (50/50 chance)!'**
  String get npcEffectMirrorNegative;

  /// Description for positive mirror
  ///
  /// In en, this message translates to:
  /// **'2x FC next fight'**
  String get npcEffectDescMirrorPositive;

  /// Description for negative mirror
  ///
  /// In en, this message translates to:
  /// **'Enemy has your FC'**
  String get npcEffectDescMirrorNegative;

  /// Name for counter stack effect
  ///
  /// In en, this message translates to:
  /// **'Counter Stack'**
  String get npcEffectNameCounterStack;

  /// Positive counter stack effect
  ///
  /// In en, this message translates to:
  /// **'Momentum: Each step gives +1% FC up to {count} steps!'**
  String npcEffectCounterStackPositive(int count);

  /// Negative counter stack effect
  ///
  /// In en, this message translates to:
  /// **'Fatigue: Each step gives -1% FC for {count} steps!'**
  String npcEffectCounterStackNegative(int count);

  /// Description for positive counter stack
  ///
  /// In en, this message translates to:
  /// **'+{percent}% FC ({count} stacks)'**
  String npcEffectDescCounterStackPositive(int percent, int count);

  /// Description for negative counter stack
  ///
  /// In en, this message translates to:
  /// **'-{percent}% FC ({count} steps left)'**
  String npcEffectDescCounterStackNegative(int percent, int count);

  /// Name for map scramble effect
  ///
  /// In en, this message translates to:
  /// **'Map Scramble'**
  String get npcEffectNameMapScramble;

  /// Positive map scramble effect
  ///
  /// In en, this message translates to:
  /// **'Monster Shuffle: All monsters moved to new positions!'**
  String get npcEffectMapScramblePositive;

  /// Negative map scramble effect
  ///
  /// In en, this message translates to:
  /// **'NPC Shuffle: All NPCs moved to new positions!'**
  String get npcEffectMapScrambleNegative;

  /// Name for cell counter effect
  ///
  /// In en, this message translates to:
  /// **'Cell Counter'**
  String get npcEffectNameCellCounter;

  /// Positive cell counter effect
  ///
  /// In en, this message translates to:
  /// **'Monster Count: {count} monsters remaining on map!'**
  String npcEffectCellCounterPositive(int count);

  /// Negative cell counter effect
  ///
  /// In en, this message translates to:
  /// **'Confused Count: Roughly {count} monsters on map (maybe)!'**
  String npcEffectCellCounterNegative(int count);

  /// Name for progress boost effect
  ///
  /// In en, this message translates to:
  /// **'Progress Boost'**
  String get npcEffectNameProgressBoost;

  /// Positive progress boost effect
  ///
  /// In en, this message translates to:
  /// **'Explorer: {count} random cells marked as explored!'**
  String npcEffectProgressBoostPositive(int count);

  /// Negative progress boost effect
  ///
  /// In en, this message translates to:
  /// **'Amnesia: {count} explored cells forgotten!'**
  String npcEffectProgressBoostNegative(int count);
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
