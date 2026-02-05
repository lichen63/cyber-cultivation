import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

/// Data class for mouse position and screen info
class MousePositionData {
  final double mouseX;
  final double mouseY;
  final double screenWidth;
  final double screenHeight;
  final bool isClicking;

  const MousePositionData({
    this.mouseX = 0,
    this.mouseY = 0,
    this.screenWidth = 1,
    this.screenHeight = 1,
    this.isClicking = false,
  });

  MousePositionData copyWith({
    double? mouseX,
    double? mouseY,
    double? screenWidth,
    double? screenHeight,
    bool? isClicking,
  }) {
    return MousePositionData(
      mouseX: mouseX ?? this.mouseX,
      mouseY: mouseY ?? this.mouseY,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      isClicking: isClicking ?? this.isClicking,
    );
  }
}

/// Service that handles keyboard and mouse input monitoring
class InputMonitorService extends ChangeNotifier {
  static const EventChannel _keyEventChannel = EventChannel(
    AppConstants.keyEventsChannel,
  );
  static const EventChannel _mouseEventChannel = EventChannel(
    AppConstants.mouseEventsChannel,
  );
  static const MethodChannel _mouseControlChannel = MethodChannel(
    AppConstants.mouseControlChannel,
  );

  StreamSubscription<dynamic>? _keySubscription;
  StreamSubscription<dynamic>? _mouseSubscription;
  Timer? _idleCheckTimer;
  Timer? _clickResetTimer;

  String _currentKey = AppConstants.defaultKeyText;
  MousePositionData _mouseData = const MousePositionData();
  DateTime _lastMouseMoveTime = DateTime.now();
  double? _lastAbsX;
  double? _lastAbsY;
  bool _moveToggle = false;
  bool _enableAntiSleep = false;
  double _accumulatedMoveDistance = 0.0;

  /// Callbacks for exp and stats updates
  final void Function(double amount)? onExpGain;
  final void Function({int keyboardCount, int clickCount, double moveDistance})?
  onStatsUpdate;

  InputMonitorService({this.onExpGain, this.onStatsUpdate});

  String get currentKey => _currentKey;
  MousePositionData get mouseData => _mouseData;
  bool get enableAntiSleep => _enableAntiSleep;

  set enableAntiSleep(bool value) {
    _enableAntiSleep = value;
    notifyListeners();
  }

  /// Initialize input listeners
  void initialize() {
    _setupKeyboardListener();
    _setupMouseListener();
    _startIdleCheck();
  }

  void _setupKeyboardListener() {
    _keySubscription = _keyEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          _currentKey = event;
          notifyListeners();
          onExpGain?.call(AppConstants.expGainPerKey);
          onStatsUpdate?.call(keyboardCount: 1, clickCount: 0, moveDistance: 0);
        }
      },
      onError: (dynamic error) {
        debugPrint('Keyboard event error: ${error.message}');
      },
    );
  }

  void _setupMouseListener() {
    _mouseSubscription = _mouseEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        _lastMouseMoveTime = DateTime.now();

        if (event is Map) {
          final absX = (event['x'] as num?)?.toDouble() ?? 0;
          final absY = (event['y'] as num?)?.toDouble() ?? 0;
          final screenMinX = (event['screenMinX'] as num?)?.toDouble() ?? 0;
          final screenMinY = (event['screenMinY'] as num?)?.toDouble() ?? 0;
          final type = event['type'] as String? ?? 'move';

          if (type == 'click') {
            _handleClick();
          } else {
            _handleMove(absX, absY, screenMinX, screenMinY, event);
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('Mouse event error: ${error.message}');
      },
    );
  }

  void _handleClick() {
    onExpGain?.call(AppConstants.expGainPerMouse);
    onStatsUpdate?.call(keyboardCount: 0, clickCount: 1, moveDistance: 0);

    _mouseData = _mouseData.copyWith(isClicking: true);
    notifyListeners();

    _clickResetTimer?.cancel();
    _clickResetTimer = Timer(
      const Duration(milliseconds: AppConstants.mouseClickBlinkDurationMs),
      () {
        _mouseData = _mouseData.copyWith(isClicking: false);
        notifyListeners();
      },
    );
  }

  void _handleMove(
    double absX,
    double absY,
    double screenMinX,
    double screenMinY,
    Map<dynamic, dynamic> event,
  ) {
    if (_lastAbsX != null && _lastAbsY != null) {
      final dx = absX - _lastAbsX!;
      final dy = absY - _lastAbsY!;
      final distance = sqrt(dx * dx + dy * dy);
      onStatsUpdate?.call(
        keyboardCount: 0,
        clickCount: 0,
        moveDistance: distance,
      );

      // Accumulate distance and grant exp when threshold is reached
      _accumulatedMoveDistance += distance;
      if (_accumulatedMoveDistance >= AppConstants.mouseDistancePerExp) {
        final expToGrant =
            (_accumulatedMoveDistance / AppConstants.mouseDistancePerExp)
                .floor();
        _accumulatedMoveDistance %=
            AppConstants.mouseDistancePerExp; // Keep remainder
        onExpGain?.call(expToGrant * AppConstants.expGainPerMouse);
      }
    }
    _lastAbsX = absX;
    _lastAbsY = absY;

    _mouseData = MousePositionData(
      mouseX: absX - screenMinX,
      mouseY: absY - screenMinY,
      screenWidth: (event['screenWidth'] as num?)?.toDouble() ?? 1,
      screenHeight: (event['screenHeight'] as num?)?.toDouble() ?? 1,
      isClicking: _mouseData.isClicking,
    );
    notifyListeners();
  }

  void _startIdleCheck() {
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_enableAntiSleep) return;

      final diff = DateTime.now().difference(_lastMouseMoveTime);
      if (diff.inSeconds >= AppConstants.antiSleepIdleIntervalSeconds) {
        _performMouseMove();
      }
    });
  }

  Future<void> _performMouseMove() async {
    try {
      _moveToggle = !_moveToggle;
      final double offset = _moveToggle ? 1.0 : -1.0;

      await _mouseControlChannel.invokeMethod('moveMouse', {
        'dx': offset,
        'dy': offset,
      });
      // Update the last mouse move time to prevent immediate re-triggering
      // This is needed because the synthetic move event may not be captured
      // by the event stream, or there could be a race condition
      _lastMouseMoveTime = DateTime.now();
    } catch (e) {
      debugPrint("Failed to move mouse via channel: $e");
    }
  }

  @override
  void dispose() {
    _keySubscription?.cancel();
    _mouseSubscription?.cancel();
    _idleCheckTimer?.cancel();
    _clickResetTimer?.cancel();
    super.dispose();
  }
}
