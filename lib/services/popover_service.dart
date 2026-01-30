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
}
