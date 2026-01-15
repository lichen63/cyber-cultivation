import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';

/// Polling interval for checking accessibility permission status.
const Duration _kPermissionPollInterval = Duration(seconds: 1);

/// A service to check and request accessibility permissions on macOS.
class AccessibilityService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.accessibilityChannel,
  );

  /// Checks if accessibility permission is granted without prompting.
  static Future<bool> checkAccessibility() async {
    if (!Platform.isMacOS) return true;
    try {
      final result = await _channel.invokeMethod<bool>('checkAccessibility');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Requests accessibility permission with system prompt.
  static Future<bool> requestAccessibility() async {
    if (!Platform.isMacOS) return true;
    try {
      final result = await _channel.invokeMethod<bool>('requestAccessibility');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the Accessibility settings in System Preferences.
  static Future<void> openAccessibilitySettings() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException {
      // Ignore errors
    }
  }
}

/// Dialog to prompt user to grant accessibility permission.
/// Automatically closes when permission is granted.
class AccessibilityDialog extends StatefulWidget {
  final AppThemeColors themeColors;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onLater;
  final VoidCallback? onPermissionGranted;

  const AccessibilityDialog({
    super.key,
    required this.themeColors,
    this.onOpenSettings,
    this.onLater,
    this.onPermissionGranted,
  });

  @override
  State<AccessibilityDialog> createState() => _AccessibilityDialogState();

  /// Shows the accessibility dialog and returns when dismissed.
  static Future<void> show({
    required BuildContext context,
    required AppThemeColors themeColors,
    VoidCallback? onOpenSettings,
    VoidCallback? onLater,
    VoidCallback? onPermissionGranted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccessibilityDialog(
        themeColors: themeColors,
        onOpenSettings: onOpenSettings,
        onLater: onLater,
        onPermissionGranted: onPermissionGranted,
      ),
    );
  }
}

class _AccessibilityDialogState extends State<AccessibilityDialog> {
  Timer? _permissionCheckTimer;
  bool _isPolling = false;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Starts polling for permission changes.
  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _permissionCheckTimer = Timer.periodic(_kPermissionPollInterval, (_) {
      _checkPermissionAndClose();
    });
  }

  /// Stops polling for permission changes.
  void _stopPolling() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
    _isPolling = false;
  }

  /// Checks if permission was granted and closes the dialog if so.
  Future<void> _checkPermissionAndClose() async {
    final isGranted = await AccessibilityService.checkAccessibility();
    if (isGranted && mounted) {
      _stopPolling();
      Navigator.of(context).pop();
      widget.onPermissionGranted?.call();
    }
  }

  void _onOpenSettingsPressed() {
    AccessibilityService.openAccessibilitySettings();
    _startPolling();
    widget.onOpenSettings?.call();
  }

  void _onLaterPressed() {
    _stopPolling();
    Navigator.of(context).pop();
    widget.onLater?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: _colors.border, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      color: _colors.accent,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.accessibilityDialogTitle,
                        style: TextStyle(
                          color: _colors.accent,
                          fontSize: AppConstants.fontSizeDialogTitle,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content
                Text(
                  l10n.accessibilityDialogContent,
                  style: TextStyle(color: _colors.primaryText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.accessibilityDialogInstructions,
                  style: TextStyle(color: _colors.secondaryText, fontSize: AppConstants.fontSizeDialogHint),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Actions
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _onLaterPressed,
                      child: Text(
                        l10n.accessibilityDialogLater,
                        style: TextStyle(color: _colors.secondaryText),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _onOpenSettingsPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors.accent,
                        foregroundColor: _colors.dialogBackground,
                      ),
                      child: Text(l10n.accessibilityDialogOpenSettings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
