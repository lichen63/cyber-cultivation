import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'constants.dart';
import 'models/game_data.dart';
import 'package:intl/intl.dart';
import 'models/daily_stats.dart';
import 'services/game_data_service.dart';
import 'widgets/stats_window.dart';
import 'widgets/character_display.dart';
import 'widgets/exp_display.dart';
import 'widgets/keyboard_monitor.dart';
import 'widgets/mouse_monitor.dart';
import 'widgets/pomodoro_dialog.dart';
import 'widgets/styled_button.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/cultivation_formation.dart';
import 'widgets/accessibility_dialog.dart';
import 'widgets/system_stats_panel.dart';
import 'widgets/todo_dialog.dart';
import 'models/todo_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Initialize launch at startup
  launchAtStartup.setup(
    appName: AppConstants.appTitle,
    appPath: Platform.resolvedExecutable,
  );

  final gameDataService = GameDataService();
  var gameData = await gameDataService.loadGameData();
  bool needSave = false;

  // Generate User ID if missing
  if (gameData == null || gameData.userId == null) {
    final userId = await gameDataService.generateUserId();
    if (gameData == null) {
      gameData = GameData(
        level: AppConstants.initialLevel,
        currentExp: 0,
        userId: userId,
      );
    } else {
      gameData = gameData.copyWith(userId: userId);
    }
    needSave = true;
  }

  // Initial save to ensure ID is persisted
  if (needSave) {
    await gameDataService.saveGameData(gameData);
  }

  final double windowWidth =
      gameData.windowWidth ?? AppConstants.defaultWindowWidth;
  final double windowHeight =
      gameData.windowHeight ?? AppConstants.defaultWindowHeight;

  WindowOptions windowOptions = WindowOptions(
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
    if (widget.initialGameData?.language != null) {
      _locale = Locale(widget.initialGameData!.language!);
    }
    if (widget.initialGameData != null) {
      _themeMode = widget.initialGameData!.themeMode;
    }
    _initTray();
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

    Menu menu = Menu(
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

    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    return file.path;
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.close();
    }
  }

  @override
  void onWindowResize() {
    // Maintain aspect ratio during resize
    windowManager.getSize().then((size) {
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
          setState(() {
            _locale = lang != null ? Locale(lang) : null;
          });
        },
        onThemeModeChanged: (mode) {
          setState(() {
            _themeMode = mode;
          });
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
  String _currentKey = AppConstants.defaultKeyText;
  double _mouseX = 0;
  double _mouseY = 0;
  double _screenWidth = 1;
  double _screenHeight = 1;
  bool _isHovering = false;
  bool _isAlwaysOnTop = true;
  bool _isMenuOpen = false;
  bool _isAlwaysShowActionButtons = false;
  bool _isAutoStartEnabled = false;
  late AppThemeMode _themeMode;

  AppThemeColors get _themeColors => widget.themeColors;

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
  double? _lastAbsX;
  double? _lastAbsY;

  final GameDataService _gameDataService = GameDataService();
  Timer? _saveDebounce;

  static const EventChannel _eventChannel = EventChannel(
    AppConstants.keyEventsChannel,
  );
  static const EventChannel _mouseEventChannel = EventChannel(
    AppConstants.mouseEventsChannel,
  );
  static const MethodChannel _mouseControlChannel = MethodChannel(
    AppConstants.mouseControlChannel,
  );

  Timer? _idleCheckTimer;
  Timer? _scheduledMoveTimer;
  DateTime _lastMouseMoveTime = DateTime.now();
  // Toggle for the anti-sleep feature
  bool _enableAntiSleep = false;
  // Toggle moving direction to prevent cursor drift
  bool _moveToggle = false;

  // Pomodoro
  Timer? _pomodoroTimer;
  int _pomodoroSecondsRemaining = 0;
  bool _isPomodoroActive = false;
  // New Pomodoro State
  int _pomodoroTotalLoops = 1;
  int _pomodoroCurrentLoop = 1;
  int _pomodoroWorkDurationMinutes = 25;
  int _pomodoroRelaxDurationMinutes = 5;
  bool _isPomodoroRelaxing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    _themeMode = widget.themeMode;

    if (widget.initialGameData != null) {
      _applyGameData(widget.initialGameData!);
    } else {
      _loadGameData();
    }

    _setupKeyboardListener();
    _setupMouseListener();
    _startIdleCheck();
    _checkAccessibilityPermission();
  }

  /// Checks accessibility permission and shows dialog if not granted.
  Future<void> _checkAccessibilityPermission() async {
    final isGranted = await AccessibilityService.checkAccessibility();
    if (!isGranted && mounted) {
      // Wait for the widget to be fully built before showing dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AccessibilityDialog.show(context: context, themeColors: _themeColors);
        }
      });
    }
  }

  @override
  void dispose() {
    _idleCheckTimer?.cancel();
    _scheduledMoveTimer?.cancel();
    _pomodoroTimer?.cancel();
    _saveGameData(immediate: true);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
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
        if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();
        _saveDebounce = Timer(
          const Duration(seconds: 1),
          () => _saveGameData(),
        );
      }
    });
  }

  void _applyGameData(GameData data) {
    if (!mounted) return;
    setState(() {
      _level = data.level;
      _isAlwaysOnTop = data.isAlwaysOnTop;
      _enableAntiSleep = data.isAntiSleepEnabled;
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
      if (_dailyStatsMap.containsKey(todayKey)) {
        _todayStats = _dailyStatsMap[todayKey]!;
      } else {
        _todayStats = DailyStats();
        _dailyStatsMap[todayKey] = _todayStats;
      }

      if (_level >= AppConstants.maxLevel) {
        _currentExp = double.infinity;
        _maxExp = double.infinity;
      } else {
        _currentExp = data.currentExp;
        // Recalculate max exp based on level
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
      // If no data found, ensure default is applied
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    }
  }

  void _saveGameData({bool immediate = false}) {
    if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();

    Future<void> save() async {
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dailyStatsMap[todayKey] = _todayStats;

      await _gameDataService.saveGameData(
        GameData(
          level: _level,
          currentExp: _currentExp,
          isAlwaysOnTop: _isAlwaysOnTop,
          isAntiSleepEnabled: _enableAntiSleep,
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

  void _showPomodoroDialog() {
    if (_isPomodoroActive) {
      _confirmStopPomodoro();
      return;
    }

    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (BuildContext context) {
        return PomodoroDialog(
          initialDuration: AppConstants.defaultPomodoroDuration,
          initialRelax: AppConstants.defaultRelaxDuration,
          initialLoops: AppConstants.defaultPomodoroLoops,
          themeColors: _themeColors,
          onStart: (duration, relax, loops) {
            Navigator.of(context).pop();
            _startPomodoro(
              workMinutes: duration,
              relaxMinutes: relax,
              loops: loops,
            );
          },
        );
      },
    );
  }

  void _confirmStopPomodoro() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (BuildContext context) {
        return AlertDialog(
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
                _cancelPomodoro();
              },
              child: Text(
                l10n.stopButtonText,
                style: TextStyle(color: _themeColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startPomodoro({
    required int workMinutes,
    required int relaxMinutes,
    required int loops,
  }) {
    if (_isPomodoroActive) return;

    setState(() {
      _isPomodoroActive = true;
      _pomodoroWorkDurationMinutes = workMinutes;
      _pomodoroRelaxDurationMinutes = relaxMinutes;
      _pomodoroTotalLoops = loops;
      _pomodoroCurrentLoop = 1;
      _isPomodoroRelaxing = false;
      _pomodoroSecondsRemaining = workMinutes * 60;
    });

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        _cancelPomodoro();
        return;
      }
      setState(() {
        if (_pomodoroSecondsRemaining > 0) {
          _pomodoroSecondsRemaining--;
        } else {
          // Timer finished
          if (_isPomodoroRelaxing) {
            // Finished Relaxing, start next Work loop
            _isPomodoroRelaxing = false;
            _pomodoroCurrentLoop++;
            if (_pomodoroCurrentLoop > _pomodoroTotalLoops) {
              // Should not happen if logic is correct, but safety catch
              _cancelPomodoro();
            } else {
              _pomodoroSecondsRemaining = _pomodoroWorkDurationMinutes * 60;
            }
          } else {
            // Finished Working
            _gainExp(
              AppConstants.expGainPerMinute * _pomodoroWorkDurationMinutes,
            );

            if (_pomodoroCurrentLoop >= _pomodoroTotalLoops) {
              // All work done
              _cancelPomodoro();
            } else {
              // Start Relax
              _isPomodoroRelaxing = true;
              _pomodoroSecondsRemaining = _pomodoroRelaxDurationMinutes * 60;
            }
          }
        }
      });
    });
  }

  void _cancelPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    setState(() {
      _isPomodoroActive = false;
      _pomodoroSecondsRemaining = 0;
      _isPomodoroRelaxing = false;
      _pomodoroCurrentLoop = 1;
    });
  }

  void _showStatsWindow() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) {
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final viewHistory = Map<String, DailyStats>.from(_dailyStatsMap);
        viewHistory[todayKey] = _todayStats;

        return StatsWindow(
          todayStats: _todayStats,
          historyStats: viewHistory,
          themeColors: _themeColors,
        );
      },
    );
  }

  void _showTodoDialog() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) {
        return TodoDialog(
          todos: _todos,
          themeColors: _themeColors,
          onTodosChanged: (updatedTodos) {
            setState(() {
              _todos = updatedTodos;
            });
            _saveGameData(immediate: true);
          },
        );
      },
    );
  }

  void _updateStats({
    int keyboardCount = 0,
    int clickCount = 0,
    double moveDistance = 0,
  }) {
    // Only update if we are mounted
    if (!mounted) return;

    setState(() {
      _todayStats.keyboardCount += keyboardCount;
      _todayStats.mouseClickCount += clickCount;
      _todayStats.mouseMoveDistance += moveDistance.toInt();
    });
  }

  void _setupKeyboardListener() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          setState(() {
            _currentKey = event;
          });
          _gainExp(AppConstants.expGainPerKey);
          _updateStats(keyboardCount: 1);
        }
      },
      onError: (dynamic error) {
        debugPrint('Received error: ${error.message}');
      },
    );
  }

  void _setupMouseListener() {
    _mouseEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        _lastMouseMoveTime = DateTime.now();
        if (_scheduledMoveTimer?.isActive ?? false) {
          _scheduledMoveTimer!.cancel();
        }

        if (event is Map) {
          final absX = (event['x'] as num?)?.toDouble() ?? 0;
          final absY = (event['y'] as num?)?.toDouble() ?? 0;
          final screenMinX = (event['screenMinX'] as num?)?.toDouble() ?? 0;
          final screenMinY = (event['screenMinY'] as num?)?.toDouble() ?? 0;
          final type = event['type'] as String? ?? 'move';

          if (type == 'click') {
            _gainExp(AppConstants.expGainPerMouse);
            _updateStats(clickCount: 1);
          } else {
            if (_lastAbsX != null && _lastAbsY != null) {
              final dx = absX - _lastAbsX!;
              final dy = absY - _lastAbsY!;
              final distance = sqrt(dx * dx + dy * dy);
              _updateStats(moveDistance: distance);
            }
            _lastAbsX = absX;
            _lastAbsY = absY;

            if (mounted) {
              setState(() {
                // Calculate relative position in Dart
                _mouseX = absX - screenMinX;
                _mouseY = absY - screenMinY;

                // Update current screen dimensions
                _screenWidth = (event['screenWidth'] as num?)?.toDouble() ?? 1;
                _screenHeight =
                    (event['screenHeight'] as num?)?.toDouble() ?? 1;
              });
              _gainExp(AppConstants.expGainPerMouse);
            }
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('Mouse event error: ${error.message}');
      },
    );
  }

  void _startIdleCheck() {
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_enableAntiSleep) return;

      // Calculate how long since the last mouse move
      final diff = DateTime.now().difference(_lastMouseMoveTime);

      // If idle for more than 10 seconds
      if (diff.inSeconds >= 10) {
        _performMouseMove();
      }
    });
  }

  Future<void> _performMouseMove() async {
    try {
      // Toggle move direction to prevent cursor from drifting off-screen over time
      _moveToggle = !_moveToggle;
      final double offset = _moveToggle ? 2.0 : -2.0;

      await _mouseControlChannel.invokeMethod('moveMouse', {
        'dx': offset,
        'dy': offset,
      });
    } catch (e) {
      debugPrint("Failed to move mouse via channel: $e");
    }
  }

  void _showContextMenu(Offset position) async {
    setState(() {
      _isMenuOpen = true;
    });
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
        PopupMenuItem(
          value: AppConstants.toggleAlwaysOnTopValue,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: _isAlwaysOnTop
                    ? Icon(
                        Icons.check,
                        color: _themeColors.primaryText,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.forceForegroundText,
                style: TextStyle(
                  color: _themeColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppConstants.toggleAntiSleepValue,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: _enableAntiSleep
                    ? Icon(
                        Icons.check,
                        color: _themeColors.primaryText,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.antiSleepText,
                style: TextStyle(
                  color: _themeColors.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppConstants.exitGameValue,
          child: Row(
            children: [
              const SizedBox(width: 24), // No checkmark for exit
              const SizedBox(width: 8),
              Text(
                l10n.exitGameText,
                style: TextStyle(
                  color: _themeColors.error, // Use error for destructive action
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (mounted) {
      setState(() {
        _isMenuOpen = false;
      });
    }

    if (result == AppConstants.toggleAlwaysOnTopValue) {
      _toggleAlwaysOnTop(!_isAlwaysOnTop);
    } else if (result == AppConstants.toggleAntiSleepValue) {
      setState(() {
        _enableAntiSleep = !_enableAntiSleep;
      });
      _saveGameData();
    } else if (result == AppConstants.exitGameValue) {
      windowManager.close();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierColor: _themeColors.overlay,
      builder: (context) {
        return SettingsDialog(
          isAlwaysOnTop: _isAlwaysOnTop,
          isAntiSleepEnabled: _enableAntiSleep,
          isAlwaysShowActionButtons: _isAlwaysShowActionButtons,
          isAutoStartEnabled: _isAutoStartEnabled,
          currentLanguage: _language,
          themeMode: _themeMode,
          themeColors: _themeColors,
          onAlwaysOnTopChanged: _toggleAlwaysOnTop,
          onAntiSleepChanged: (value) {
            setState(() {
              _enableAntiSleep = value;
            });
            _saveGameData();
          },
          onAlwaysShowActionButtonsChanged: (value) {
            setState(() {
              _isAlwaysShowActionButtons = value;
            });
            _saveGameData();
          },
          onAutoStartChanged: _toggleAutoStart,
          onLanguageChanged: (value) {
            setState(() {
              _language = value;
            });
            widget.onLanguageChanged?.call(value);
            _saveGameData();
          },
          onThemeModeChanged: (value) {
            setState(() {
              _themeMode = value;
            });
            widget.onThemeModeChanged?.call(value);
            _saveGameData();
          },
        );
      },
    );
  }

  void _toggleAutoStart(bool value) async {
    setState(() {
      _isAutoStartEnabled = value;
    });
    if (value) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    _saveGameData();
  }

  void _toggleAlwaysOnTop(bool value) async {
    setState(() {
      _isAlwaysOnTop = value;
    });
    await windowManager.setAlwaysOnTop(value);
    _saveGameData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppConstants.transparentColor,
      body: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (event) {
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
        },
        child: GestureDetector(
          onSecondaryTapUp: (details) =>
              _showContextMenu(details.globalPosition),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double windowScale =
                  constraints.maxWidth / AppConstants.defaultWindowWidth;
              return Stack(
                children: [
                  DragToMoveArea(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _themeColors.border,
                          width: AppConstants.borderWidth * windowScale,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius * windowScale,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          AppConstants.defaultPadding * windowScale,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate scale based on a reference width
                                  final double scale =
                                      constraints.maxWidth /
                                      AppConstants.defaultWindowWidth;

                                  return Stack(
                                    children: [
                                      Column(
                                        children: [
                                          SizedBox(height: 10 * scale),
                                          ExpDisplay(
                                            level: _level,
                                            currentExp: _currentExp,
                                            maxExp: _maxExp,
                                            scale: scale,
                                            themeColors: _themeColors,
                                          ),
                                          SizedBox(height: 10 * scale),
                                          Expanded(
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                const CharacterDisplay(),
                                                if (_isPomodoroActive)
                                                  CultivationFormation(
                                                    progress:
                                                        _pomodoroSecondsRemaining /
                                                        ((_isPomodoroRelaxing
                                                                ? _pomodoroRelaxDurationMinutes
                                                                : _pomodoroWorkDurationMinutes) *
                                                            60),
                                                    isRelaxing:
                                                        _isPomodoroRelaxing,
                                                    size: 240 * scale,
                                                  ),
                                                // System stats positioned around the character
                                                Positioned(
                                                  top: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: SystemStatsPanel(
                                                    scale: scale,
                                                    themeColors: _themeColors,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 260 * scale,
                                        left: 0,
                                        child: KeyboardMonitor(
                                          currentKey: _currentKey,
                                          scale: scale,
                                          themeColors: _themeColors,
                                        ),
                                      ),
                                      Positioned(
                                        top: 260 * scale,
                                        right: 0,
                                        child: MouseMonitor(
                                          mouseX: _mouseX,
                                          mouseY: _mouseY,
                                          screenWidth: _screenWidth,
                                          screenHeight: _screenHeight,
                                          scale: scale,
                                          themeColors: _themeColors,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isHovering || _isAlwaysShowActionButtons) ...[
                    Positioned(
                      top: 10 * windowScale,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StyledButton(
                            text: _isPomodoroActive
                                ? (_isPomodoroRelaxing
                                      ? '${l10n.relaxState} ${(_pomodoroSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0')}'
                                      : '${l10n.focusState} $_pomodoroCurrentLoop/$_pomodoroTotalLoops  ${(_pomodoroSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0')}')
                                : l10n.focusState,
                            onPressed: _isPomodoroActive
                                ? _confirmStopPomodoro
                                : _showPomodoroDialog,
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: l10n.statsTitle,
                            onPressed: _showStatsWindow,
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: l10n.todoTitle,
                            onPressed: _showTodoDialog,
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10 * windowScale,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StyledButton(
                            text: 'B-1',
                            onPressed: () {},
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: 'B-2',
                            onPressed: () {},
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: l10n.settingsTitle,
                            onPressed: _showSettingsDialog,
                            scale: windowScale,
                            themeColors: _themeColors,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
