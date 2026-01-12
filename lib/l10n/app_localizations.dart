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
