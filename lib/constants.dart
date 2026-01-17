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
    border: const Color(0xFF3A3A5C),
    accent: Colors.cyanAccent,
    accentSecondary: Colors.purpleAccent,
    inactive: Colors.grey,
    error: Colors.red,
    expBarBackground: Colors.black.withValues(alpha: 0.7),
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
    border: Colors.white,
    accent: const Color(0xFF0097A7),
    accentSecondary: const Color(0xFF7B1FA2),
    inactive: const Color(0xFF9E9E9E),
    error: const Color(0xFFD32F2F),
    expBarBackground: const Color(0xFFE8E8EC).withValues(alpha: 0.85),
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
  static const double buttonPaddingHorizontal = 24.0;
  static const double buttonPaddingVertical = 0.0;
  static const double monitorWidgetSize = 120.0;
  static const double mouseDotSize = 16.0;
  static const double systemStatBoxSize = 110.0;
  static const double systemStatSpacing = 10.0;

  // EXP Bar Dimensions
  static const double expBarHeight = 40.0;
  static const double expBarWidth = 320.0;
  static const double expBarBorderRadius = 16.0;
  static const double expBarPaddingHorizontal = 16.0;
  static const double expBarSpacing = 14.0;

  // Animation Durations
  static const int mouseClickBlinkDurationMs = 100;

  // Font Sizes for main window (base values before scaling)
  static const double fontSizeSmall = 24.0;
  static const double fontSizeMedium = 28.0;
  static const double fontSizeLarge = 32.0;
  static const double fontSizeXLarge = 38.0;
  static const double fontSizeLevel = 30.0;
  static const double fontSizeExpProgress = 28.0;
  static const double fontSizeNetworkStat = 24.0;
  static const double fontSizeButton = 28.0;
  static const double fontSizeStatLabel = 26.0;
  static const double fontSizeStatValue = 28.0;

  // Font Sizes for sub-windows/dialogs (smaller)
  static const double fontSizeDialogTitle = 16.0;
  static const double fontSizeDialogContent = 12.0;
  static const double fontSizeDialogHint = 10.0;
  static const double fontSizeDialogButton = 12.0;
  static const double fontSizeDialogStatLabel = 10.0;
  static const double fontSizeDialogStatValue = 14.0;

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

/// Constants for games list dialog
class GameConstants {
  // Dialog dimensions
  static const double gamesDialogMaxWidth = 800.0;
  static const double gamesDialogMaxHeight = 700.0;
  static const double gamesDialogWidthRatio = 0.98;
  static const double gamesDialogHeightRatio = 0.9;
  static const double gamesDialogInsetPadding = 8.0;
  static const double gamesDialogBorderRadius = 16.0;
  static const double gamesDialogShadowBlur = 20.0;
  static const double gamesDialogShadowSpread = 5.0;

  // Header
  static const double gamesDialogHeaderPaddingH = 12.0;
  static const double gamesDialogHeaderPaddingV = 8.0;
  static const double gamesHeaderIconSize = 16.0;
  static const double gamesHeaderIconSpacing = 6.0;
  static const double gamesHeaderFontSize = 16.0;

  // Games list
  static const double gamesListPadding = 12.0;
  static const double gameCardBorderRadius = 8.0;
  static const double gameCardPadding = 12.0;
  static const double gameIconContainerSize = 36.0;
  static const double gameIconContainerRadius = 8.0;
  static const double gameIconSize = 20.0;
  static const double gameCardContentSpacing = 10.0;
  static const double gameTitleFontSize = 14.0;
  static const double gameTitleSpacing = 2.0;
  static const double gameDescFontSize = 11.0;
}

/// Constants for snake game
class SnakeGameConstants {
  // Grid
  static const int gridSize = 15;
  static const double gridBorderRadius = 8.0;
  static const double gridBorderWidth = 2.0;

  // Game mechanics
  static const int gameTickMs = 200;
  static const int scorePerFood = 10;
  static const int expPerFood = 5;
  static const double swipeThreshold = 20.0;

  // Dialog dimensions
  static const double gameDialogMaxWidth = 800.0;
  static const double gameDialogMaxHeight = 900.0;
  static const double gameDialogWidthRatio = 0.98;
  static const double gameDialogHeightRatio = 0.98;
  static const double gameDialogInsetPadding = 8.0;
  static const double gameDialogBorderRadius = 16.0;
  static const double gameDialogShadowBlur = 20.0;
  static const double gameDialogShadowSpread = 5.0;

  // Header
  static const double gameHeaderPaddingH = 12.0;
  static const double gameHeaderPaddingV = 8.0;
  static const double gameHeaderIconSize = 16.0;
  static const double gameHeaderIconSpacing = 6.0;
  static const double gameHeaderFontSize = 16.0;
  static const double headerButtonSpacing = 6.0;

  // Score display
  static const double scorePaddingH = 8.0;
  static const double scorePaddingV = 4.0;
  static const double scoreBorderRadius = 10.0;
  static const double scoreIconSize = 12.0;
  static const double scoreIconSpacing = 4.0;
  static const double scoreFontSize = 12.0;

  // Game area
  static const double gameAreaPadding = 16.0;
  static const double gameAreaMargin = 32.0;
  static const double cellPadding = 2.0;

  // Cell rendering
  static const double snakeHeadBorderRadius = 6.0;
  static const double snakeBodyBorderRadius = 4.0;
  static const double foodBorderRadius = 50.0;

  // Colors
  static const Color snakeColor = Color(0xFF4CAF50);
  static const Color snakeHeadColor = Color(0xFF2E7D32);
  static const Color foodColor = Color(0xFFFF5722);

  // Overlay UI
  static const double overlayIconSize = 40.0;
  static const double overlaySpacing = 12.0;
  static const double overlaySmallSpacing = 6.0;
  static const double overlayLargeSpacing = 16.0;
  static const double overlayTitleFontSize = 22.0;
  static const double overlaySubtitleFontSize = 12.0;
  static const double overlayHintFontSize = 10.0;

  // Game over
  static const double gameOverTitleFontSize = 24.0;
  static const double gameOverScoreFontSize = 14.0;
  static const double gameOverExpFontSize = 12.0;

  // Button
  static const double buttonPaddingH = 16.0;
  static const double buttonPaddingV = 8.0;
  static const double buttonBorderRadius = 12.0;
}

/// Constants for Flappy Bird game
class FlappyBirdConstants {
  // Game area
  static const double gameWidth = 500.0;
  static const double gameHeight = 700.0;

  // Bird
  static const double birdSize = 30.0;
  static const double birdX = 100.0;
  static const double birdStartY = 350.0;
  static const double birdJumpVelocity = -7.0;
  static const double gravity = 0.35;
  static const double maxFallVelocity = 10.0;

  // Pipes
  static const double pipeWidth = 50.0;
  static const double pipeGap = 180.0;
  static const double pipeSpeed = 2.5;
  static const double pipeSpawnInterval = 2000.0; // ms
  static const double minPipeHeight = 60.0;

  // Game mechanics
  static const int gameTickMs = 16; // ~60 FPS
  static const int scorePerPipe = 1;
  static const int expPerScore = 2;

  // Dialog dimensions
  static const double gameDialogMaxWidth = 500.0;
  static const double gameDialogMaxHeight = 750.0;
  static const double gameDialogWidthRatio = 0.95;
  static const double gameDialogHeightRatio = 0.95;
  static const double gameDialogInsetPadding = 8.0;
  static const double gameDialogBorderRadius = 16.0;
  static const double gameDialogShadowBlur = 20.0;
  static const double gameDialogShadowSpread = 5.0;

  // Header
  static const double gameHeaderPaddingH = 12.0;
  static const double gameHeaderPaddingV = 8.0;
  static const double gameHeaderIconSize = 16.0;
  static const double gameHeaderIconSpacing = 6.0;
  static const double gameHeaderFontSize = 16.0;
  static const double headerButtonSpacing = 6.0;

  // Score display
  static const double scorePaddingH = 8.0;
  static const double scorePaddingV = 4.0;
  static const double scoreBorderRadius = 10.0;
  static const double scoreIconSize = 12.0;
  static const double scoreIconSpacing = 4.0;
  static const double scoreFontSize = 12.0;

  // Game area styling
  static const double gameAreaPadding = 16.0;
  static const double gameBorderRadius = 8.0;
  static const double gameBorderWidth = 2.0;

  // Colors
  static const Color skyColorTop = Color(0xFF87CEEB);
  static const Color skyColorBottom = Color(0xFF4CA6E8);
  static const Color birdColor = Color(0xFFFFD700);
  static const Color birdOutlineColor = Color(0xFFE6A800);
  static const Color pipeColor = Color(0xFF228B22);
  static const Color pipeOutlineColor = Color(0xFF006400);
  static const Color groundColor = Color(0xFF8B4513);

  // Overlay UI
  static const double overlayIconSize = 40.0;
  static const double overlaySpacing = 12.0;
  static const double overlaySmallSpacing = 6.0;
  static const double overlayLargeSpacing = 16.0;
  static const double overlayTitleFontSize = 22.0;
  static const double overlaySubtitleFontSize = 12.0;
  static const double overlayHintFontSize = 10.0;

  // Game over
  static const double gameOverTitleFontSize = 24.0;
  static const double gameOverScoreFontSize = 14.0;
  static const double gameOverExpFontSize = 12.0;

  // Button
  static const double buttonPaddingH = 16.0;
  static const double buttonPaddingV = 8.0;
  static const double buttonBorderRadius = 12.0;
}
