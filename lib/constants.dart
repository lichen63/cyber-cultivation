import 'package:flutter/material.dart';

/// Theme mode for the application
enum AppThemeMode { light, dark }

/// Theme colors for different modes
class AppThemeColors {
  final Color primaryText;
  final Color secondaryText;
  final Color background;
  final Color dialogBackground;
  final Color overlay;
  final Color overlayLight;
  final Color border;
  final Color accent;
  final Color accentSecondary;
  final Color inactive;
  final Color error;
  final Color expBarBackground;
  final Color expBarText;
  final Color expBarTextShadow;
  final Color levelTextShadow;
  final Color progressBarFill;
  final Color chartAccent;
  final Color networkUpload;
  final Color networkDownload;
  final Brightness brightness;

  const AppThemeColors({
    required this.primaryText,
    required this.secondaryText,
    required this.background,
    required this.dialogBackground,
    required this.overlay,
    required this.overlayLight,
    required this.border,
    required this.accent,
    required this.accentSecondary,
    required this.inactive,
    required this.error,
    required this.expBarBackground,
    required this.expBarText,
    required this.expBarTextShadow,
    required this.levelTextShadow,
    required this.progressBarFill,
    required this.chartAccent,
    required this.networkUpload,
    required this.networkDownload,
    required this.brightness,
  });

  /// Dark theme colors (default)
  static final dark = AppThemeColors(
    primaryText: Colors.white,
    secondaryText: Colors.white54,
    background: Colors.transparent,
    dialogBackground: Colors.black.withValues(alpha: 0.9),
    overlay: Colors.black.withValues(alpha: 0.7),
    overlayLight: Colors.black.withValues(alpha: 0.3),
    border: Colors.white,
    accent: Colors.cyanAccent,
    accentSecondary: Colors.purpleAccent,
    inactive: Colors.grey,
    error: Colors.red,
    expBarBackground: Colors.black.withValues(alpha: 0.5),
    expBarText: Colors.white,
    expBarTextShadow: Colors.black,
    levelTextShadow: Colors.black,
    progressBarFill: Colors.deepPurple,
    chartAccent: const Color(0xFF66BB6A),
    networkUpload: Colors.red,
    networkDownload: Colors.blue,
    brightness: Brightness.dark,
  );

  /// Light theme colors
  static final light = AppThemeColors(
    primaryText: const Color(0xFF1A1A2E),
    secondaryText: const Color(0xFF4A4A6A),
    background: Colors.transparent,
    dialogBackground: const Color(0xFFF5F5F7).withValues(alpha: 0.95),
    overlay: const Color(0xFFE8E8EC).withValues(alpha: 0.85),
    overlayLight: const Color(0xFFE8E8EC).withValues(alpha: 0.5),
    border: const Color(0xFF3A3A5C),
    accent: const Color(0xFF0097A7),
    accentSecondary: const Color(0xFF7B1FA2),
    inactive: const Color(0xFF9E9E9E),
    error: const Color(0xFFD32F2F),
    expBarBackground: const Color(0xFFE0E0E0).withValues(alpha: 0.7),
    expBarText: const Color(0xFF1A1A2E),
    expBarTextShadow: Colors.white54,
    levelTextShadow: Colors.black45,
    progressBarFill: const Color(0xFF673AB7),
    chartAccent: const Color(0xFF43A047),
    networkUpload: const Color(0xFFD32F2F),
    networkDownload: const Color(0xFF1976D2),
    brightness: Brightness.light,
  );

  /// Get theme colors by mode
  static AppThemeColors fromMode(AppThemeMode mode) {
    return mode == AppThemeMode.light ? light : dark;
  }
}

class AppConstants {
  // App Info
  static const String appTitle = 'Cyber Cultivation';

  // Window Configuration
  static const double defaultWindowWidth = 600.0;
  static const double defaultWindowHeight = 600.0;
  static const double minWindowWidth = 400.0;
  static const double minWindowHeight = 400.0;
  static const double maxWindowWidth = 1600.0;
  static const double maxWindowHeight = 1600.0;
  static const double windowAspectRatio = 1.0;

  // Event Channels
  static const String keyEventsChannel =
      'com.lichen63.cyber_cultivation/key_events';
  static const String mouseEventsChannel =
      'com.lichen63.cyber_cultivation/mouse_events';
  static const String mouseControlChannel =
      'com.lichen63.cyber_cultivation/mouse_control';
  static const String accessibilityChannel =
      'com.lichen63.cyber_cultivation/accessibility';
  static const String systemInfoChannel =
      'com.lichen63.cyber_cultivation/system_info';

  // UI Strings
  static const String defaultKeyText = 'Key';
  static const String forceForegroundText = 'Force Foreground';
  static const String toggleAlwaysOnTopValue = 'toggleAlwaysOnTop';
  static const String antiSleepText = 'Anti-Sleep';
  static const String toggleAntiSleepValue = 'toggle_anti_sleep';
  static const String exitGameText = 'Exit Game';
  static const String exitGameValue = 'exit_game';

  // Pomodoro Strings
  static const String pomodoroDialogTitle = 'Pomodoro Clock';
  static const String pomodoroDurationLabel = 'Focus (min):';
  static const String pomodoroRelaxLabel = 'Relax (min):';
  static const String pomodoroLoopsLabel = 'Loops:';
  static const String pomodoroExpectedExpLabel = 'Expected Exp: ';
  static const String pomodoroStartButtonText = 'Start';
  static const String cancelButtonText = 'Cancel';
  static const String confirmStopTitle = 'Stop Cultivation?';
  static const String confirmStopContent =
      'Current cultivation progress will be lost.';
  static const String stopButtonText = 'Stop';
  static const String invalidInputErrorText = 'Invalid';

  // UI Dimensions
  static const double borderWidth = 6.0;
  static const double thinBorderWidth = 2.0;
  static const double borderRadius = 20.0;
  static const double smallBorderRadius = 10.0;
  static const double defaultPadding = 30.0;
  static const double buttonPaddingHorizontal = 16.0;
  static const double buttonPaddingVertical = 4.0;
  static const double monitorWidgetSize = 80.0;
  static const double mouseDotSize = 10.0;
  static const double systemStatBoxSize = 70.0;
  static const double systemStatSpacing = 6.0;

  // Animation Durations
  static const int mouseClickBlinkDurationMs = 150;

  // Colors (non-themed)
  static const Color transparentColor = Colors.transparent;
  static const Color pomodoroFocusColor = Colors.redAccent;
  static const Color pomodoroRelaxColor = Colors.greenAccent;
  static const double pomodoroTimeFontSizeRatio = 0.22;

  // Assets
  static const String characterImagePath = 'assets/images/character_2.png';

  // EXP System
  static const int initialLevel = 1;
  static const double initialMaxExp = 100.0;
  static const int maxLevel = 100;
  static const double expGainPerKey = 1.0;
  static const double expGainPerMouse = 1.0;
  static const double expGrowthFactor = 1.3;
  static const double expGainPerMinute = 20.0;

  static const int defaultPomodoroDuration = 25;
  static const int defaultRelaxDuration = 5;
  static const int defaultPomodoroLoops = 1;
}
