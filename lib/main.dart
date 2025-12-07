import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  String _currentKey = 'Press any key...';

  @override
  void initState() {
    super.initState();
    _setupGlobalKeyboardListener();
  }

  Future<void> _setupGlobalKeyboardListener() async {
    // Register a global hotkey listener for all keys
    await hotKeyManager.unregisterAll();
    
    // Listen to common keys - you can extend this list
    final keysToMonitor = [
      LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, 
      LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyE, LogicalKeyboardKey.keyF, 
      LogicalKeyboardKey.keyG, LogicalKeyboardKey.keyH, LogicalKeyboardKey.keyI, 
      LogicalKeyboardKey.keyJ, LogicalKeyboardKey.keyK, LogicalKeyboardKey.keyL, 
      LogicalKeyboardKey.keyM, LogicalKeyboardKey.keyN, LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyP, LogicalKeyboardKey.keyQ, LogicalKeyboardKey.keyR, 
      LogicalKeyboardKey.keyS, LogicalKeyboardKey.keyT, LogicalKeyboardKey.keyU, 
      LogicalKeyboardKey.keyV, LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyX, 
      LogicalKeyboardKey.keyY, LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, 
      LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, 
      LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8, 
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.space, LogicalKeyboardKey.enter, LogicalKeyboardKey.escape, 
      LogicalKeyboardKey.backspace, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowDown, 
      LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight,
    ];

    for (var key in keysToMonitor) {
      final hotKey = HotKey(
        key: key,
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (hotKey) {
          setState(() {
            _currentKey = _formatKeyboardKey(hotKey.key);
          });
        },
      );
    }
  }

  String _formatKeyboardKey(KeyboardKey key) {
    if (key is LogicalKeyboardKey) {
      final label = key.keyLabel;
      return label.isEmpty ? 'Key' : label.toUpperCase();
    } else if (key is PhysicalKeyboardKey) {
      return key.debugName ?? 'Key';
    }
    return 'Unknown';
  }

  @override
  void dispose() {
    hotKeyManager.unregisterAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DragToMoveArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 6.0),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Stack(
              children: [
                Center(child: Image.asset('assets/images/character.png')),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        _currentKey,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
