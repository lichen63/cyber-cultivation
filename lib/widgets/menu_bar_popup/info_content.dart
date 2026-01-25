import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/todo_item.dart';
import 'menu_bar_popup_constants.dart';
import 'popup_styles.dart';
import 'popup_widgets.dart';

/// Focus session information content
class FocusContent extends StatelessWidget {
  final bool focusIsActive;
  final bool focusIsRelaxing;
  final int focusSecondsRemaining;
  final int focusCurrentLoop;
  final int focusTotalLoops;

  const FocusContent({
    super.key,
    required this.focusIsActive,
    required this.focusIsRelaxing,
    required this.focusSecondsRemaining,
    required this.focusCurrentLoop,
    required this.focusTotalLoops,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Format remaining time as MM:SS
    final minutes = (focusSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (focusSecondsRemaining % 60).toString().padLeft(2, '0');
    final timeString = '$minutes:$seconds';

    // Determine state label
    String stateLabel;
    if (!focusIsActive) {
      stateLabel = l10n.idleState;
    } else if (focusIsRelaxing) {
      stateLabel = l10n.relaxState;
    } else {
      stateLabel = l10n.focusState;
    }

    return PopupWidgets.buildContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupWidgets.buildInfoRow(l10n.focusPopupStatus, stateLabel),
          const SizedBox(height: 8),
          PopupWidgets.buildInfoRow(l10n.focusPopupTimeRemaining, timeString),
          const SizedBox(height: 8),
          PopupWidgets.buildInfoRow(
            l10n.pomodoroLoopsLabel,
            '$focusCurrentLoop/$focusTotalLoops',
          ),
        ],
      ),
    );
  }
}

/// Todo list content
class TodoContent extends StatelessWidget {
  final List<TodoItem> todos;
  final bool isLoading;

  const TodoContent({super.key, required this.todos, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopupWidgets.buildLoading();
    }

    if (todos.isEmpty) {
      return PopupWidgets.buildEmpty('No todos');
    }

    return PopupWidgets.buildContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < todos.length && i < 10; i++) ...[
            _TodoRow(todo: todos[i]),
            if (i < todos.length - 1 && i < 9) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final TodoItem todo;

  const _TodoRow({required this.todo});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (todo.status) {
      case TodoStatus.done:
        icon = Icons.check_circle;
        iconColor = PopupColors.todoDone;
      case TodoStatus.doing:
        icon = Icons.radio_button_checked;
        iconColor = PopupColors.todoDoing;
      case TodoStatus.todo:
        icon = Icons.radio_button_unchecked;
        iconColor = PopupColors.todoDefault;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            todo.title,
            style: TextStyle(
              fontSize: MenuBarPopupConstants.processNameFontSize,
              color: todo.status == TodoStatus.done
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF1D1D1F),
              decoration: todo.status == TodoStatus.done
                  ? TextDecoration.lineThrough
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Level and EXP content
class LevelExpContent extends StatelessWidget {
  final int level;
  final double currentExp;
  final double maxExp;

  const LevelExpContent({
    super.key,
    required this.level,
    required this.currentExp,
    required this.maxExp,
  });

  @override
  Widget build(BuildContext context) {
    return PopupWidgets.buildContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupWidgets.buildInfoRow('Level', level.toString()),
          const SizedBox(height: 8),
          PopupWidgets.buildInfoRow('Current EXP', '${currentExp.toInt()}'),
          const SizedBox(height: 8),
          PopupWidgets.buildInfoRow('Max EXP', '${maxExp.toInt()}'),
        ],
      ),
    );
  }
}

/// Keyboard stats content
class KeyboardContent extends StatelessWidget {
  final int keyCount;
  final bool isLoading;

  const KeyboardContent({
    super.key,
    required this.keyCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopupWidgets.buildLoading();
    }

    return PopupWidgets.buildContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupWidgets.buildInfoRow(
            'Today Key Events',
            _formatNumber(keyCount),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }
}

/// Mouse stats content
class MouseContent extends StatelessWidget {
  final int distance;
  final bool isLoading;

  const MouseContent({
    super.key,
    required this.distance,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopupWidgets.buildLoading();
    }

    return PopupWidgets.buildContentContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupWidgets.buildInfoRow(
            'Today Mouse Distance',
            _formatDistance(distance),
          ),
        ],
      ),
    );
  }

  String _formatDistance(int pixels) {
    // Convert pixels to meters (assuming 96 DPI, 1 inch = 2.54 cm)
    final meters = pixels / 96 * 2.54 / 100;
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else if (meters >= 1) {
      return '${meters.toStringAsFixed(1)} m';
    }
    return '${(meters * 100).toStringAsFixed(0)} cm';
  }
}
