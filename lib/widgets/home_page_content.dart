import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/todo_item.dart';
import '../services/pomodoro_service.dart';
import 'action_buttons_row.dart';
import 'game_area_widget.dart';

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
  final PomodoroState pomodoroState;
  final List<TodoItem> todos;
  final AppThemeColors themeColors;
  final VoidCallback onPomodoroPressed;
  final VoidCallback onStatsPressed;
  final VoidCallback onTodoPressed;
  final VoidCallback onSettingsPressed;
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
    required this.pomodoroState,
    required this.todos,
    required this.themeColors,
    required this.onPomodoroPressed,
    required this.onStatsPressed,
    required this.onTodoPressed,
    required this.onSettingsPressed,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }

  Widget _buildMainArea(double windowScale) {
    return DragToMoveArea(
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
                  pomodoroState: pomodoroState,
                  themeColors: themeColors,
                ),
              ),
            ],
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
          ActionButtonConfig(text: 'B-1', onPressed: () {}),
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
