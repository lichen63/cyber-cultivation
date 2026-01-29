import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';

/// A service that manages a pool of pre-warmed Flutter windows for instant popups.
///
/// Instead of creating new windows on demand (which takes ~1s due to Flutter engine
/// initialization), this service pre-creates hidden windows at app startup.
/// When a popup is needed, it reuses a window from the pool, making it nearly instant.
class WindowPoolService {
  WindowPoolService._();

  static final WindowPoolService instance = WindowPoolService._();

  /// Pool of available (hidden) window controllers
  final List<_PooledWindow> _availableWindows = [];

  /// Currently active (visible) window
  _PooledWindow? _activeWindow;

  /// Whether the pool has been initialized
  bool _isInitialized = false;

  /// Whether initialization is in progress
  bool _isInitializing = false;

  /// Number of windows to pre-warm
  static const int _poolSize = WindowPoolConstants.poolSize;

  /// Initialize the window pool by creating pre-warmed windows.
  /// Call this early in app startup (e.g., after main window is ready).
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    debugPrint('[WindowPool] Initializing pool with $_poolSize windows...');

    try {
      // Create windows sequentially to avoid overwhelming the system
      for (int i = 0; i < _poolSize; i++) {
        final controller = await _createPooledWindow(i);
        if (controller != null) {
          _availableWindows.add(controller);
          debugPrint('[WindowPool] Pre-warmed window ${i + 1}/$_poolSize');
        }
      }

      _isInitialized = true;
      debugPrint(
        '[WindowPool] Initialized with ${_availableWindows.length} windows',
      );
    } catch (e) {
      debugPrint('[WindowPool] Failed to initialize: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Create a single pooled window
  Future<_PooledWindow?> _createPooledWindow(int index) async {
    try {
      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: jsonEncode({
            'pooledWindow': true,
            'poolIndex': index,
            // Provide default values - will be updated when shown
            'itemId': '',
            'x': 0.0,
            'y': 0.0,
            'brightness': 'dark',
            'locale': 'en',
          }),
        ),
      );

      return _PooledWindow(controller: controller, index: index);
    } catch (e) {
      debugPrint('[WindowPool] Failed to create window $index: $e');
      return null;
    }
  }

  /// Show a popup window with the given configuration.
  /// Returns true if a pooled window was used, false if fallback to creating new.
  Future<bool> showPopup({
    required String itemId,
    required double x,
    required double y,
    required String brightness,
    String? locale,
    Map<String, dynamic>? extraArgs,
  }) async {
    // Prepare the arguments to send to the window
    final args = <String, dynamic>{
      'itemId': itemId,
      'x': x,
      'y': y,
      'brightness': brightness,
      'locale': locale,
      ...?extraArgs,
    };

    // If we have an active window, reuse it directly (most efficient)
    if (_activeWindow != null) {
      debugPrint('[WindowPool] Reusing active window ${_activeWindow!.index}');
      try {
        await _activeWindow!.controller.invokeMethod('updateContent', args);
        return true;
      } catch (e) {
        debugPrint('[WindowPool] Failed to update active window: $e');
        // Active window failed, try to get a new one from pool
        _activeWindow = null;
      }
    }

    // Try to get a window from the pool
    _PooledWindow? window;

    if (_availableWindows.isNotEmpty) {
      window = _availableWindows.removeLast();
      debugPrint('[WindowPool] Getting window ${window.index} from pool');
    } else {
      // Pool exhausted, create a new window on-demand
      debugPrint('[WindowPool] Pool exhausted, creating new window');
      window = await _createPooledWindow(_availableWindows.length + 1);
    }

    if (window == null) {
      debugPrint('[WindowPool] Failed to get window');
      return false;
    }

    try {
      // Send update command to the pooled window
      await window.controller.invokeMethod('updateContent', args);
      _activeWindow = window;
      return true;
    } catch (e) {
      debugPrint('[WindowPool] Failed to show popup: $e');
      // Return window to pool on failure
      _availableWindows.add(window);
      return false;
    }
  }

  /// Hide the currently active popup and return it to the pool.
  Future<void> hideActivePopup() async {
    if (_activeWindow == null) return;

    try {
      await _activeWindow!.controller.invokeMethod('hideWindow', null);
      _availableWindows.add(_activeWindow!);
      debugPrint(
        '[WindowPool] Returned window ${_activeWindow!.index} to pool',
      );
    } catch (e) {
      debugPrint('[WindowPool] Failed to hide active popup: $e');
    } finally {
      _activeWindow = null;
    }
  }

  /// Notify that a pooled window was closed externally (e.g., lost focus).
  /// Called from the pooled window itself.
  void onWindowHidden(int poolIndex) {
    if (_activeWindow?.index == poolIndex) {
      _availableWindows.add(_activeWindow!);
      _activeWindow = null;
      debugPrint('[WindowPool] Window $poolIndex returned to pool (external)');
    }
  }

  /// Dispose of all pooled windows.
  /// Note: We use hide() since WindowController doesn't have a close() method.
  /// The windows will be cleaned up when the app exits.
  Future<void> dispose() async {
    for (final window in _availableWindows) {
      try {
        await window.controller.hide();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    _availableWindows.clear();

    if (_activeWindow != null) {
      try {
        await _activeWindow!.controller.hide();
      } catch (e) {
        // Ignore
      }
      _activeWindow = null;
    }

    _isInitialized = false;
    debugPrint('[WindowPool] Disposed');
  }

  /// Check if the pool is ready to use.
  /// Returns true if we have any pre-warmed windows (active or available).
  bool get isReady =>
      _isInitialized && (_availableWindows.isNotEmpty || _activeWindow != null);

  /// Get the number of available windows in the pool
  int get availableCount => _availableWindows.length;
}

/// Internal class to track pooled windows
class _PooledWindow {
  final WindowController controller;
  final int index;

  _PooledWindow({required this.controller, required this.index});
}
