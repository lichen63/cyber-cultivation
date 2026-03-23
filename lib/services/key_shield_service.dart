import 'package:flutter/services.dart';

import '../constants.dart';
import '../models/key_shield_config.dart';

/// Represents a running macOS GUI application
class RunningApp {
  final String bundleId;
  final String name;

  const RunningApp({required this.bundleId, required this.name});

  factory RunningApp.fromMap(Map<String, dynamic> map) {
    return RunningApp(
      bundleId: map['bundleId'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}

/// Key Shield status from native side
class KeyShieldStatus {
  final bool isEnabled;
  final bool isActivelyBlocking;
  final String? frontmostBundleId;
  final String? frontmostAppName;

  const KeyShieldStatus({
    this.isEnabled = false,
    this.isActivelyBlocking = false,
    this.frontmostBundleId,
    this.frontmostAppName,
  });

  factory KeyShieldStatus.fromMap(Map<String, dynamic> map) {
    return KeyShieldStatus(
      isEnabled: map['isEnabled'] as bool? ?? false,
      isActivelyBlocking: map['isActivelyBlocking'] as bool? ?? false,
      frontmostBundleId: map['frontmostBundleId'] as String?,
      frontmostAppName: map['frontmostAppName'] as String?,
    );
  }
}

/// Service bridging Flutter and native Key Shield functionality
class KeyShieldService {
  static const MethodChannel _channel = MethodChannel(
    KeyShieldConstants.keyShieldChannel,
  );

  /// Push the full Key Shield configuration to native side
  Future<void> syncConfig(KeyShieldConfig config) async {
    try {
      await _channel.invokeMethod('updateConfig', config.toJson());
    } on PlatformException catch (_) {
      // Silently ignore — native side may not be ready
    }
  }

  /// Quick toggle Key Shield on/off
  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } on PlatformException catch (_) {
      // Silently ignore
    }
  }

  /// Get list of currently running GUI applications
  Future<List<RunningApp>> getRunningApps() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getRunningApps',
      );
      if (result == null) return [];
      return result
          .map((e) => RunningApp.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Get current Key Shield status from native
  Future<KeyShieldStatus> getStatus() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getStatus',
      );
      if (result == null) return const KeyShieldStatus();
      return KeyShieldStatus.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (_) {
      return const KeyShieldStatus();
    }
  }
}
