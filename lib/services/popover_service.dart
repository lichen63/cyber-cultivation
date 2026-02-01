import 'dart:io';

import 'package:flutter/services.dart';

/// Service to manage native popover windows on macOS.
///
/// Note: The native side now shows the popover immediately on menu bar item click.
/// This service is used to update the popover content after it's shown.
class PopoverService {
  PopoverService._();

  static final PopoverService instance = PopoverService._();

  static const MethodChannel _channel = MethodChannel('menu_bar_popover');

  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    if (_isInitialized) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }

  /// Dispose of the service
  void dispose() {
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPopoverClosed':
        return true;
      case 'onTrayPopupClosed':
        // Tray popup was closed, stop streaming
        return true;
      default:
        return null;
    }
  }

  /// Hide the currently visible popover.
  Future<bool> hidePopover() async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await _channel.invokeMethod('hidePopover');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Update content of the currently visible popover.
  /// Called after native shows the popover to provide the actual data.
  Future<bool> updatePopoverContent(Map<String, dynamic> data) async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await _channel.invokeMethod('updatePopoverContent', data);
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Show the tray popup with window preview.
  /// This triggers native side to show the popup and start frame streaming.
  Future<bool> showTrayPopup({
    required bool isDarkMode,
    required String locale,
    required double popupWidth,
    required double popupHeight,
    required double titleBarHeight,
  }) async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await _channel.invokeMethod('showTrayPopup', {
        'isDarkMode': isDarkMode,
        'locale': locale,
        'popupWidth': popupWidth,
        'popupHeight': popupHeight,
        'titleBarHeight': titleBarHeight,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Hide the tray popup.
  Future<bool> hideTrayPopup() async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await _channel.invokeMethod('hideTrayPopup');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
