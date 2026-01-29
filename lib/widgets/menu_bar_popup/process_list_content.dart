import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/system_process_helper.dart';
import 'menu_bar_popup_constants.dart';
import 'popup_styles.dart';
import 'popup_widgets.dart';

/// Displays a list of processes for system stats (CPU, GPU, RAM, Disk, Network, Battery)
class ProcessListContent extends StatelessWidget {
  final String itemId;
  final List<Map<String, dynamic>>? processes;
  final bool isLoading;
  final VoidCallback onClose;

  const ProcessListContent({
    super.key,
    required this.itemId,
    required this.processes,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return PopupWidgets.buildLoading();
    }

    final processList = processes ?? [];
    if (processList.isEmpty) {
      return PopupWidgets.buildEmpty('No processes found');
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
          _buildColumnHeaders(context),
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

  Widget _buildColumnHeaders(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (itemId) {
      case 'disk':
        return _DiskColumnHeaders(l10n: l10n);
      case 'network':
        return _NetworkColumnHeaders(l10n: l10n);
      default:
        return _DefaultColumnHeaders(l10n: l10n);
    }
  }

  Widget _buildProcessRow(Map<String, dynamic> process) {
    switch (itemId) {
      case 'disk':
        return _DiskProcessRow(process: process, onClose: onClose);
      case 'network':
        return _NetworkProcessRow(process: process, onClose: onClose);
      default:
        return _DefaultProcessRow(
          process: process,
          itemId: itemId,
          onClose: onClose,
        );
    }
  }
}

/// Default column headers for CPU, GPU, RAM, Battery
class _DefaultColumnHeaders extends StatelessWidget {
  final AppLocalizations l10n;

  const _DefaultColumnHeaders({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            l10n.cpuPopupHeaderUsage,
            textAlign: TextAlign.right,
            style: PopupTextStyles.headerText,
          ),
        ),
      ],
    );
  }
}

/// Column headers for disk I/O
class _DiskColumnHeaders extends StatelessWidget {
  final AppLocalizations l10n;

  const _DiskColumnHeaders({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            l10n.diskPopupHeaderRead,
            textAlign: TextAlign.right,
            style: PopupTextStyles.headerText,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.diskPopupHeaderWrite,
            textAlign: TextAlign.right,
            style: PopupTextStyles.headerText,
          ),
        ),
      ],
    );
  }
}

/// Column headers for network
class _NetworkColumnHeaders extends StatelessWidget {
  final AppLocalizations l10n;

  const _NetworkColumnHeaders({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

/// Default process row for CPU, GPU, RAM, Battery
class _DefaultProcessRow extends StatelessWidget {
  final Map<String, dynamic> process;
  final String itemId;
  final VoidCallback onClose;

  const _DefaultProcessRow({
    required this.process,
    required this.itemId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final value = process['value'] as num? ?? 0;

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
                _formatValue(value),
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(num value) {
    switch (itemId) {
      case 'cpu':
      case 'gpu':
      case 'battery':
        return '${value.toStringAsFixed(1)}%';
      case 'ram':
        return _formatBytes(value);
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _formatBytes(num bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${bytes.toInt()} B';
  }
}

/// Disk process row with read/write columns
class _DiskProcessRow extends StatelessWidget {
  final Map<String, dynamic> process;
  final VoidCallback onClose;

  const _DiskProcessRow({required this.process, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final read = process['read'] as num? ?? 0;
    final write = process['write'] as num? ?? 0;

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
                _formatBytes(read * 1024),
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatBytes(write * 1024),
                textAlign: TextAlign.right,
                style: PopupTextStyles.processValueText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${bytes.toInt()} B';
  }
}

/// Network process row with download/upload columns
class _NetworkProcessRow extends StatelessWidget {
  final Map<String, dynamic> process;
  final VoidCallback onClose;

  const _NetworkProcessRow({required this.process, required this.onClose});

  @override
  Widget build(BuildContext context) {
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
