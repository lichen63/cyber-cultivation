import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'l10n/app_localizations.dart';
import 'models/daily_stats.dart';
import 'models/game_data.dart';
import 'models/menu_bar_settings.dart';
import 'models/todo_item.dart';
import 'services/game_data_service.dart';
import 'services/input_monitor_service.dart';
import 'services/menu_bar_helper.dart';
import 'services/menu_bar_info_service.dart';
import 'services/pomodoro_service.dart';
import 'services/popover_service.dart';
import 'services/window_capture_service.dart';
import 'widgets/accessibility_dialog.dart';
import 'widgets/debug_level_exp_dialog.dart';
import 'widgets/explore_window.dart';
import 'widgets/floating_exp_indicator.dart';
import 'widgets/games_list_dialog.dart';
import 'widgets/home_page_content.dart';
import 'widgets/level_up_effect.dart';
import 'widgets/pomodoro_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/stats_window.dart';
import 'widgets/system_stats_panel.dart';
import 'widgets/todo_dialog.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if this is a sub-window (explore window)
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(args[2]) as Map<String, dynamic>;

    // Note: Don't set window ID here - it's in sub-window's memory space
    // The main window tracks it separately

    runApp(ExploreWindowApp(args: argument, windowId: windowId));
    return;
  }

  // Main window initialization
  await windowManager.ensureInitialized();

  // Setup method handler to receive messages from sub-windows
  ExploreWindowManager.setupMethodHandler();

  launchAtStartup.setup(
    appName: AppConstants.appTitle,
    appPath: Platform.resolvedExecutable,
  );

  final gameDataService = GameDataService();
  var gameData = await gameDataService.loadGameData();
  bool needSave = false;

  if (gameData == null || gameData.userId == null) {
    final userId = await gameDataService.generateUserId();
    gameData =
        gameData?.copyWith(userId: userId) ??
        GameData(
          level: AppConstants.initialLevel,
          currentExp: 0,
          userId: userId,
        );
    needSave = true;
  }

  if (needSave) {
    await gameDataService.saveGameData(gameData);
  }

  final windowWidth = gameData.windowWidth ?? AppConstants.defaultWindowWidth;
  final windowHeight =
      gameData.windowHeight ?? AppConstants.defaultWindowHeight;
  final windowX = gameData.windowX;
  final windowY = gameData.windowY;
  final hasStoredPosition = windowX != null && windowY != null;

  final windowOptions = WindowOptions(
    size: Size(windowWidth, windowHeight),
    center: !hasStoredPosition,
    backgroundColor: AppConstants.transparentColor,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setMinimumSize(
      const Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
    );
    await windowManager.setMaximumSize(
      const Size(AppConstants.maxWindowWidth, AppConstants.maxWindowHeight),
    );
    await windowManager.setAspectRatio(AppConstants.windowAspectRatio);
    await windowManager.setOpacity(1.0);
    await windowManager.show();
    // Restore saved position after showing (must be after show to take effect)
    if (hasStoredPosition) {
      await windowManager.setPosition(Offset(windowX, windowY));
    }
    await windowManager.focus();
  });

  runApp(MyApp(initialGameData: gameData));
}

class MyApp extends StatefulWidget {
  final GameData? initialGameData;

  const MyApp({super.key, this.initialGameData});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  Locale? _locale;
  AppThemeMode _themeMode = AppThemeMode.dark;
  MenuBarSettings _menuBarSettings = const MenuBarSettings();
  String _trayIconPath = '';
  bool _trayIconPositioned = false; // Track if icon has been positioned left
  bool _isMenuBarUpdating = false; // Lock to prevent concurrent updates
  List<MenuBarItem>?
  _pendingMenuBarItems; // Store latest pending items if update is in progress
  Set<String> _currentMenuBarItemIds =
      {}; // Track current item IDs for ordering
  PomodoroState _pomodoroState =
      const PomodoroState(); // Current pomodoro state for popup
  // Level/Exp state for popup
  int _level = AppConstants.initialLevel;
  double _currentExp = 0;
  double _maxExp = AppConstants.initialMaxExp;

  AppThemeColors get _themeColors => AppThemeColors.fromMode(_themeMode);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _initializeFromGameData();
    _initTray();
    _initMenuBarHelper();
    _initPopoverService();
  }

  /// Initialize the native popover service
  void _initPopoverService() {
    PopoverService.instance.initialize();
  }

  void _initMenuBarHelper() {
    MenuBarHelper.initialize(
      onItemClicked: _onMenuBarItemClicked,
      onNativePopupShowing: _hidePopupWindow,
    );
  }

  /// Hide any open popup window (used when native popup or tray menu is shown).
  void _hidePopupWindow() {
    PopoverService.instance.hidePopover();
  }

  /// Handle menu bar item click - update popover with data
  /// Note: Native side shows popover immediately, this just updates the content
  Future<void> _onMenuBarItemClicked(String itemId) async {
    // Gather data for the popover based on itemId
    final popoverData = await _gatherPopoverData(itemId);

    // Update the already-visible native popover with the data
    await PopoverService.instance.updatePopoverContent(popoverData);
  }

  /// Gather data for popover content based on item type
  Future<Map<String, dynamic>> _gatherPopoverData(String itemId) async {
    final baseData = <String, dynamic>{
      'itemId': itemId,
      'brightness': _themeMode == AppThemeMode.dark ? 'dark' : 'light',
      'locale': _locale?.languageCode ?? 'en',
    };

    switch (itemId) {
      case 'focus':
        return {
          ...baseData,
          'focusIsActive': _pomodoroState.isActive,
          'focusIsRelaxing': _pomodoroState.isRelaxing,
          'focusSecondsRemaining': _pomodoroState.secondsRemaining,
          'focusCurrentLoop': _pomodoroState.currentLoop,
          'focusTotalLoops': _pomodoroState.totalLoops,
        };

      case 'levelExp':
        return {
          ...baseData,
          'level': _level,
          'currentExp': _currentExp,
          'maxExp': _maxExp,
        };

      // System stats items (cpu, gpu, ram, disk, network, battery) are now
      // handled directly by native Swift - see AppDelegate.loadSystemStatsNatively()

      case 'todo':
        final gameDataService = GameDataService();
        final gameData = await gameDataService.loadGameData();
        final todos =
            gameData?.todos
                .map((t) => {'title': t.title, 'status': t.status.name})
                .toList() ??
            [];
        return {...baseData, 'todos': todos};

      case 'keyboard':
        final gameDataService = GameDataService();
        final gameData = await gameDataService.loadGameData();
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayStats = gameData?.dailyStats[todayKey];
        return {...baseData, 'keyCount': todayStats?.keyboardCount ?? 0};

      case 'mouse':
        final gameDataService = GameDataService();
        final gameData = await gameDataService.loadGameData();
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayStats = gameData?.dailyStats[todayKey];
        return {...baseData, 'distance': todayStats?.mouseMoveDistance ?? 0};

      default:
        return baseData;
    }
  }

  void _initializeFromGameData() {
    final data = widget.initialGameData;
    if (data != null) {
      if (data.language != null) {
        _locale = Locale(data.language!);
      }
      _themeMode = data.themeMode;
      _menuBarSettings = data.menuBarSettings;
    }
    // Set initial theme for native UI components
    if (Platform.isMacOS) {
      MenuBarHelper.setTheme(
        isDark: _themeMode == AppThemeMode.dark,
        locale: _locale?.languageCode,
      );
    }
  }

  @override
  void dispose() {
    MenuBarHelper.dispose();
    PopoverService.instance.dispose();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    // On macOS, tray_manager expects the asset path directly (it loads via rootBundle)
    // On other platforms, we may need the extracted file path
    if (Platform.isMacOS) {
      _trayIconPath = TrayConstants.trayIconAssetPath;
    } else {
      _trayIconPath = await _extractAsset(TrayConstants.trayIconAssetPath);
    }
    // Don't set icon here - let _updateMenuBarItems handle it for proper positioning

    final menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show Window'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> _updateTrayIcon() async {
    // Icon is managed by _updateMenuBarItems for proper positioning
  }

  Future<void> _updateTrayTitle(String title) async {
    // Only update if we have any enabled info types
    if (_menuBarSettings.enabledInfoTypes.isEmpty) {
      await trayManager.setTitle('');
      await MenuBarHelper.clearMenuBarItems();
    } else {
      // Hide tray_manager's title (we'll use our own separate items)
      await trayManager.setTitle('');
    }
  }

  void _updateMenuBarItems(List<MenuBarItem> items) {
    // If an update is in progress, store as pending (overwrites any previous pending)
    if (_isMenuBarUpdating) {
      _pendingMenuBarItems = items;
      return;
    }

    _executeMenuBarUpdate(items);
  }

  Future<void> _executeMenuBarUpdate(List<MenuBarItem> items) async {
    _isMenuBarUpdating = true;
    _pendingMenuBarItems = null;

    try {
      if (items.isEmpty) {
        await MenuBarHelper.clearMenuBarItems();
        _trayIconPositioned = false; // Reset when items are cleared
        // Show tray icon even when no info items are enabled
        if (_menuBarSettings.showTrayIcon && _trayIconPath.isNotEmpty) {
          await trayManager.setIcon(
            _trayIconPath,
            iconSize: TrayConstants.macOSIconSize,
          );
          final menu = Menu(
            items: [
              MenuItem(key: 'show_window', label: 'Show Window'),
              MenuItem(key: 'hide_window', label: 'Hide Window'),
              MenuItem.separator(),
              MenuItem(key: 'exit_app', label: 'Exit'),
            ],
          );
          await trayManager.setContextMenu(menu);
          _trayIconPositioned = true;
        } else {
          await trayManager.destroy();
        }
      } else {
        // To ensure tray icon appears LEFT of our items:
        // 1. Destroy tray icon if it exists (removes its status item)
        // 2. Set our items (they get created at leftmost positions)
        // 3. Recreate tray icon (it becomes the new leftmost)

        final shouldShowTrayIcon =
            _menuBarSettings.showTrayIcon && _trayIconPath.isNotEmpty;

        // Check if we're adding new items (same logic as Swift side)
        // When new items are added, Swift recreates ALL items, so we need to
        // reposition the tray icon to maintain correct left-to-right order
        final newItemIds = items.map((item) => item.id).toSet();
        final hasNewItems = newItemIds
            .difference(_currentMenuBarItemIds)
            .isNotEmpty;
        if (hasNewItems) {
          _trayIconPositioned = false; // Reset so tray icon gets repositioned
        }
        _currentMenuBarItemIds = newItemIds;

        // Destroy tray icon if not yet positioned correctly
        if (shouldShowTrayIcon && !_trayIconPositioned) {
          await trayManager.destroy();
        }

        await MenuBarHelper.setMenuBarItems(
          items: items,
          fontSize: 10.0,
          fontWeight: 'light',
        );

        // Always ensure tray icon is shown when it should be
        if (shouldShowTrayIcon) {
          if (!_trayIconPositioned) {
            // First time - set icon which creates it at leftmost position
            // On macOS, specify iconSize for proper menu bar icon scaling
            await trayManager.setIcon(
              _trayIconPath,
              iconSize: TrayConstants.macOSIconSize,
            );
            // Re-set context menu after creating
            final menu = Menu(
              items: [
                MenuItem(key: 'show_window', label: 'Show Window'),
                MenuItem(key: 'hide_window', label: 'Hide Window'),
                MenuItem.separator(),
                MenuItem(key: 'exit_app', label: 'Exit'),
              ],
            );
            await trayManager.setContextMenu(menu);
            _trayIconPositioned = true;
          }
        }
      }
    } finally {
      _isMenuBarUpdating = false;

      // If there are pending items, process them (only the latest)
      if (_pendingMenuBarItems != null) {
        final pending = _pendingMenuBarItems!;
        _pendingMenuBarItems = null;
        // Use Future.microtask to avoid stack overflow on rapid calls
        Future.microtask(() => _executeMenuBarUpdate(pending));
      }
    }
  }

  void _onMenuBarSettingsChanged(MenuBarSettings settings) {
    setState(() => _menuBarSettings = settings);
    _updateTrayIcon();
  }

  Future<String> _extractAsset(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = p.basename(assetPath);
    final file = File(p.join(tempDir.path, fileName));
    final byteData = await rootBundle.load(assetPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  @override
  void onTrayIconMouseDown() {
    _hidePopupWindow();
    // Show tray popup with window preview instead of context menu
    _showTrayPopup();
  }

  @override
  void onTrayIconRightMouseDown() {
    _hidePopupWindow();
    // Right-click shows the traditional context menu
    trayManager.popUpContextMenu();
  }

  /// Show the tray popup window with live preview
  Future<void> _showTrayPopup() async {
    if (!Platform.isMacOS) return;
    try {
      await PopoverService.instance.showTrayPopup(
        isDarkMode: _themeMode == AppThemeMode.dark,
        locale: _locale?.languageCode ?? 'en',
        popupWidth: TrayPopupConstants.popupWidth,
        popupHeight: TrayPopupConstants.popupHeight,
        titleBarHeight: TrayPopupConstants.titleBarHeight,
      );
    } catch (e) {
      // Fallback to context menu if popup fails
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        windowManager.focus();
      case 'hide_window':
        windowManager.hide();
      case 'exit_app':
        // Use the native method to properly exit the application
        MenuBarHelper.exitApp();
    }
  }

  @override
  void onWindowResize() {
    windowManager.getSize().then((_) {
      windowManager.setAspectRatio(AppConstants.windowAspectRatio);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      theme: ThemeData(
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: AppConstants.transparentColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColors.progressBarFill,
          brightness: _themeColors.brightness,
        ),
        canvasColor: AppConstants.transparentColor,
      ),
      color: AppConstants.transparentColor,
      home: MyHomePage(
        initialGameData: widget.initialGameData,
        themeMode: _themeMode,
        themeColors: _themeColors,
        menuBarSettings: _menuBarSettings,
        onLanguageChanged: (lang) {
          setState(() => _locale = lang != null ? Locale(lang) : null);
          // Update native UI locale
          if (Platform.isMacOS) {
            MenuBarHelper.setTheme(
              isDark: _themeMode == AppThemeMode.dark,
              locale: lang,
            );
          }
        },
        onThemeModeChanged: (mode) {
          setState(() => _themeMode = mode);
          // Update native UI theme (calendar popup, etc.)
          if (Platform.isMacOS) {
            MenuBarHelper.setTheme(
              isDark: mode == AppThemeMode.dark,
              locale: _locale?.languageCode,
            );
          }
        },
        onMenuBarSettingsChanged: _onMenuBarSettingsChanged,
        onTrayTitleChanged: _updateTrayTitle,
        onMenuBarItemsChanged: _updateMenuBarItems,
        onPomodoroStateChanged: (state) => _pomodoroState = state,
        onLevelExpChanged: (level, currentExp, maxExp) {
          _level = level;
          _currentExp = currentExp;
          _maxExp = maxExp;
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final GameData? initialGameData;
  final AppThemeMode themeMode;
  final AppThemeColors themeColors;
  final MenuBarSettings menuBarSettings;
  final ValueChanged<String?>? onLanguageChanged;
  final ValueChanged<AppThemeMode>? onThemeModeChanged;
  final ValueChanged<MenuBarSettings>? onMenuBarSettingsChanged;
  final ValueChanged<String>? onTrayTitleChanged;
  final ValueChanged<List<MenuBarItem>>? onMenuBarItemsChanged;
  final ValueChanged<PomodoroState>? onPomodoroStateChanged;
  final void Function(int level, double currentExp, double maxExp)?
  onLevelExpChanged;

  const MyHomePage({
    super.key,
    this.initialGameData,
    required this.themeMode,
    required this.themeColors,
    required this.menuBarSettings,
    this.onLanguageChanged,
    this.onThemeModeChanged,
    this.onMenuBarSettingsChanged,
    this.onTrayTitleChanged,
    this.onMenuBarItemsChanged,
    this.onPomodoroStateChanged,
    this.onLevelExpChanged,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WindowListener, WidgetsBindingObserver {
  // UI State
  bool _isHovering = false;
  bool _isMenuOpen = false;

  // Settings
  bool _isAlwaysOnTop = true;
  bool _isAlwaysShowActionButtons = false;
  bool _isAutoStartEnabled = false;
  bool _isShowSystemStats = true;
  bool _isShowKeyboardTrack = true;
  bool _isShowMouseTrack = true;
  bool _isCompactModeEnabled = false;
  bool _isInCompactView = false;
  bool _isAnimatingWindow = false;
  // Store the original window size before entering compact mode
  double _originalWindowWidth = AppConstants.defaultWindowWidth;
  double _originalWindowHeight = AppConstants.defaultWindowHeight;
  // Debounce timer for compact mode transitions
  Timer? _compactModeDebounce;
  int _systemStatsRefreshSeconds =
      AppConstants.defaultSystemStatsRefreshSeconds;
  late AppThemeMode _themeMode;
  late MenuBarSettings _menuBarSettings;

  // EXP System
  int _level = AppConstants.initialLevel;
  double _currentExp = 0;
  double _maxExp = AppConstants.initialMaxExp;
  String? _userId;
  double _windowWidth = AppConstants.defaultWindowWidth;
  double _windowHeight = AppConstants.defaultWindowHeight;
  double? _windowX;
  double? _windowY;
  String? _language;

  // Todos
  List<TodoItem> _todos = [];

  // Pomodoro defaults
  int _defaultPomodoroDuration = AppConstants.defaultPomodoroDuration;
  int _defaultPomodoroRelax = AppConstants.defaultRelaxDuration;
  int _defaultPomodoroLoops = AppConstants.defaultPomodoroLoops;

  // Stats
  DailyStats _todayStats = DailyStats();
  Map<String, DailyStats> _dailyStatsMap = {};
  String _currentDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Services
  final GameDataService _gameDataService = GameDataService();
  late final PomodoroService _pomodoroService;
  late final InputMonitorService _inputMonitorService;
  late final MenuBarInfoService _menuBarInfoService;
  Timer? _saveDebounce;
  Timer? _trayUpdateTimer;

  // Floating exp indicator manager key
  final GlobalKey<FloatingExpIndicatorManagerState> _floatingExpKey =
      GlobalKey<FloatingExpIndicatorManagerState>();

  // Level-up effect wrapper key
  final GlobalKey<LevelUpEffectWrapperState> _levelUpEffectKey =
      GlobalKey<LevelUpEffectWrapperState>();

  // Window capture key for tray popup preview
  final GlobalKey _captureKey = GlobalKey();

  AppThemeColors get _themeColors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    _themeMode = widget.themeMode;
    _menuBarSettings = widget.menuBarSettings;

    _initializeServices();
    _setupExploreWindowCallback();

    if (widget.initialGameData != null) {
      _applyGameData(widget.initialGameData!);
    } else {
      _loadGameData();
    }

    _checkAccessibilityPermission();
  }

  /// Setup callback to receive EXP changes from explore window
  void _setupExploreWindowCallback() {
    ExploreWindowManager.setExpChangeCallback((newExp) {
      if (!mounted) return;
      // Calculate the difference and apply it
      final expDiff = newExp - _currentExp;
      if (expDiff > 0) {
        // Gained EXP - use _gainExp to handle level ups
        // Note: _gainExp already calls setState internally
        _gainExp(expDiff);
      } else if (expDiff < 0) {
        // Lost EXP - directly update (no level down)
        setState(() {
          _currentExp = newExp.clamp(0.0, double.infinity);
        });
        _saveGameData();
      }
    });
  }

  void _initializeServices() {
    _pomodoroService = PomodoroService(
      onWorkSessionComplete: (workMinutes) {
        _gainExp(AppConstants.expGainPerMinute * workMinutes);
      },
    );
    _pomodoroService.addListener(_onPomodoroStateChanged);

    _inputMonitorService = InputMonitorService(
      onExpGain: _gainExp,
      onStatsUpdate: _updateStats,
    );
    _inputMonitorService.addListener(_onInputMonitorChanged);
    _inputMonitorService.initialize();

    _menuBarInfoService = MenuBarInfoService();
    _menuBarInfoService.updateSettings(_menuBarSettings);
    _menuBarInfoService.initialize(refreshSeconds: _systemStatsRefreshSeconds);
    _menuBarInfoService.addListener(_onMenuBarInfoChanged);

    // Initialize window capture service for tray popup preview
    WindowCaptureService.instance.initialize();
    WindowCaptureService.instance.setBoundaryKey(_captureKey);

    // Update tray/menu bar items periodically
    _trayUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMenuBarInfo(),
    );
    // Initial update
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateMenuBarInfo());
  }

  void _onPomodoroStateChanged() {
    if (mounted) {
      setState(() {});
      widget.onPomodoroStateChanged?.call(_pomodoroService.state);
    }
  }

  void _onInputMonitorChanged() {
    if (mounted) setState(() {});
  }

  void _onMenuBarInfoChanged() {
    if (mounted) setState(() {});
  }

  void _updateMenuBarInfo() {
    // Update the data without notifying listeners to avoid recursion
    _menuBarInfoService.updateDataSilently(
      pomodoroState: _pomodoroService.state,
      todos: _todos,
      level: _level,
      currentExp: _currentExp,
      maxExp: _maxExp,
      currentKey: _inputMonitorService.currentKey,
      todayMouseDistance: _todayStats.mouseMoveDistance,
      todayKeyboardCount: _todayStats.keyboardCount,
    );

    // Build and update separate menu bar items
    final items = _menuBarInfoService.buildMenuBarItems();
    widget.onMenuBarItemsChanged?.call(items);
  }

  @override
  void dispose() {
    ExploreWindowManager.setExpChangeCallback(null);
    _pomodoroService.removeListener(_onPomodoroStateChanged);
    _pomodoroService.dispose();
    _inputMonitorService.removeListener(_onInputMonitorChanged);
    _inputMonitorService.dispose();
    _menuBarInfoService.removeListener(_onMenuBarInfoChanged);
    _menuBarInfoService.dispose();
    WindowCaptureService.instance.dispose();
    _trayUpdateTimer?.cancel();
    _compactModeDebounce?.cancel();
    _saveGameData(immediate: true);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkAccessibilityPermission() async {
    final isGranted = await AccessibilityService.checkAccessibility();
    if (!isGranted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AccessibilityDialog.show(context: context, themeColors: _themeColors);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveGameData(immediate: true);
    }
  }

  @override
  void onWindowResize() {
    // Don't update window size while in compact view or animating
    if (_isInCompactView || _isAnimatingWindow) return;

    windowManager.getSize().then((size) {
      windowManager.setAspectRatio(AppConstants.windowAspectRatio);
      if (mounted) {
        _windowWidth = size.width;
        _windowHeight = size.height;
        _scheduleSave();
      }
    });
  }

  @override
  void onWindowMove() {
    // Don't update window position while animating
    if (_isAnimatingWindow) return;

    windowManager.getPosition().then((position) {
      if (mounted) {
        _windowX = position.dx;
        _windowY = position.dy;
        _scheduleSave();
      }
    });
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 1), () => _saveGameData());
  }

  void _applyGameData(GameData data) {
    if (!mounted) return;
    setState(() {
      _level = data.level;
      _isAlwaysOnTop = data.isAlwaysOnTop;
      _inputMonitorService.enableAntiSleep = data.isAntiSleepEnabled;
      _isAlwaysShowActionButtons = data.isAlwaysShowActionButtons;
      _isAutoStartEnabled = data.isAutoStartEnabled;
      _isShowSystemStats = data.isShowSystemStats;
      _isShowKeyboardTrack = data.isShowKeyboardTrack;
      _isShowMouseTrack = data.isShowMouseTrack;
      _isCompactModeEnabled = data.isCompactModeEnabled;
      _systemStatsRefreshSeconds = data.systemStatsRefreshSeconds;
      _userId = data.userId;
      _language = data.language;
      _themeMode = data.themeMode;
      _menuBarSettings = data.menuBarSettings;
      _windowWidth = data.windowWidth ?? AppConstants.defaultWindowWidth;
      _windowHeight = data.windowHeight ?? AppConstants.defaultWindowHeight;
      _windowX = data.windowX;
      _windowY = data.windowY;
      _todos = List.from(data.todos);

      _dailyStatsMap = Map.of(data.dailyStats);
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _currentDateKey = todayKey;
      _todayStats = _dailyStatsMap[todayKey] ?? DailyStats();
      _dailyStatsMap[todayKey] = _todayStats;

      _defaultPomodoroDuration = data.defaultPomodoroDuration;
      _defaultPomodoroRelax = data.defaultPomodoroRelax;
      _defaultPomodoroLoops = data.defaultPomodoroLoops;

      if (_level >= AppConstants.maxLevel) {
        _currentExp = double.infinity;
        _maxExp = double.infinity;
      } else {
        _currentExp = data.currentExp;
        _maxExp =
            AppConstants.initialMaxExp *
            pow(AppConstants.expGrowthFactor, _level - 1);
      }
    });
    widget.onLevelExpChanged?.call(_level, _currentExp, _maxExp);
    windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    _menuBarInfoService.updateSettings(_menuBarSettings);
    // Defer the callback to after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMenuBarSettingsChanged?.call(_menuBarSettings);
    });
  }

  Future<void> _loadGameData() async {
    final data = await _gameDataService.loadGameData();
    if (data != null) {
      _applyGameData(data);
    } else {
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    }
  }

  void _saveGameData({bool immediate = false}) {
    _saveDebounce?.cancel();

    Future<void> save() async {
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dailyStatsMap[todayKey] = _todayStats;

      await _gameDataService.saveGameData(
        GameData(
          level: _level,
          currentExp: _currentExp,
          isAlwaysOnTop: _isAlwaysOnTop,
          isAntiSleepEnabled: _inputMonitorService.enableAntiSleep,
          isAlwaysShowActionButtons: _isAlwaysShowActionButtons,
          isAutoStartEnabled: _isAutoStartEnabled,
          isShowSystemStats: _isShowSystemStats,
          isShowKeyboardTrack: _isShowKeyboardTrack,
          isShowMouseTrack: _isShowMouseTrack,
          isCompactModeEnabled: _isCompactModeEnabled,
          systemStatsRefreshSeconds: _systemStatsRefreshSeconds,
          windowWidth: _windowWidth,
          windowHeight: _windowHeight,
          windowX: _windowX,
          windowY: _windowY,
          userId: _userId,
          language: _language,
          themeMode: _themeMode,
          dailyStats: _dailyStatsMap,
          todos: _todos,
          menuBarSettings: _menuBarSettings,
          defaultPomodoroDuration: _defaultPomodoroDuration,
          defaultPomodoroRelax: _defaultPomodoroRelax,
          defaultPomodoroLoops: _defaultPomodoroLoops,
        ),
      );
    }

    if (immediate) {
      save();
    } else {
      _saveDebounce = Timer(const Duration(seconds: 1), save);
    }
  }

  void _gainExp(double amount) {
    if (_level >= AppConstants.maxLevel) return;

    // Trigger floating exp indicator
    _floatingExpKey.currentState?.addExpGain(amount);

    final previousLevel = _level;

    setState(() {
      _currentExp += amount;
      while (_currentExp >= _maxExp && _level < AppConstants.maxLevel) {
        _currentExp -= _maxExp;
        _level++;
        _maxExp = _maxExp * AppConstants.expGrowthFactor;
      }

      if (_level >= AppConstants.maxLevel) {
        _currentExp = double.infinity;
        _maxExp = double.infinity;
      }
    });

    // Trigger level-up effect if level increased
    if (_level > previousLevel) {
      _levelUpEffectKey.currentState?.triggerLevelUp();
    }

    widget.onLevelExpChanged?.call(_level, _currentExp, _maxExp);
    _saveGameData();
  }

  void _updateStats({
    int keyboardCount = 0,
    int clickCount = 0,
    double moveDistance = 0,
  }) {
    if (!mounted) return;

    // Check if date has changed (midnight crossed)
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (todayKey != _currentDateKey) {
      // Save yesterday's stats and start fresh for today
      _dailyStatsMap[_currentDateKey] = _todayStats;
      _currentDateKey = todayKey;
      _todayStats = _dailyStatsMap[todayKey] ?? DailyStats();
      _dailyStatsMap[todayKey] = _todayStats;
      _saveGameData(immediate: true);
    }

    setState(() {
      _todayStats.keyboardCount += keyboardCount;
      _todayStats.mouseClickCount += clickCount;
      _todayStats.mouseMoveDistance += moveDistance.toInt();
    });
  }

  void _showPomodoroDialog() {
    if (_pomodoroService.isActive) {
      _confirmStopPomodoro();
      return;
    }

    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => PomodoroDialog(
        initialDuration: _defaultPomodoroDuration,
        initialRelax: _defaultPomodoroRelax,
        initialLoops: _defaultPomodoroLoops,
        themeColors: _themeColors,
        onStart: (duration, relax, loops) {
          Navigator.of(context).pop();
          _pomodoroService.start(
            workMinutes: duration,
            relaxMinutes: relax,
            loops: loops,
          );
        },
        onSaveAsDefault: (duration, relax, loops) {
          setState(() {
            _defaultPomodoroDuration = duration;
            _defaultPomodoroRelax = relax;
            _defaultPomodoroLoops = loops;
          });
          _saveGameData(immediate: true);
        },
      ),
    );
  }

  void _confirmStopPomodoro() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => AlertDialog(
        backgroundColor: _themeColors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: _themeColors.border, width: 2),
        ),
        title: Text(
          l10n.confirmStopTitle,
          style: TextStyle(color: _themeColors.error),
        ),
        content: Text(
          l10n.confirmStopContent,
          style: TextStyle(color: _themeColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancelButtonText,
              style: TextStyle(color: _themeColors.inactive),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pomodoroService.cancel();
            },
            child: Text(
              l10n.stopButtonText,
              style: TextStyle(color: _themeColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsWindow() {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final viewHistory = Map<String, DailyStats>.from(_dailyStatsMap);
    viewHistory[todayKey] = _todayStats;

    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => StatsWindow(
        todayStats: _todayStats,
        historyStats: viewHistory,
        themeColors: _themeColors,
        onClearStats: _clearAllStats,
      ),
    );
  }

  void _clearAllStats() {
    setState(() {
      _dailyStatsMap.clear();
      _todayStats = DailyStats();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dailyStatsMap[todayKey] = _todayStats;
    });
    _saveGameData(immediate: true);
  }

  void _showGamesDialog() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => GamesListDialog(
        themeColors: _themeColors,
        onExpGained: (expGained) {
          _gainExp(expGained.toDouble());
        },
      ),
    );
  }

  void _showExploreWindow() {
    showExploreWindow(
      context: context,
      themeColors: _themeColors,
      level: _level,
      currentExp: _currentExp,
      maxExp: _maxExp,
    );
  }

  void _showTodoDialog() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => TodoDialog(
        todos: _todos,
        themeColors: _themeColors,
        onTodosChanged: (updatedTodos) {
          setState(() => _todos = updatedTodos);
          _saveGameData(immediate: true);
        },
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) => SettingsDialog(
        isAlwaysOnTop: _isAlwaysOnTop,
        isAntiSleepEnabled: _inputMonitorService.enableAntiSleep,
        isAlwaysShowActionButtons: _isAlwaysShowActionButtons,
        isAutoStartEnabled: _isAutoStartEnabled,
        isShowSystemStats: _isShowSystemStats,
        isShowKeyboardTrack: _isShowKeyboardTrack,
        isShowMouseTrack: _isShowMouseTrack,
        systemStatsRefreshSeconds: _systemStatsRefreshSeconds,
        currentLanguage: _language,
        themeMode: _themeMode,
        themeColors: _themeColors,
        menuBarSettings: _menuBarSettings,
        menuBarInfoService: _menuBarInfoService,
        onAlwaysOnTopChanged: _toggleAlwaysOnTop,
        onAntiSleepChanged: (value) {
          setState(() => _inputMonitorService.enableAntiSleep = value);
          _saveGameData();
        },
        onAlwaysShowActionButtonsChanged: (value) {
          setState(() => _isAlwaysShowActionButtons = value);
          _saveGameData();
        },
        onAutoStartChanged: _toggleAutoStart,
        onShowSystemStatsChanged: (value) {
          setState(() => _isShowSystemStats = value);
          _saveGameData();
        },
        onShowKeyboardTrackChanged: (value) {
          setState(() => _isShowKeyboardTrack = value);
          _saveGameData();
        },
        onShowMouseTrackChanged: (value) {
          setState(() => _isShowMouseTrack = value);
          _saveGameData();
        },
        onSystemStatsRefreshSecondsChanged: (value) {
          setState(() => _systemStatsRefreshSeconds = value);
          _menuBarInfoService.updateRefreshInterval(value);
          _saveGameData();
        },
        onLanguageChanged: (value) {
          setState(() => _language = value);
          widget.onLanguageChanged?.call(value);
          _saveGameData();
        },
        onThemeModeChanged: (value) {
          setState(() => _themeMode = value);
          widget.onThemeModeChanged?.call(value);
          _saveGameData();
        },
        onMenuBarSettingsChanged: (value) {
          setState(() => _menuBarSettings = value);
          _menuBarInfoService.updateSettings(value);
          _updateMenuBarInfo(); // Immediate update for responsive UI
          widget.onMenuBarSettingsChanged?.call(value);
          _saveGameData();
        },
        onResetLevelExp: _resetLevelExp,
      ),
    );
  }

  void _resetLevelExp() {
    setState(() {
      _level = AppConstants.initialLevel;
      _currentExp = 0;
      _maxExp = AppConstants.initialMaxExp;
    });
    _saveGameData(immediate: true);
  }

  void _toggleAutoStart(bool value) async {
    setState(() => _isAutoStartEnabled = value);
    if (value) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    _saveGameData();
  }

  void _toggleAlwaysOnTop(bool value) async {
    setState(() => _isAlwaysOnTop = value);
    await windowManager.setAlwaysOnTop(value);
    _saveGameData();
  }

  /// Toggle compact mode on/off
  void _toggleCompactMode(bool enabled) {
    setState(() => _isCompactModeEnabled = enabled);
    if (enabled) {
      // When enabling, shrink to compact view
      _animateToCompactView();
    } else {
      // When disabling, restore to normal view if currently in compact
      if (_isInCompactView) {
        _animateToNormalView();
      }
    }
    _saveGameData();
  }

  /// Close all dialogs and popups before shrinking to compact mode
  void _closeAllDialogs() {
    // Pop all routes until we reach the main page (MaterialApp's home)
    // This closes all dialogs, bottom sheets, and other modal routes
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Animate window to compact circular view (small circle with character)
  Future<void> _animateToCompactView() async {
    if (_isAnimatingWindow || _isInCompactView) return;

    // Close all dialogs and popups before shrinking to compact mode
    _closeAllDialogs();

    _isAnimatingWindow = true;
    setState(() {});

    try {
      final compactSize = AppConstants.compactModeSize;

      // Get current window bounds
      final currentBounds = await windowManager.getBounds();

      // Only save original size if current window is larger than compact
      // This prevents overwriting when re-shrinking after hover
      if (currentBounds.width > compactSize * 1.5) {
        _originalWindowWidth = currentBounds.width;
        _originalWindowHeight = currentBounds.height;
      }

      // Remove all constraints first
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(const Size(1, 1));
      await windowManager.setMaximumSize(const Size(10000, 10000));

      // Animate in steps for smoother transition
      const int steps = 15;
      const int delayMs = 16; // ~60fps
      final startWidth = currentBounds.width;
      final startHeight = currentBounds.height;
      final startLeft = currentBounds.left;
      final startTop = currentBounds.top;

      final centerX = startLeft + startWidth / 2;
      final centerY = startTop + startHeight / 2;
      final endLeft = centerX - compactSize / 2;
      final endTop = centerY - compactSize / 2;

      for (int i = 1; i <= steps; i++) {
        final t = i / steps;
        // Ease-out curve for smoother deceleration
        final easeT = 1 - pow(1 - t, 3);

        final currentWidth = startWidth + (compactSize - startWidth) * easeT;
        final currentHeight = startHeight + (compactSize - startHeight) * easeT;
        final currentLeft = startLeft + (endLeft - startLeft) * easeT;
        final currentTop = startTop + (endTop - startTop) * easeT;

        await windowManager.setBounds(
          Rect.fromLTWH(currentLeft, currentTop, currentWidth, currentHeight),
        );
        await Future.delayed(const Duration(milliseconds: delayMs));
      }

      // Lock the window size
      await windowManager.setMinimumSize(Size(compactSize, compactSize));
      await windowManager.setMaximumSize(Size(compactSize, compactSize));
      await windowManager.setResizable(false);

      _isInCompactView = true;
    } finally {
      _isAnimatingWindow = false;
      if (mounted) setState(() {});
    }
  }

  /// Animate window back to normal rectangular view
  Future<void> _animateToNormalView() async {
    if (_isAnimatingWindow || !_isInCompactView) return;

    _isAnimatingWindow = true;
    setState(() {});

    try {
      // Use the saved original window size, with fallback to defaults
      final targetWidth = _originalWindowWidth >= AppConstants.minWindowWidth
          ? _originalWindowWidth
          : AppConstants.defaultWindowWidth;
      final targetHeight = _originalWindowHeight >= AppConstants.minWindowHeight
          ? _originalWindowHeight
          : AppConstants.defaultWindowHeight;

      // Unlock resizing first
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(const Size(1, 1));
      await windowManager.setMaximumSize(const Size(10000, 10000));

      // Get current position
      final currentBounds = await windowManager.getBounds();

      // Animate in steps for smoother transition
      const int steps = 15;
      const int delayMs = 16; // ~60fps
      final startWidth = currentBounds.width;
      final startHeight = currentBounds.height;
      final startLeft = currentBounds.left;
      final startTop = currentBounds.top;

      final centerX = startLeft + startWidth / 2;
      final centerY = startTop + startHeight / 2;
      final endLeft = centerX - targetWidth / 2;
      final endTop = centerY - targetHeight / 2;

      for (int i = 1; i <= steps; i++) {
        final t = i / steps;
        // Ease-out curve for smoother deceleration
        final easeT = 1 - pow(1 - t, 3);

        final currentWidth = startWidth + (targetWidth - startWidth) * easeT;
        final currentHeight =
            startHeight + (targetHeight - startHeight) * easeT;
        final currentLeft = startLeft + (endLeft - startLeft) * easeT;
        final currentTop = startTop + (endTop - startTop) * easeT;

        await windowManager.setBounds(
          Rect.fromLTWH(currentLeft, currentTop, currentWidth, currentHeight),
        );
        await Future.delayed(const Duration(milliseconds: delayMs));
      }

      // Restore normal constraints
      await windowManager.setMinimumSize(
        const Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
      );
      await windowManager.setMaximumSize(
        const Size(AppConstants.maxWindowWidth, AppConstants.maxWindowHeight),
      );
      await windowManager.setAspectRatio(AppConstants.windowAspectRatio);

      _isInCompactView = false;
    } finally {
      _isAnimatingWindow = false;
      if (mounted) setState(() {});
    }
  }

  void _showContextMenu(Offset position) async {
    setState(() => _isMenuOpen = true);
    final l10n = AppLocalizations.of(context)!;

    final items = <PopupMenuEntry<String>>[
      _buildMenuItem(
        value: AppConstants.toggleAlwaysOnTopValue,
        label: l10n.forceForegroundText,
        isChecked: _isAlwaysOnTop,
      ),
      _buildMenuItem(
        value: AppConstants.toggleAntiSleepValue,
        label: l10n.antiSleepText,
        isChecked: _inputMonitorService.enableAntiSleep,
      ),
      _buildMenuItem(
        value: AppConstants.toggleCompactModeValue,
        label: l10n.compactModeText,
        isChecked: _isCompactModeEnabled,
      ),
      _buildMenuItem(
        value: AppConstants.hideWindowValue,
        label: l10n.hideWindowText,
      ),
      // Debug menu inserted here in debug mode (before exit)
      if (kDebugMode)
        _DebugSubmenuItem(
          themeColors: _themeColors,
          l10n: l10n,
          onSelected: (value) {
            Navigator.of(context).pop();
            _handleMenuResult(value);
          },
        ),
      _buildMenuItem(
        value: AppConstants.exitGameValue,
        label: l10n.exitGameText,
        isDestructive: true,
      ),
    ];

    final result = await showMenu(
      context: context,
      color: _themeColors.overlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        side: BorderSide(color: _themeColors.border, width: 2),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    );

    if (mounted) setState(() => _isMenuOpen = false);

    _handleMenuResult(result);
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required String label,
    bool isChecked = false,
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: isChecked
                ? Icon(Icons.check, color: _themeColors.primaryText, size: 18)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDestructive
                    ? _themeColors.error
                    : _themeColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuResult(String? result) {
    switch (result) {
      case AppConstants.toggleAlwaysOnTopValue:
        _toggleAlwaysOnTop(!_isAlwaysOnTop);
      case AppConstants.toggleAntiSleepValue:
        setState(() {
          _inputMonitorService.enableAntiSleep =
              !_inputMonitorService.enableAntiSleep;
        });
        _saveGameData();
      case AppConstants.toggleCompactModeValue:
        _toggleCompactMode(!_isCompactModeEnabled);
      case AppConstants.hideWindowValue:
        windowManager.hide();
      case AppConstants.exitGameValue:
        // Use native method to properly exit the app
        MenuBarHelper.exitApp();
      case AppConstants.debugSetLevelExpValue:
        _showDebugLevelExpDialog();
    }
  }

  void _showDebugLevelExpDialog() {
    showDialog(
      context: context,
      builder: (context) => DebugLevelExpDialog(
        currentLevel: _level,
        currentExp: _currentExp,
        themeColors: _themeColors,
        onApply: (level, exp) {
          setState(() {
            _level = level;
            _currentExp = exp;
            _maxExp =
                AppConstants.initialMaxExp *
                pow(AppConstants.expGrowthFactor, level - 1);
            if (_level >= AppConstants.maxLevel) {
              _currentExp = double.infinity;
              _maxExp = double.infinity;
            }
          });
          widget.onLevelExpChanged?.call(_level, _currentExp, _maxExp);
          _saveGameData(immediate: true);
        },
      ),
    );
  }

  /// Build the compact circular view showing only the character image
  Widget _buildCompactView() {
    return GestureDetector(
      onTap: () {
        // Click to expand from compact view to normal view
        if (_isCompactModeEnabled && _isInCompactView && !_isAnimatingWindow) {
          _animateToNormalView();
        }
      },
      child: DragToMoveArea(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _themeColors.border, width: 3.0),
            color: _themeColors.overlay,
          ),
          child: ClipOval(
            child: Image.asset(
              AppConstants.characterImagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mouseData = _inputMonitorService.mouseData;
    final menuBarData = _menuBarInfoService.data;

    // Build the normal content widget (used for both display and capture)
    final normalContent = HomePageContent(
      level: _level,
      currentExp: _currentExp,
      maxExp: _maxExp,
      currentKey: _inputMonitorService.currentKey,
      mouseX: mouseData.mouseX,
      mouseY: mouseData.mouseY,
      screenWidth: mouseData.screenWidth,
      screenHeight: mouseData.screenHeight,
      isMouseClicking: mouseData.isClicking,
      isHovering: _isHovering,
      isAlwaysShowActionButtons: _isAlwaysShowActionButtons,
      isShowSystemStats: _isShowSystemStats,
      isShowKeyboardTrack: _isShowKeyboardTrack,
      isShowMouseTrack: _isShowMouseTrack,
      systemStats: SystemStatsData(
        cpuUsage: menuBarData.cpuUsage,
        gpuUsage: menuBarData.gpuUsage,
        ramUsage: menuBarData.ramUsage,
        diskUsage: menuBarData.diskUsage,
        networkUpload: menuBarData.networkUpload,
        networkDownload: menuBarData.networkDownload,
      ),
      pomodoroState: _pomodoroService.state,
      todos: _todos,
      themeColors: _themeColors,
      floatingExpKey: _floatingExpKey,
      levelUpEffectKey: _levelUpEffectKey,
      captureKey: _captureKey,
      onPomodoroPressed: _showPomodoroDialog,
      onStatsPressed: _showStatsWindow,
      onTodoPressed: _showTodoDialog,
      onSettingsPressed: _showSettingsDialog,
      onGamesPressed: _showGamesDialog,
      onExplorePressed: _showExploreWindow,
      onContextMenu: _showContextMenu,
    );

    return Scaffold(
      backgroundColor: AppConstants.transparentColor,
      body: MouseRegion(
        onEnter: (_) => _handleMouseEnter(),
        onExit: (event) => _handleMouseExit(event),
        child: Stack(
          children: [
            // Hidden offscreen widget for capture when in compact view
            // This ensures tray popup always shows normal window preview
            if (_isInCompactView)
              Positioned(
                left: -10000,
                top: -10000,
                width: _originalWindowWidth,
                height: _originalWindowHeight,
                child: normalContent,
              ),
            // Visible content
            _isInCompactView ? _buildCompactView() : normalContent,
          ],
        ),
      ),
    );
  }

  void _handleMouseEnter() {
    setState(() => _isHovering = true);
    _compactModeDebounce?.cancel();
  }

  void _handleMouseExit(PointerExitEvent event) {
    setState(() => _isHovering = false);

    // Check if mouse is truly outside the window bounds
    final windowSize = MediaQuery.of(context).size;
    final windowRect = Rect.fromLTWH(0, 0, windowSize.width, windowSize.height);
    final safeRect = windowRect.inflate(10.0);
    final isOutsideWindow = !safeRect.contains(event.position);

    // When leaving window in compact mode, shrink back to compact view after a delay
    // Only shrink if mouse is truly outside the window (not just moved to a dialog overlay)
    if (_isCompactModeEnabled &&
        !_isInCompactView &&
        !_isMenuOpen &&
        isOutsideWindow) {
      _compactModeDebounce?.cancel();
      _compactModeDebounce = Timer(const Duration(milliseconds: 300), () {
        if (_isCompactModeEnabled &&
            !_isInCompactView &&
            !_isMenuOpen &&
            !_isAnimatingWindow &&
            !_isHovering) {
          _animateToCompactView();
        }
      });
    }

    if (_isMenuOpen) {
      if (isOutsideWindow) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// A custom PopupMenuEntry that shows a submenu on hover.
/// Used for the debug menu in debug mode.
class _DebugSubmenuItem extends PopupMenuEntry<String> {
  final AppThemeColors themeColors;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelected;

  const _DebugSubmenuItem({
    required this.themeColors,
    required this.l10n,
    required this.onSelected,
  });

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(String? value) => false;

  @override
  State<_DebugSubmenuItem> createState() => _DebugSubmenuItemState();
}

class _DebugSubmenuItemState extends State<_DebugSubmenuItem> {
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;
  bool _isSubmenuHovering = false;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSubmenu() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 180,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(4, 0),
          child: MouseRegion(
            onEnter: (_) {
              _isSubmenuHovering = true;
            },
            onExit: (_) {
              _isSubmenuHovering = false;
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!_isHovering && !_isSubmenuHovering) {
                  _removeOverlay();
                }
              });
            },
            child: Material(
              color: widget.themeColors.overlay,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.smallBorderRadius,
                ),
                side: BorderSide(color: widget.themeColors.border, width: 2),
              ),
              elevation: 8,
              child: InkWell(
                onTap: () {
                  _removeOverlay();
                  widget.onSelected(AppConstants.debugSetLevelExpValue);
                },
                borderRadius: BorderRadius.circular(
                  AppConstants.smallBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.l10n.debugSetLevelExp,
                          style: TextStyle(
                            color: widget.themeColors.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onHoverChanged(bool hovering) {
    _isHovering = hovering;
    if (hovering) {
      _showSubmenu();
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isHovering && !_isSubmenuHovering) {
          _removeOverlay();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        child: InkWell(
          onTap: () {
            // Also show submenu on tap
            _showSubmenu();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: widget.themeColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.l10n.debugMenu,
                    style: TextStyle(
                      color: widget.themeColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_right,
                  color: widget.themeColors.secondaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
