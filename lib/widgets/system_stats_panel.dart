import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

/// Service for getting system information via native platform channel
class SystemInfoService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.systemInfoChannel,
  );

  /// Get CPU usage percentage (0-100)
  static Future<double> getCpuUsage() async {
    try {
      final result = await _channel.invokeMethod<double>('getCpuUsage');
      return result ?? 0.0;
    } catch (e) {
      debugPrint('Failed to get CPU usage: $e');
      return 0.0;
    }
  }

  /// Get GPU usage percentage (0-100)
  static Future<double> getGpuUsage() async {
    try {
      final result = await _channel.invokeMethod<double>('getGpuUsage');
      return result ?? 0.0;
    } catch (e) {
      debugPrint('Failed to get GPU usage: $e');
      return 0.0;
    }
  }

  /// Get RAM usage percentage (0-100)
  static Future<double> getRamUsage() async {
    try {
      final result = await _channel.invokeMethod<double>('getRamUsage');
      return result ?? 0.0;
    } catch (e) {
      debugPrint('Failed to get RAM usage: $e');
      return 0.0;
    }
  }

  /// Get Disk usage percentage (0-100)
  static Future<double> getDiskUsage() async {
    try {
      final result = await _channel.invokeMethod<double>('getDiskUsage');
      return result ?? 0.0;
    } catch (e) {
      debugPrint('Failed to get Disk usage: $e');
      return 0.0;
    }
  }

  /// Get Network upload speed in bytes per second
  static Future<int> getNetworkUpload() async {
    try {
      final result = await _channel.invokeMethod<int>('getNetworkUpload');
      return result ?? 0;
    } catch (e) {
      debugPrint('Failed to get Network upload: $e');
      return 0;
    }
  }

  /// Get Network download speed in bytes per second
  static Future<int> getNetworkDownload() async {
    try {
      final result = await _channel.invokeMethod<int>('getNetworkDownload');
      return result ?? 0;
    } catch (e) {
      debugPrint('Failed to get Network download: $e');
      return 0;
    }
  }

  /// Get all system stats at once
  static Future<Map<String, dynamic>> getAllStats() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAllStats');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } catch (e) {
      debugPrint('Failed to get all stats: $e');
      return {};
    }
  }

  /// Get top CPU consuming processes
  /// Returns a list of maps with 'name', 'pid', and 'cpu' keys
  static Future<List<Map<String, dynamic>>> getTopCpuProcesses({
    int limit = 5,
  }) async {
    try {
      final result = await _channel.invokeMethod<List>('getTopCpuProcesses', {
        'limit': limit,
      });
      if (result != null) {
        return result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get top CPU processes: $e');
      return [];
    }
  }
}

/// Widget that displays a single system stat
class SystemStatBox extends StatelessWidget {
  final String label;
  final String value;
  final double scale;
  final AppThemeColors themeColors;
  final double? progress;

  const SystemStatBox({
    super.key,
    required this.label,
    required this.value,
    required this.scale,
    required this.themeColors,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.overlay,
        shape: BoxShape.circle,
        border: Border.all(
          color: themeColors.border,
          width: AppConstants.thinBorderWidth,
        ),
      ),
      padding: EdgeInsets.all(4 * scale),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: themeColors.primaryText,
                fontSize: AppConstants.fontSizeStatLabel * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (progress != null)
              SizedBox(
                width: 40 * scale,
                height: 4 * scale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2 * scale),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    backgroundColor: themeColors.border.withValues(alpha: 0.9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress!),
                    ),
                  ),
                ),
              ),
            Text(
              value,
              style: TextStyle(
                color: themeColors.primaryText,
                fontSize: AppConstants.fontSizeStatValue * scale,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) {
      return themeColors.error;
    } else if (progress >= 0.7) {
      return Colors.orange;
    } else {
      return themeColors.accent;
    }
  }
}

/// Specialized widget for network stats with compact layout
class _NetworkStatBox extends StatelessWidget {
  final int upload;
  final int download;
  final String Function(int) formatBytes;
  final double scale;
  final AppThemeColors themeColors;

  const _NetworkStatBox({
    required this.upload,
    required this.download,
    required this.formatBytes,
    required this.scale,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.overlay,
        shape: BoxShape.circle,
        border: Border.all(
          color: themeColors.border,
          width: AppConstants.thinBorderWidth,
        ),
      ),
      padding: EdgeInsets.all(4 * scale),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NET',
              style: TextStyle(
                color: themeColors.primaryText,
                fontSize: AppConstants.fontSizeStatLabel * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '↑',
                  style: TextStyle(
                    color: themeColors.networkUpload,
                    fontSize: AppConstants.fontSizeNetworkStat * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(upload),
                  style: TextStyle(
                    color: themeColors.primaryText,
                    fontSize: AppConstants.fontSizeNetworkStat * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '↓',
                  style: TextStyle(
                    color: themeColors.networkDownload,
                    fontSize: AppConstants.fontSizeNetworkStat * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(download),
                  style: TextStyle(
                    color: themeColors.primaryText,
                    fontSize: AppConstants.fontSizeNetworkStat * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class to hold system stats for the panel
/// This allows the stats to be passed from a central source (MenuBarInfoService)
/// to ensure synchronization with menu bar display
class SystemStatsData {
  final double cpuUsage;
  final double gpuUsage;
  final double ramUsage;
  final double diskUsage;
  final int networkUpload;
  final int networkDownload;

  const SystemStatsData({
    this.cpuUsage = 0,
    this.gpuUsage = 0,
    this.ramUsage = 0,
    this.diskUsage = 0,
    this.networkUpload = 0,
    this.networkDownload = 0,
  });
}

/// Panel containing all system stats arranged in a grid
/// Uses [systemStats] data from a central source to ensure
/// synchronization with menu bar display
class SystemStatsPanel extends StatelessWidget {
  final double scale;
  final AppThemeColors themeColors;
  final SystemStatsData systemStats;

  const SystemStatsPanel({
    super.key,
    required this.scale,
    required this.themeColors,
    required this.systemStats,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}K';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = AppConstants.systemStatBoxSize * scale;
    final spacing = AppConstants.systemStatSpacing * scale;

    // Calculate positions for the 5 stat boxes around the character
    // Top row: 3 boxes (left, center, right) - positioned near top of character area
    // Bottom row: 2 boxes (left, right) - positioned at the sides

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final topRowY = 0.0;
        final sideOffset = spacing * 4; // CPU and RAM are lower than GPU
        final bottomRowY = boxSize + spacing;

        // Horizontal spacing for top row (3 items) - larger separation
        final topRowSpacing = boxSize + spacing * 0;

        return SizedBox(
          width: constraints.maxWidth,
          height: boxSize * 2 + spacing,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top Left - CPU
              Positioned(
                left: centerX - topRowSpacing - boxSize / 2,
                top: topRowY + sideOffset,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: SystemStatBox(
                    label: 'CPU',
                    value: '${systemStats.cpuUsage.toStringAsFixed(0)}%',
                    scale: scale,
                    themeColors: themeColors,
                    progress: systemStats.cpuUsage / 100,
                  ),
                ),
              ),
              // Top Center - GPU
              Positioned(
                left: centerX - boxSize / 2,
                top: topRowY,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: SystemStatBox(
                    label: 'GPU',
                    value: '${systemStats.gpuUsage.toStringAsFixed(0)}%',
                    scale: scale,
                    themeColors: themeColors,
                    progress: systemStats.gpuUsage / 100,
                  ),
                ),
              ),
              // Top Right - RAM
              Positioned(
                left: centerX + topRowSpacing - boxSize / 2,
                top: topRowY + sideOffset,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: SystemStatBox(
                    label: 'RAM',
                    value: '${systemStats.ramUsage.toStringAsFixed(0)}%',
                    scale: scale,
                    themeColors: themeColors,
                    progress: systemStats.ramUsage / 100,
                  ),
                ),
              ),
              // Bottom Left - DISK (positioned at left edge)
              Positioned(
                left: spacing,
                top: bottomRowY,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: SystemStatBox(
                    label: 'DISK',
                    value: '${systemStats.diskUsage.toStringAsFixed(0)}%',
                    scale: scale,
                    themeColors: themeColors,
                    progress: systemStats.diskUsage / 100,
                  ),
                ),
              ),
              // Bottom Right - NET (positioned at right edge)
              Positioned(
                right: spacing,
                top: bottomRowY,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: _NetworkStatBox(
                    upload: systemStats.networkUpload,
                    download: systemStats.networkDownload,
                    formatBytes: _formatBytes,
                    scale: scale,
                    themeColors: themeColors,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
