import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'constants.dart';
import 'widgets/character_display.dart';
import 'widgets/exp_display.dart';
import 'widgets/keyboard_monitor.dart';
import 'widgets/mouse_monitor.dart';
import 'widgets/styled_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
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
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
        scaffoldBackgroundColor: AppConstants.transparentColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primarySeedColor),
        canvasColor: AppConstants.transparentColor,
      ),
      color: AppConstants.transparentColor,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  String _currentKey = AppConstants.defaultKeyText;
  double _mouseX = 0;
  double _mouseY = 0;
  double _screenWidth = 1;
  double _screenHeight = 1;
  bool _isHovering = false;
  bool _isAlwaysOnTop = false;
  bool _isMenuOpen = false;

  // EXP System
  int _level = AppConstants.initialLevel;
  double _currentExp = 0;
  double _maxExp = AppConstants.initialMaxExp;

  static const EventChannel _eventChannel = EventChannel(
    AppConstants.keyEventsChannel,
  );
  static const EventChannel _mouseEventChannel = EventChannel(
    AppConstants.mouseEventsChannel,
  );

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _setupKeyboardListener();
    _setupMouseListener();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    windowManager.getSize().then((size) {
      windowManager.setAspectRatio(AppConstants.windowAspectRatio);
    });
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
        _currentExp = _maxExp;
      }
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
      ],
    );

    if (mounted) {
      setState(() {
        _isMenuOpen = false;
      });
    }

    if (result == AppConstants.toggleAlwaysOnTopValue) {
      _toggleAlwaysOnTop(!_isAlwaysOnTop);
    }
  }

  void _toggleAlwaysOnTop(bool value) async {
    setState(() {
      _isAlwaysOnTop = value;
    });
    await windowManager.setAlwaysOnTop(value);
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
          child: Stack(
            children: [
              DragToMoveArea(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppConstants.whiteColor,
                      width: AppConstants.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate scale based on a reference width
                              final double scale = constraints.maxWidth / AppConstants.defaultWindowWidth;

                              return Stack(
                                children: [
                                  Column(
                                    children: [
                                      SizedBox(height: 30 * scale),
                                      ExpDisplay(
                                        level: _level,
                                        currentExp: _currentExp,
                                        maxExp: _maxExp,
                                        scale: scale,
                                      ),
                                      SizedBox(height: 10 * scale),
                                      const Expanded(child: CharacterDisplay()),
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
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StyledButton(text: 'T-1', onPressed: () {}),
                      const SizedBox(width: 10),
                      StyledButton(text: 'T-2', onPressed: () {}),
                      const SizedBox(width: 10),
                      StyledButton(text: 'T-3', onPressed: () {}),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StyledButton(text: 'B-1', onPressed: () {}),
                      const SizedBox(width: 10),
                      StyledButton(text: 'B-2', onPressed: () {}),
                      const SizedBox(width: 10),
                      StyledButton(text: 'B-3', onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
