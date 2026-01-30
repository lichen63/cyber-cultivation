import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/pomodoro_service.dart';
import 'character_display.dart';
import 'cultivation_formation.dart';
import 'exp_display.dart';
import 'floating_exp_indicator.dart';
import 'keyboard_monitor.dart';
import 'mouse_monitor.dart';
import 'system_stats_panel.dart';

/// The main game area widget containing character, monitors, and stats
class GameAreaWidget extends StatelessWidget {
  final int level;
  final double currentExp;
  final double maxExp;
  final String currentKey;
  final double mouseX;
  final double mouseY;
  final double screenWidth;
  final double screenHeight;
  final bool isMouseClicking;
  final bool isShowSystemStats;
  final bool isShowKeyboardTrack;
  final bool isShowMouseTrack;
  final SystemStatsData systemStats;
  final PomodoroState pomodoroState;
  final AppThemeColors themeColors;
  final GlobalKey<FloatingExpIndicatorManagerState>? floatingExpKey;

  const GameAreaWidget({
    super.key,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.currentKey,
    required this.mouseX,
    required this.mouseY,
    required this.screenWidth,
    required this.screenHeight,
    required this.isMouseClicking,
    required this.isShowSystemStats,
    required this.isShowKeyboardTrack,
    required this.isShowMouseTrack,
    required this.systemStats,
    required this.pomodoroState,
    required this.themeColors,
    this.floatingExpKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale =
            constraints.maxWidth / AppConstants.defaultWindowWidth;

        return Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 30 * scale),
                ExpDisplay(
                  level: level,
                  currentExp: currentExp,
                  maxExp: maxExp,
                  scale: scale,
                  themeColors: themeColors,
                ),
                SizedBox(height: 10 * scale),
                Expanded(child: _buildCharacterArea(scale)),
              ],
            ),
            if (isShowKeyboardTrack) _buildKeyboardMonitor(scale),
            if (isShowMouseTrack) _buildMouseMonitor(scale),
            // Floating exp indicator manager - centered in the window
            if (floatingExpKey != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: FloatingExpIndicatorManager(
                    key: floatingExpKey,
                    themeColors: themeColors,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCharacterArea(double scale) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CharacterDisplay(),
        if (pomodoroState.isActive)
          CultivationFormation(
            progress: pomodoroState.progress,
            isRelaxing: pomodoroState.isRelaxing,
            size: 240 * scale,
            timeText: pomodoroState.formattedTime,
          ),
        if (isShowSystemStats)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SystemStatsPanel(
              scale: scale,
              themeColors: themeColors,
              systemStats: systemStats,
            ),
          ),
      ],
    );
  }

  Widget _buildKeyboardMonitor(double scale) {
    return Positioned(
      top: 360 * scale,
      left: 0,
      child: KeyboardMonitor(
        currentKey: currentKey,
        scale: scale,
        themeColors: themeColors,
      ),
    );
  }

  Widget _buildMouseMonitor(double scale) {
    return Positioned(
      top: 360 * scale,
      right: 0,
      child: MouseMonitor(
        mouseX: mouseX,
        mouseY: mouseY,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        isClicking: isMouseClicking,
        scale: scale,
        themeColors: themeColors,
      ),
    );
  }
}
