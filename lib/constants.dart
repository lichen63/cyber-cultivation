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
  
  // UI Strings
  static const String defaultKeyText = 'Press any key...';
  static const String forceForegroundText = 'Force Foreground';
  static const String toggleAlwaysOnTopValue = 'toggleAlwaysOnTop';
  
  // UI Dimensions
  static const double borderWidth = 6.0;
  static const double thinBorderWidth = 2.0;
  static const double borderRadius = 20.0;
  static const double smallBorderRadius = 10.0;
  static const double defaultPadding = 30.0;
  static const double buttonPaddingHorizontal = 16.0;
  static const double buttonPaddingVertical = 8.0;
  static const double mouseMonitorSize = 80.0;
  static const double mouseDotSize = 10.0;
  
  // Colors
  static const Color primarySeedColor = Colors.deepPurple;
  static const Color transparentColor = Colors.transparent;
  static const Color whiteColor = Colors.white;
  static const Color redColor = Colors.red;
  static final Color blackOverlayColor = Colors.black.withValues(alpha: 0.7);
  static final Color blackOverlayLightColor = Colors.black.withValues(alpha: 0.3);
  
  // Assets
  static const String characterImagePath = 'assets/images/character.png';
}
