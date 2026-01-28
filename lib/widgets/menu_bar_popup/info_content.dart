import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/todo_item.dart';
import '../../services/system_process_helper.dart';
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

/// Network basic info content widget
class NetworkInfoContent extends StatefulWidget {
  const NetworkInfoContent({super.key});

  @override
  State<NetworkInfoContent> createState() => _NetworkInfoContentState();
}

class _NetworkInfoContentState extends State<NetworkInfoContent> {
  Map<String, String>? _networkInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    final info = await SystemProcessHelper.getNetworkInfo();
    if (mounted) {
      setState(() {
        _networkInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MenuBarPopupConstants.popupPadding,
          vertical: MenuBarPopupConstants.popupPadding / 2,
        ),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    final info = _networkInfo ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuBarPopupConstants.popupPadding,
        vertical: MenuBarPopupConstants.popupPadding / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoRow(
            l10n.networkInfoInterface,
            info['interfaceType'] ?? '-',
          ),
          _buildInfoRow(
            l10n.networkInfoNetworkName,
            info['networkName'] ?? '-',
          ),
          _buildInfoRow(l10n.networkInfoLocalIp, info['localIp'] ?? '-'),
          _buildInfoRow(l10n.networkInfoPublicIp, info['publicIp'] ?? '-'),
          _buildInfoRow(l10n.networkInfoMacAddress, info['macAddress'] ?? '-'),
          _buildInfoRow(l10n.networkInfoGateway, info['gateway'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return SizedBox(
      height: MenuBarPopupConstants.networkInfoRowHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: PopupTextStyles.labelText.copyWith(fontSize: 11)),
          Flexible(
            child: Text(
              value,
              style: PopupTextStyles.valueText.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined network content with info section and process list
class NetworkContent extends StatelessWidget {
  final List<Map<String, dynamic>>? processes;
  final bool isLoading;
  final VoidCallback onClose;

  const NetworkContent({
    super.key,
    required this.processes,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Network info section
        const NetworkInfoContent(),
        // Separator
        Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(
            horizontal: MenuBarPopupConstants.popupPadding,
          ),
          color: PopupColors.separator,
        ),
        const SizedBox(height: MenuBarPopupConstants.popupPadding / 2),
        // Process list section
        _NetworkProcessList(
          processes: processes,
          isLoading: isLoading,
          onClose: onClose,
        ),
      ],
    );
  }
}

/// Network process list widget (reuses the network-specific styling)
class _NetworkProcessList extends StatelessWidget {
  final List<Map<String, dynamic>>? processes;
  final bool isLoading;
  final VoidCallback onClose;

  const _NetworkProcessList({
    required this.processes,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(MenuBarPopupConstants.popupPadding),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    final processList = processes ?? [];
    if (processList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
        child: Center(
          child: Text(
            'No active network processes',
            style: PopupTextStyles.emptyText,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MenuBarPopupConstants.popupPadding,
        vertical: MenuBarPopupConstants.popupPadding / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column headers
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.cpuPopupHeaderProcess,
                  style: PopupTextStyles.headerText,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MenuBarPopupConstants.pidColumnWidth,
                child: Text(
                  l10n.cpuPopupHeaderPid,
                  textAlign: TextAlign.right,
                  style: PopupTextStyles.headerText,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MenuBarPopupConstants.valueColumnWidth,
                child: Text(
                  l10n.networkPopupHeaderDownload,
                  textAlign: TextAlign.right,
                  style: PopupTextStyles.headerText,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MenuBarPopupConstants.valueColumnWidth,
                child: Text(
                  l10n.networkPopupHeaderUpload,
                  textAlign: TextAlign.right,
                  style: PopupTextStyles.headerText,
                ),
              ),
            ],
          ),
          const SizedBox(height: MenuBarPopupConstants.headerBottomSpacing),
          // Process rows
          for (int i = 0; i < processList.length; i++) ...[
            _buildProcessRow(processList[i]),
            if (i < processList.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessRow(Map<String, dynamic> process) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final download = process['download'] as num? ?? 0;
    final upload = process['upload'] as num? ?? 0;

    return InkWell(
      onTap: () {
        SystemProcessHelper.openActivityMonitor();
        onClose();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: PopupTextStyles.processNameText,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.pidColumnWidth,
              child: Text(
                pid > 0 ? pid.toString() : '-',
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatSpeed(download),
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatSpeed(upload),
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSpeed(num bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024 * 1024)).toStringAsFixed(1)}G/s';
    } else if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)}M/s';
    } else if (bytesPerSec >= 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)}K/s';
    }
    return '${bytesPerSec.toInt()}B/s';
  }
}
