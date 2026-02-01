import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../constants.dart';

/// Service for capturing and streaming window content to native tray popup.
///
/// Uses RepaintBoundary to capture the game window at reduced resolution,
/// compresses to JPEG, and streams via MethodChannel to native side.
class WindowCaptureService {
  WindowCaptureService._();

  static final WindowCaptureService instance = WindowCaptureService._();

  static const MethodChannel _channel = MethodChannel('window_capture');

  bool _isInitialized = false;
  bool _isStreaming = false;
  Timer? _captureTimer;
  GlobalKey? _boundaryKey;

  /// Callback to notify Flutter when popup requests stream start/stop
  Function(bool isVisible)? onPopupVisibilityChanged;

  /// Initialize the service
  void initialize() {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }

  /// Set the RepaintBoundary key for capturing
  void setBoundaryKey(GlobalKey key) {
    _boundaryKey = key;
  }

  /// Dispose of the service
  void dispose() {
    stopStreaming();
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
    _boundaryKey = null;
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'startStreaming':
        await startStreaming();
        return true;
      case 'stopStreaming':
        stopStreaming();
        return true;
      case 'captureFrame':
        // Single frame capture request
        return await _captureAndSendFrame();
      default:
        return null;
    }
  }

  /// Start streaming frames to native popup
  Future<void> startStreaming() async {
    if (_isStreaming) return;
    _isStreaming = true;

    onPopupVisibilityChanged?.call(true);

    // Capture at configured FPS
    _captureTimer = Timer.periodic(
      TrayPopupConstants.captureInterval,
      (_) => _captureAndSendFrame(),
    );

    // Send initial frame immediately
    await _captureAndSendFrame();
  }

  /// Stop streaming frames
  void stopStreaming() {
    _isStreaming = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    onPopupVisibilityChanged?.call(false);
  }

  /// Capture a frame and send to native side
  Future<bool> _captureAndSendFrame() async {
    if (!_isStreaming || _boundaryKey == null) return false;

    try {
      final boundary =
          _boundaryKey!.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return false;

      // Capture at reduced pixel ratio for performance
      final image = await boundary.toImage(
        pixelRatio: TrayPopupConstants.capturePixelRatio,
      );

      // Convert to JPEG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return false;

      final bytes = byteData.buffer.asUint8List();

      // Send to native side
      await _channel.invokeMethod('updateFrame', {
        'imageData': bytes,
        'width': image.width,
        'height': image.height,
      });

      return true;
    } catch (e) {
      // Silently fail - streaming may have been stopped
      return false;
    }
  }

  /// Check if currently streaming
  bool get isStreaming => _isStreaming;

  /// Send popup visibility state to native (for toggling)
  Future<void> notifyPopupState({required bool isVisible}) async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('setPopupVisible', {'visible': isVisible});
    } catch (e) {
      // Ignore errors
    }
  }
}
