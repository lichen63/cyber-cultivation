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

  /// Timestamp of the last *real* user input (keyboard or mouse). Synthetic
  /// anti-sleep nudges are filtered out natively and never update this, so they
  /// cannot keep resetting the idle window on their own.
  DateTime _lastActivityTime = DateTime.now();
  double? _lastAbsX;
  double? _lastAbsY;
  bool _moveToggle = false;
  bool _enableAntiSleep = false;
  double _accumulatedMoveDistance = 0.0;
  bool _disposed = false;

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
    // Start counting the idle window from now so enabling the feature never
    // triggers an immediate nudge based on a stale activity timestamp.
    if (value) {
      _lastActivityTime = DateTime.now();
    }
    notifyListeners();
  }

  /// Initialize input listeners
  void initialize() {
    _setupKeyboardListener();
    _setupMouseListener();
    _startIdleCheck();
  }

  void _setupKeyboardListener() {
    _keySubscription?.cancel();
    _keySubscription = _keyEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          _lastActivityTime = DateTime.now();
          _currentKey = event;
          notifyListeners();
          onExpGain?.call(AppConstants.expGainPerKey);
          onStatsUpdate?.call(keyboardCount: 1, clickCount: 0, moveDistance: 0);
        }
      },
      onError: (dynamic error) {
        debugPrint('Keyboard event error: $error');
      },
      onDone: () {
        debugPrint('Keyboard event stream closed, reconnecting...');
        if (!_disposed) {
          Future.delayed(const Duration(seconds: 2), _setupKeyboardListener);
        }
      },
    );
  }

  void _setupMouseListener() {
    _mouseSubscription?.cancel();
    _mouseSubscription = _mouseEventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          // Any event that reaches Dart is genuine user input: native code
          // tags and filters out the synthetic anti-sleep nudges.
          _lastActivityTime = DateTime.now();

          final absX = (event['x'] as num?)?.toDouble() ?? 0;
          final absY = (event['y'] as num?)?.toDouble() ?? 0;
          final screenMinX = (event['screenMinX'] as num?)?.toDouble() ?? 0;
          final screenMinY = (event['screenMinY'] as num?)?.toDouble() ?? 0;
          final type = event['type'] as String? ?? 'move';

          if (type == 'click') {
            _handleClick(absX, absY, screenMinX, screenMinY, event);
          } else {
            _handleMove(absX, absY, screenMinX, screenMinY, event);
          }
        }
      },
      onError: (dynamic error) {
        debugPrint('Mouse event error: $error');
      },
      onDone: () {
        debugPrint('Mouse event stream closed, reconnecting...');
        if (!_disposed) {
          Future.delayed(const Duration(seconds: 2), _setupMouseListener);
        }
      },
    );
  }

  void _handleClick(
    double absX,
    double absY,
    double screenMinX,
    double screenMinY,
    Map<dynamic, dynamic> event,
  ) {
    onExpGain?.call(AppConstants.expGainPerMouse);
    onStatsUpdate?.call(keyboardCount: 0, clickCount: 1, moveDistance: 0);

    // Update position tracking so next move distance is correct
    _lastAbsX = absX;
    _lastAbsY = absY;

    _mouseData = MousePositionData(
      mouseX: absX - screenMinX,
      mouseY: absY - screenMinY,
      screenWidth: (event['screenWidth'] as num?)?.toDouble() ?? 1,
      screenHeight: (event['screenHeight'] as num?)?.toDouble() ?? 1,
      isClicking: true,
    );
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

  /// Periodically checks how long the user has been idle and, once the idle
  /// threshold is crossed, performs a synthetic mouse nudge to keep the display
  /// awake. The check itself is cheap and only acts while anti-sleep is on.
  void _startIdleCheck() {
    _idleCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_enableAntiSleep) return;

      final idle = DateTime.now().difference(_lastActivityTime);
      if (idle.inSeconds >= AppConstants.antiSleepIdleIntervalSeconds) {
        _performMouseMove();
      }
    });
  }

  /// Sends a tiny, direction-alternating mouse nudge through the native channel.
  /// The native side tags the synthetic event so it is ignored by the input
  /// monitor (no spurious exp/stats), while still resetting the system idle
  /// timer that controls display sleep.
  Future<void> _performMouseMove() async {
    try {
      _moveToggle = !_moveToggle;
      final double offset = _moveToggle
          ? AppConstants.antiSleepNudgeOffset
          : -AppConstants.antiSleepNudgeOffset;

      await _mouseControlChannel.invokeMethod('moveMouse', {
        'dx': offset,
        'dy': offset,
      });
      // The synthetic move is filtered out natively and never returns through
      // the event stream, so advance the idle window here to schedule the next
      // nudge a full interval from now.
      _lastActivityTime = DateTime.now();
    } catch (e) {
      debugPrint('Failed to move mouse via channel: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _keySubscription?.cancel();
    _mouseSubscription?.cancel();
    _idleCheckTimer?.cancel();
    _clickResetTimer?.cancel();
    super.dispose();
  }
}
