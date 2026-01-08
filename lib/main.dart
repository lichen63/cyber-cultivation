import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'models/game_data.dart';
import 'services/game_data_service.dart';
import 'widgets/character_display.dart';
import 'widgets/exp_display.dart';
import 'widgets/keyboard_monitor.dart';
import 'widgets/mouse_monitor.dart';
import 'widgets/styled_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

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

  final double windowWidth = gameData.windowWidth ?? AppConstants.defaultWindowWidth;
  final double windowHeight = gameData.windowHeight ?? AppConstants.defaultWindowHeight;

  WindowOptions windowOptions = WindowOptions(
    size: Size(windowWidth, windowHeight),
    center: true,
    backgroundColor: AppConstants.transparentColor,
    skipTaskbar: false,
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

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
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
      theme: ThemeData(
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: AppConstants.transparentColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primarySeedColor),
        canvasColor: AppConstants.transparentColor,
      ),
      color: AppConstants.transparentColor,
      home: MyHomePage(initialGameData: widget.initialGameData),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final GameData? initialGameData;
  const MyHomePage({super.key, this.initialGameData});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener, WidgetsBindingObserver {
  String _currentKey = AppConstants.defaultKeyText;
  double _mouseX = 0;
  double _mouseY = 0;
  double _screenWidth = 1;
  double _screenHeight = 1;
  bool _isHovering = false;
  bool _isAlwaysOnTop = true;
  bool _isMenuOpen = false;

  // EXP System
  int _level = AppConstants.initialLevel;
  double _currentExp = 0;
  double _maxExp = AppConstants.initialMaxExp;
  String? _userId;
  double _windowWidth = AppConstants.defaultWindowWidth;
  double _windowHeight = AppConstants.defaultWindowHeight;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    
    if (widget.initialGameData != null) {
      _applyGameData(widget.initialGameData!);
    } else {
      _loadGameData();
    }
    
    _setupKeyboardListener();
    _setupMouseListener();
    _startIdleCheck();
  }

  @override
  void dispose() {
    _idleCheckTimer?.cancel();
    _scheduledMoveTimer?.cancel();
    _saveGameData(immediate: true);
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
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
        _saveDebounce = Timer(const Duration(seconds: 1), () => _saveGameData());
      }
    });
  }

  void _applyGameData(GameData data) {
    if (!mounted) return;
    setState(() {
      _level = data.level;
      _isAlwaysOnTop = data.isAlwaysOnTop;
      _enableAntiSleep = data.isAntiSleepEnabled;
      _userId = data.userId;
      _windowWidth = data.windowWidth ?? AppConstants.defaultWindowWidth;
      _windowHeight = data.windowHeight ?? AppConstants.defaultWindowHeight;

      if (_level >= AppConstants.maxLevel) {
        _currentExp = double.infinity;
        _maxExp = double.infinity;
      } else {
        _currentExp = data.currentExp;
        // Recalculate max exp based on level
        _maxExp = AppConstants.initialMaxExp * pow(AppConstants.expGrowthFactor, _level - 1);
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
    
    if (immediate) {
      _gameDataService.saveGameData(GameData(
        level: _level,
        currentExp: _currentExp,
        isAlwaysOnTop: _isAlwaysOnTop,
        isAntiSleepEnabled: _enableAntiSleep,
        windowWidth: _windowWidth,
        windowHeight: _windowHeight,
        userId: _userId,
      ));
    } else {
      _saveDebounce = Timer(const Duration(seconds: 1), () {
        _gameDataService.saveGameData(GameData(
          level: _level,
          currentExp: _currentExp,
          isAlwaysOnTop: _isAlwaysOnTop,
          isAntiSleepEnabled: _enableAntiSleep,
          windowWidth: _windowWidth,
          windowHeight: _windowHeight,
          userId: _userId,
        ));
      });
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

  void _setupKeyboardListener() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          setState(() {
            _currentKey = event;
          });
          _gainExp(AppConstants.expGainPerKey);
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

          if (mounted) {
            setState(() {
              // Calculate relative position in Dart
              _mouseX = absX - screenMinX;
              _mouseY = absY - screenMinY;

              // Update current screen dimensions
              _screenWidth = (event['screenWidth'] as num?)?.toDouble() ?? 1;
              _screenHeight = (event['screenHeight'] as num?)?.toDouble() ?? 1;
            });
            _gainExp(AppConstants.expGainPerMouse);
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
    final result = await showMenu(
      context: context,
      color: AppConstants.blackOverlayColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        side: const BorderSide(color: AppConstants.whiteColor, width: 2),
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
                child:
                    _isAlwaysOnTop
                        ? const Icon(Icons.check, color: AppConstants.whiteColor, size: 18)
                        : null,
              ),
              const SizedBox(width: 8),
              const Text(
                AppConstants.forceForegroundText,
                style: TextStyle(
                  color: AppConstants.whiteColor,
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
                    ? const Icon(Icons.check, color: AppConstants.whiteColor, size: 18)
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                AppConstants.antiSleepText,
                style: TextStyle(
                  color: AppConstants.whiteColor,
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
    }
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
          onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
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
                          color: AppConstants.whiteColor,
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
                                          ),
                                          SizedBox(height: 10 * scale),
                                          const Expanded(
                                            child: CharacterDisplay(),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 80 * scale,
                                        left: 0,
                                        child: KeyboardMonitor(
                                          currentKey: _currentKey,
                                          scale: scale,
                                        ),
                                      ),
                                      Positioned(
                                        top: 80 * scale,
                                        right: 0,
                                        child: MouseMonitor(
                                          mouseX: _mouseX,
                                          mouseY: _mouseY,
                                          screenWidth: _screenWidth,
                                          screenHeight: _screenHeight,
                                          scale: scale,
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
                  if (_isHovering) ...[
                    Positioned(
                      top: 10 * windowScale,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StyledButton(
                            text: 'T-1',
                            onPressed: () {},
                            scale: windowScale,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: 'T-2',
                            onPressed: () {},
                            scale: windowScale,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: 'T-3',
                            onPressed: () {},
                            scale: windowScale,
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
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: 'B-2',
                            onPressed: () {},
                            scale: windowScale,
                          ),
                          SizedBox(width: 10 * windowScale),
                          StyledButton(
                            text: 'B-3',
                            onPressed: () {},
                            scale: windowScale,
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
