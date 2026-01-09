import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appTitle = 'Cyber Cultivation';
  
  // Window Configuration
  static const double defaultWindowWidth = 400.0;
  static const double defaultWindowHeight = 400.0;
  static const double minWindowWidth = 200.0;
  static const double minWindowHeight = 200.0;
  static const double maxWindowWidth = 800.0;
  static const double maxWindowHeight = 800.0;
  static const double windowAspectRatio = 1.0;
  
  // Event Channels
  static const String keyEventsChannel = 'com.lichen63.cyber_cultivation/key_events';
  static const String mouseEventsChannel = 'com.lichen63.cyber_cultivation/mouse_events';
  static const String mouseControlChannel = 'com.lichen63.cyber_cultivation/mouse_control';
  
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
  static const String confirmStopContent = 'Current cultivation progress will be lost.';
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
  
  // Colors
  static const Color primarySeedColor = Colors.deepPurple;
  static const Color transparentColor = Colors.transparent;
  static const Color whiteColor = Colors.white;
  static const Color redColor = Colors.red;
  static final Color blackOverlayColor = Colors.black.withValues(alpha: 0.7);
  static final Color blackOverlayLightColor = Colors.black.withValues(alpha: 0.3);
  static final Color dialogBackgroundColor = Colors.black.withValues(alpha: 0.9);
  static const Color cyanAccentColor = Colors.cyanAccent;
  static const Color purpleAccentColor = Colors.purpleAccent;
  static const Color greyColor = Colors.grey;
  static const Color white54Color = Colors.white54;
  static const Color pomodoroFocusColor = Colors.redAccent;
  static const Color pomodoroRelaxColor = Colors.greenAccent;
  
  // Assets
  static const String characterImagePath = 'assets/images/character_2.png';

  // EXP System
  static const int initialLevel = 1;
  static const double initialMaxExp = 100.0;
  static const int maxLevel = 100;
  static const double expGainPerKey = 10.0;
  static const double expGainPerMouse = 1.0;
  static const double expGrowthFactor = 1.1;
  static const double expGainPerMinute = 20.0;
  
  static const int defaultPomodoroDuration = 25;
  static const int defaultRelaxDuration = 5;
  static const int defaultPomodoroLoops = 1;
}
