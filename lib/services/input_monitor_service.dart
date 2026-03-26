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
  Timer? _clickResetTimer;

  String _currentKey = AppConstants.defaultKeyText;
  MousePositionData _mouseData = const MousePositionData();
  double? _lastAbsX;
  double? _lastAbsY;
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
    _setNativeAntiSleep(value);
    notifyListeners();
  }

  /// Initialize input listeners
  void initialize() {
    _setupKeyboardListener();
    _setupMouseListener();
  }

  void _setupKeyboardListener() {
    _keySubscription?.cancel();
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

  /// Tell the native side to enable or disable the IOPMAssertion
  /// that prevents display sleep.
  Future<void> _setNativeAntiSleep(bool enabled) async {
    try {
      await _mouseControlChannel.invokeMethod('setAntiSleep', {
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('Failed to set anti-sleep assertion: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_enableAntiSleep) {
      _setNativeAntiSleep(false);
    }
    _keySubscription?.cancel();
    _mouseSubscription?.cancel();
    _clickResetTimer?.cancel();
    super.dispose();
  }
}
