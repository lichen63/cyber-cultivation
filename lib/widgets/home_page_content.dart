import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/todo_item.dart';
import '../services/pomodoro_service.dart';
import 'action_buttons_row.dart';
import 'floating_exp_indicator.dart';
import 'game_area_widget.dart';
import 'level_up_effect.dart';
import 'system_stats_panel.dart';

/// The main content widget for the home page
class HomePageContent extends StatelessWidget {
  final int level;
  final double currentExp;
  final double maxExp;
  final String currentKey;
  final double mouseX;
  final double mouseY;
  final double screenWidth;
  final double screenHeight;
  final bool isMouseClicking;
  final bool isHovering;
  final bool isAlwaysShowActionButtons;
  final bool isShowSystemStats;
  final bool isShowKeyboardTrack;
  final bool isShowMouseTrack;
  final SystemStatsData systemStats;
  final PomodoroState pomodoroState;
  final List<TodoItem> todos;
  final AppThemeColors themeColors;
  final GlobalKey<FloatingExpIndicatorManagerState>? floatingExpKey;
  final GlobalKey<LevelUpEffectWrapperState>? levelUpEffectKey;
  final GlobalKey? captureKey;
  final VoidCallback onPomodoroPressed;
  final VoidCallback onStatsPressed;
  final VoidCallback onTodoPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onGamesPressed;
  final void Function(Offset) onContextMenu;

  const HomePageContent({
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
    required this.isHovering,
    required this.isAlwaysShowActionButtons,
    required this.isShowSystemStats,
    required this.isShowKeyboardTrack,
    required this.isShowMouseTrack,
    required this.systemStats,
    required this.pomodoroState,
    required this.todos,
    required this.themeColors,
    this.floatingExpKey,
    this.levelUpEffectKey,
    this.captureKey,
    required this.onPomodoroPressed,
    required this.onStatsPressed,
    required this.onTodoPressed,
    required this.onSettingsPressed,
    required this.onGamesPressed,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onSecondaryTapUp: (details) => onContextMenu(details.globalPosition),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double windowScale =
              constraints.maxWidth / AppConstants.defaultWindowWidth;

          return Stack(
            children: [
              _buildMainArea(windowScale),
              if (isHovering || isAlwaysShowActionButtons) ...[
                _buildTopButtons(context, windowScale),
                _buildBottomButtons(context, windowScale),
              ],
            ],
          );
        },
      ),
    );

    // Wrap in RepaintBoundary for tray popup capture if key is provided
    if (captureKey != null) {
      content = RepaintBoundary(key: captureKey, child: content);
    }

    return content;
  }

  Widget _buildMainArea(double windowScale) {
    return DragToMoveArea(
      child: LevelUpEffectWrapper(
        key: levelUpEffectKey,
        themeColors: themeColors,
        scale: windowScale,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: themeColors.border,
              width: AppConstants.borderWidth * windowScale,
            ),
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadius * windowScale,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding * windowScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: GameAreaWidget(
                    level: level,
                    currentExp: currentExp,
                    maxExp: maxExp,
                    currentKey: currentKey,
                    mouseX: mouseX,
                    mouseY: mouseY,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    isMouseClicking: isMouseClicking,
                    isShowSystemStats: isShowSystemStats,
                    isShowKeyboardTrack: isShowKeyboardTrack,
                    isShowMouseTrack: isShowMouseTrack,
                    systemStats: systemStats,
                    pomodoroState: pomodoroState,
                    themeColors: themeColors,
                    floatingExpKey: floatingExpKey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context, double windowScale) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: 10 * windowScale,
      left: 0,
      right: 0,
      child: ActionButtonsRow(
        scale: windowScale,
        themeColors: themeColors,
        buttons: [
          ActionButtonConfig(
            text: _buildPomodoroButtonText(l10n),
            onPressed: onPomodoroPressed,
          ),
          ActionButtonConfig(text: l10n.statsTitle, onPressed: onStatsPressed),
          ActionButtonConfig(
            text: _buildTodoButtonText(l10n),
            onPressed: onTodoPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, double windowScale) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 10 * windowScale,
      left: 0,
      right: 0,
      child: ActionButtonsRow(
        scale: windowScale,
        themeColors: themeColors,
        buttons: [
          ActionButtonConfig(text: l10n.gamesTitle, onPressed: onGamesPressed),
          ActionButtonConfig(text: 'B-2', onPressed: () {}),
          ActionButtonConfig(
            text: l10n.settingsTitle,
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }

  String _buildPomodoroButtonText(AppLocalizations l10n) {
    if (!pomodoroState.isActive) {
      return l10n.focusState;
    }

    if (pomodoroState.isRelaxing) {
      return '${l10n.relaxState} ${pomodoroState.formattedTime}';
    }

    return '${l10n.focusState} ${pomodoroState.currentLoop}/${pomodoroState.totalLoops}  ${pomodoroState.formattedTime}';
  }

  String _buildTodoButtonText(AppLocalizations l10n) {
    if (todos.isEmpty) {
      return l10n.todoTitle;
    }
    final doneCount = todos.where((t) => t.status == TodoStatus.done).length;
    return '${l10n.todoTitle} $doneCount/${todos.length}';
  }
}
