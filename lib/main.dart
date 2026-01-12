import 'dart:async';
import 'dart:io';
import 'dart:math';
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
import 'models/todo_item.dart';
import 'services/game_data_service.dart';
import 'services/input_monitor_service.dart';
import 'services/pomodoro_service.dart';
import 'widgets/accessibility_dialog.dart';
import 'widgets/home_page_content.dart';
import 'widgets/pomodoro_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/stats_window.dart';
import 'widgets/todo_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

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

  final windowOptions = WindowOptions(
    size: Size(windowWidth, windowHeight),
    center: true,
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

  AppThemeColors get _themeColors => AppThemeColors.fromMode(_themeMode);

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    _initializeFromGameData();
    _initTray();
  }

  void _initializeFromGameData() {
    final data = widget.initialGameData;
    if (data != null) {
      if (data.language != null) {
        _locale = Locale(data.language!);
      }
      _themeMode = data.themeMode;
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    String iconPath = 'assets/images/tray_icon.png';
    if (Platform.isMacOS) {
      iconPath = await _extractAsset(iconPath);
    }
    await trayManager.setIcon(iconPath);

    final menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Show Window'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
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
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        windowManager.focus();
      case 'exit_app':
        windowManager.close();
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
        onLanguageChanged: (lang) {
          setState(() => _locale = lang != null ? Locale(lang) : null);
        },
        onThemeModeChanged: (mode) {
          setState(() => _themeMode = mode);
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final GameData? initialGameData;
  final AppThemeMode themeMode;
  final AppThemeColors themeColors;
  final ValueChanged<String?>? onLanguageChanged;
  final ValueChanged<AppThemeMode>? onThemeModeChanged;

  const MyHomePage({
    super.key,
    this.initialGameData,
    required this.themeMode,
    required this.themeColors,
    this.onLanguageChanged,
    this.onThemeModeChanged,
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
  late AppThemeMode _themeMode;

  // EXP System
  int _level = AppConstants.initialLevel;
  double _currentExp = 0;
  double _maxExp = AppConstants.initialMaxExp;
  String? _userId;
  double _windowWidth = AppConstants.defaultWindowWidth;
  double _windowHeight = AppConstants.defaultWindowHeight;
  String? _language;

  // Todos
  List<TodoItem> _todos = [];

  // Stats
  DailyStats _todayStats = DailyStats();
  Map<String, DailyStats> _dailyStatsMap = {};

  // Services
  final GameDataService _gameDataService = GameDataService();
  late final PomodoroService _pomodoroService;
  late final InputMonitorService _inputMonitorService;
  Timer? _saveDebounce;

  AppThemeColors get _themeColors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    _themeMode = widget.themeMode;

    _initializeServices();

    if (widget.initialGameData != null) {
      _applyGameData(widget.initialGameData!);
    } else {
      _loadGameData();
    }

    _checkAccessibilityPermission();
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
  }

  void _onPomodoroStateChanged() {
    if (mounted) setState(() {});
  }

  void _onInputMonitorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pomodoroService.removeListener(_onPomodoroStateChanged);
    _pomodoroService.dispose();
    _inputMonitorService.removeListener(_onInputMonitorChanged);
    _inputMonitorService.dispose();
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
    windowManager.getSize().then((size) {
      windowManager.setAspectRatio(AppConstants.windowAspectRatio);
      if (mounted) {
        _windowWidth = size.width;
        _windowHeight = size.height;
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
      _userId = data.userId;
      _language = data.language;
      _themeMode = data.themeMode;
      _windowWidth = data.windowWidth ?? AppConstants.defaultWindowWidth;
      _windowHeight = data.windowHeight ?? AppConstants.defaultWindowHeight;
      _todos = List.from(data.todos);

      _dailyStatsMap = Map.of(data.dailyStats);
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayStats = _dailyStatsMap[todayKey] ?? DailyStats();
      _dailyStatsMap[todayKey] = _todayStats;

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
    windowManager.setAlwaysOnTop(_isAlwaysOnTop);
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
          windowWidth: _windowWidth,
          windowHeight: _windowHeight,
          userId: _userId,
          language: _language,
          themeMode: _themeMode,
          dailyStats: _dailyStatsMap,
          todos: _todos,
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
    _saveGameData();
  }

  void _updateStats({
    int keyboardCount = 0,
    int clickCount = 0,
    double moveDistance = 0,
  }) {
    if (!mounted) return;
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
        initialDuration: AppConstants.defaultPomodoroDuration,
        initialRelax: AppConstants.defaultRelaxDuration,
        initialLoops: AppConstants.defaultPomodoroLoops,
        themeColors: _themeColors,
        onStart: (duration, relax, loops) {
          Navigator.of(context).pop();
          _pomodoroService.start(
            workMinutes: duration,
            relaxMinutes: relax,
            loops: loops,
          );
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
      ),
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
        currentLanguage: _language,
        themeMode: _themeMode,
        themeColors: _themeColors,
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
      ),
    );
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

  void _showContextMenu(Offset position) async {
    setState(() => _isMenuOpen = true);
    final l10n = AppLocalizations.of(context)!;

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
      items: [
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
          value: AppConstants.exitGameValue,
          label: l10n.exitGameText,
          isDestructive: true,
        ),
      ],
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
          Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? _themeColors.error
                  : _themeColors.primaryText,
              fontWeight: FontWeight.bold,
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
      case AppConstants.exitGameValue:
        windowManager.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mouseData = _inputMonitorService.mouseData;

    return Scaffold(
      backgroundColor: AppConstants.transparentColor,
      body: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (event) => _handleMouseExit(event),
        child: HomePageContent(
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
          pomodoroState: _pomodoroService.state,
          todos: _todos,
          themeColors: _themeColors,
          onPomodoroPressed: _showPomodoroDialog,
          onStatsPressed: _showStatsWindow,
          onTodoPressed: _showTodoDialog,
          onSettingsPressed: _showSettingsDialog,
          onContextMenu: _showContextMenu,
        ),
      ),
    );
  }

  void _handleMouseExit(PointerExitEvent event) {
    setState(() => _isHovering = false);
    if (_isMenuOpen) {
      final windowSize = MediaQuery.of(context).size;
      final windowRect = Rect.fromLTWH(
        0,
        0,
        windowSize.width,
        windowSize.height,
      );
      final safeRect = windowRect.inflate(10.0);
      if (!safeRect.contains(event.position)) {
        Navigator.of(context).pop();
      }
    }
  }
}
