import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setMinimumSize(const Size(200, 200));
    await windowManager.setMaximumSize(const Size(800, 800));
    await windowManager.setAspectRatio(1.0); // Set aspect ratio to 1:1 (square)
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
      windowManager.setAspectRatio(1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyber Cultivation',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        canvasColor: Colors.transparent,
      ),
      color: Colors.transparent,
      home: const MyHomePage(title: 'Cyber Cultivation'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  String _currentKey = 'Press any key...';
  double _mouseX = 0;
  double _mouseY = 0;
  double _screenWidth = 1;
  double _screenHeight = 1;
  bool _isHovering = false;
  bool _isAlwaysOnTop = false;
  bool _isMenuOpen = false;

  static const EventChannel _eventChannel = EventChannel(
    'com.lichen63.cyber_cultivation/key_events',
  );
  static const EventChannel _mouseEventChannel = EventChannel(
    'com.lichen63.cyber_cultivation/mouse_events',
  );

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateWindowBounds();
    _setupKeyboardListener();
    _setupMouseListener();
  }

  void _setupKeyboardListener() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          setState(() {
            _currentKey = event;
          });
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

          if (mounted && _windowBounds != null && _isMenuOpen) {
            if (!_windowBounds!.contains(Offset(absX, absY))) {
              Navigator.of(context).pop();
            }
          }

          if (mounted) {
            setState(() {
              // Calculate relative position in Dart
              _mouseX = absX - screenMinX;
              _mouseY = absY - screenMinY;

              // Update current screen dimensions
              _screenWidth = (event['screenWidth'] as num?)?.toDouble() ?? 1;
              _screenHeight = (event['screenHeight'] as num?)?.toDouble() ?? 1;
            });
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
      color: Colors.black.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'toggleAlwaysOnTop',
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child:
                    _isAlwaysOnTop
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
              const SizedBox(width: 8),
              const Text(
                'Force Foreground',
                style: TextStyle(
                  color: Colors.white,
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

    if (result == 'toggleAlwaysOnTop') {
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
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Rect? _windowBounds;

  @override
  void onWindowMove() {
    _updateWindowBounds();
  }

  @override
  void onWindowResize() {
    _updateWindowBounds();
  }

  void _updateWindowBounds() async {
    final bounds = await windowManager.getBounds();
    if (mounted) {
      setState(() {
        _windowBounds = bounds;
      });
    }
  }

  Widget _buildStyledButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
          child: Stack(
            children: [
              DragToMoveArea(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 6.0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate scale based on a reference width (e.g., 400.0)
                              final double scale = constraints.maxWidth / 400.0;

                              return Stack(
                                children: [
                                  // Character image centered and larger
                                  Center(
                                    child: Image.asset(
                                      'assets/images/character.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Keyboard label overlaid on top-left
                                  Positioned(
                                    top: 40 * scale,
                                    left: 0,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          _currentKey,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Mouse visualization overlaid on top-right
                                  Positioned(
                                    top: 40 * scale,
                                    right: 0,
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.black.withValues(alpha: 0.3),
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            // Calculate the position of the red dot relative to the container
                                            // Use actual screen dimensions from native side
                                            final dotX =
                                                (_mouseX / _screenWidth) *
                                                constraints.maxWidth;
                                            final dotY =
                                                (_mouseY / _screenHeight) *
                                                constraints.maxHeight;
                                            return Stack(
                                              children: [
                                                // Red dot representing mouse position
                                                Positioned(
                                                  left:
                                                      dotX.clamp(
                                                        0,
                                                        constraints.maxWidth,
                                                      ) -
                                                      5,
                                                  top:
                                                      dotY.clamp(
                                                        0,
                                                        constraints.maxHeight,
                                                      ) -
                                                      5,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
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
                      _buildStyledButton('T-1', () {}),
                      const SizedBox(width: 10),
                      _buildStyledButton('T-2', () {}),
                      const SizedBox(width: 10),
                      _buildStyledButton('T-3', () {}),
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
                      _buildStyledButton('B-1', () {}),
                      const SizedBox(width: 10),
                      _buildStyledButton('B-2', () {}),
                      const SizedBox(width: 10),
                      _buildStyledButton('B-3', () {}),
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
