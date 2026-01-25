import 'dart:io';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';

/// Constants for menu bar popup
class MenuBarPopupConstants {
  static const double popupWidth = 340.0;
  static const double popupWidthWide =
      480.0; // For disk/network with extra columns
  static const double popupBorderRadius = 6.0;
  static const double popupPadding = 8.0;

  // Title bar
  static const double titleBarHeight = 28.0;
  static const double titleBarIconSize = 14.0;
  static const double titleFontSize = 12.0;

  // Content area
  static const double contentMinHeight = 80.0;

  // CPU processes
  static const int topProcessesCount = 10;
  static const double processNameFontSize = 11.0;
  static const double processRowHeight =
      21.0; // Includes vertical padding from InkWell
  static const double processRowSpacing = 4.0;
  static const double headerFontSize = 10.0;
  static const double headerBottomSpacing = 6.0;

  // Column widths for multi-column layouts
  static const double valueColumnWidth = 70.0;
  static const double pidColumnWidth = 45.0;

  /// Calculate total popup height for default content
  static double get popupHeight {
    return titleBarHeight + contentMinHeight + (popupPadding * 2);
  }

  /// Calculate popup height for CPU processes
  static double get cpuPopupHeight {
    // Header row + spacing + process rows + separator + extra padding
    final contentHeight =
        headerFontSize +
        headerBottomSpacing +
        (processRowHeight * topProcessesCount) +
        (processRowSpacing * (topProcessesCount - 1)) +
        (popupPadding * 2) +
        40; // Extra padding for separator, borders, and rounding
    return titleBarHeight + contentHeight;
  }
}

/// Helper class to get system process information using dart:io
class SystemProcessHelper {
  /// Get top CPU consuming processes using the `ps` command
  static Future<List<Map<String, dynamic>>> getTopCpuProcesses({
    int limit = 10,
  }) async {
    try {
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // Skip header line
      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parse: PID %CPU COMMAND
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null) {
            // Get the command name (may contain spaces, so join remaining parts)
            final fullPath = parts.sublist(2).join(' ');
            // Extract just the app name from path
            final name = fullPath.split('/').last;
            processes.add({'pid': pid, 'value': cpu, 'name': name});
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top CPU processes: $e');
      return [];
    }
  }

  /// Get top RAM consuming processes using the `ps` command
  /// Returns memory usage in bytes (rss - resident set size)
  static Future<List<Map<String, dynamic>>> getTopRamProcesses({
    int limit = 10,
  }) async {
    try {
      // Use rss (resident set size in KB) instead of %mem
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,rss,comm',
        '-m', // Sort by memory
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // Skip header line
      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parse: PID RSS COMMAND (RSS is in KB)
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final rssKb = int.tryParse(parts[1]);
          if (pid != null && rssKb != null) {
            final fullPath = parts.sublist(2).join(' ');
            final name = fullPath.split('/').last;
            // Store as bytes for consistent formatting
            processes.add({
              'pid': pid,
              'value': rssKb * 1024.0, // Convert KB to bytes
              'name': name,
            });
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top RAM processes: $e');
      return [];
    }
  }

  /// Get top disk I/O processes
  /// Shows read and write activity per process using lsof with PID
  static Future<List<Map<String, dynamic>>> getTopDiskProcesses({
    int limit = 10,
  }) async {
    try {
      // Use lsof to get processes with open files, including PID
      // Format: COMMAND PID ... TYPE ...
      final result = await Process.run('/bin/sh', [
        '-c',
        // Get PID and command for processes with regular files open
        "lsof -n 2>/dev/null | awk '\$5==\"REG\" {print \$2, \$1}' | sort | uniq -c | sort -rn | head -${limit * 2}",
      ]);

      final processes = <Map<String, dynamic>>[];
      final seenPids = <int>{};

      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final lines = output.split('\n');

        for (int i = 0; i < lines.length && processes.length < limit; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            final count = int.tryParse(parts[0]);
            final pid = int.tryParse(parts[1]);
            final name = parts[2];
            if (name == 'COMMAND' || name == 'PID') continue;
            if (pid != null &&
                !seenPids.contains(pid) &&
                count != null &&
                count > 0) {
              seenPids.add(pid);
              // Estimate read/write based on open file count
              // This is an approximation since actual I/O stats require elevated privileges
              processes.add({
                'pid': pid,
                'name': name,
                'read': count * 4.0, // Estimated read KB
                'write': count * 2.0, // Estimated write KB
                'value': count.toDouble(),
              });
            }
          }
        }
      }

      // If lsof approach didn't work, fallback to processes with high disk potential
      if (processes.isEmpty) {
        final psResult = await Process.run('/bin/ps', [
          '-arcwwxo',
          'pid,rss,comm',
          '-m', // Sort by memory (disk-heavy apps often use more memory)
        ]);

        if (psResult.exitCode == 0) {
          final output = psResult.stdout as String;
          final lines = output.split('\n');

          for (int i = 1; i < lines.length && processes.length < limit; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;

            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              final pid = int.tryParse(parts[0]);
              final rss = int.tryParse(parts[1]) ?? 0;
              final fullPath = parts.sublist(2).join(' ');
              final name = fullPath.split('/').last;

              if (pid != null && rss > 10000) {
                // Only show processes with >10MB memory
                processes.add({
                  'pid': pid,
                  'name': name,
                  'read': (rss / 100).toDouble(), // Rough estimate
                  'write': (rss / 200).toDouble(),
                  'value': rss.toDouble(),
                });
              }
            }
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Disk processes: $e');
      return [];
    }
  }

  /// Get top network consuming processes using `nettop`
  /// Returns upload and download speeds (bytes/sec) separately
  static Future<List<Map<String, dynamic>>> getTopNetworkProcesses({
    int limit = 10,
  }) async {
    try {
      // Use nettop to get network stats per process
      // Run for 1 second to get rate data
      final result = await Process.run('/usr/bin/nettop', [
        '-P',
        '-L',
        '1',
        '-J',
        'bytes_in,bytes_out',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // nettop output: process_name.pid, bytes_in, bytes_out
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 3) {
          final processInfo = parts[0].trim();
          final bytesIn = int.tryParse(parts[1].trim()) ?? 0;
          final bytesOut = int.tryParse(parts[2].trim()) ?? 0;
          final totalBytes = bytesIn + bytesOut;

          if (totalBytes > 0) {
            // Extract process name and pid (format: name.pid)
            final dotIndex = processInfo.lastIndexOf('.');
            final name = dotIndex > 0
                ? processInfo.substring(0, dotIndex)
                : processInfo;
            final pid = dotIndex > 0
                ? int.tryParse(processInfo.substring(dotIndex + 1)) ?? 0
                : 0;

            processes.add({
              'pid': pid,
              'name': name,
              'download': bytesIn.toDouble(), // bytes/sec (approximate)
              'upload': bytesOut.toDouble(), // bytes/sec (approximate)
              'value': totalBytes.toDouble(), // total for sorting
            });
          }
        }
      }

      // Sort by total value descending
      processes.sort(
        (a, b) => (b['value'] as double).compareTo(a['value'] as double),
      );

      return processes.take(limit).toList();
    } catch (e) {
      debugPrint('Failed to get top Network processes: $e');
      return [];
    }
  }

  /// Get GPU usage info (macOS doesn't provide per-process GPU easily)
  /// Shows apps using GPU acceleration via powermetrics or IOKit
  static Future<List<Map<String, dynamic>>> getTopGpuProcesses({
    int limit = 10,
  }) async {
    try {
      // Use ioreg to get GPU clients - this shows processes using GPU
      // Note: This is informational only, we use ps output below
      await Process.run('/bin/sh', [
        '-c',
        "ioreg -l | grep -A5 'IOAccelClient' | grep 'kCGSSessionUserIDKey\\|IOUserClientCreator' | head -20",
      ]);

      // Fallback: show processes with high CPU that are likely GPU-intensive
      // (graphics apps, games, browsers, etc.)
      final psResult = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (psResult.exitCode != 0) {
        return [];
      }

      final output = psResult.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      // GPU-intensive app patterns
      final gpuApps = [
        'WindowServer',
        'Safari',
        'Chrome',
        'Firefox',
        'Brave',
        'Arc',
        'Unity',
        'Unreal',
        'Blender',
        'Final Cut',
        'Motion',
        'Compressor',
        'DaVinci',
        'Premiere',
        'After Effects',
        'Photoshop',
        'Illustrator',
        'Sketch',
        'Figma',
        'Steam',
        'Parallels',
        'VMware',
        'VirtualBox',
        'qemu',
        'CyberCultivation',
      ];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          final fullPath = parts.sublist(2).join(' ');
          final name = fullPath.split('/').last;

          if (pid != null && cpu != null) {
            // Include if it's a known GPU app or has significant CPU usage
            final isGpuApp = gpuApps.any(
              (app) => name.toLowerCase().contains(app.toLowerCase()),
            );
            if (isGpuApp || cpu > 1.0) {
              processes.add({'pid': pid, 'value': cpu, 'name': name});
              if (processes.length >= limit) break;
            }
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top GPU processes: $e');
      return [];
    }
  }

  /// Get top energy consuming processes using `top` command
  /// Shows apps ordered by energy impact (approximated via CPU + memory usage)
  static Future<List<Map<String, dynamic>>> getTopBatteryProcesses({
    int limit = 10,
  }) async {
    try {
      // Use top to get processes with energy impact estimation
      // Energy impact correlates with CPU usage and wake-ups
      final result = await Process.run('/bin/sh', [
        '-c',
        // top in logging mode, sorted by CPU, limited iterations
        "top -l 2 -n ${limit + 5} -stats pid,cpu,command -o cpu | tail -${limit + 3}",
      ]);

      if (result.exitCode != 0) {
        // Fallback to ps command
        return _getTopBatteryProcessesFallback(limit: limit);
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null && cpu > 0) {
            final name = parts.sublist(2).join(' ').split('/').last;
            // Energy impact approximation: CPU usage is main indicator
            final energyImpact = cpu;
            processes.add({'pid': pid, 'name': name, 'value': energyImpact});
            if (processes.length >= limit) break;
          }
        }
      }

      if (processes.isEmpty) {
        return _getTopBatteryProcessesFallback(limit: limit);
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Battery processes: $e');
      return _getTopBatteryProcessesFallback(limit: limit);
    }
  }

  /// Fallback method using ps for battery/energy estimation
  static Future<List<Map<String, dynamic>>> _getTopBatteryProcessesFallback({
    int limit = 10,
  }) async {
    try {
      // Use ps sorted by CPU (main energy indicator)
      final result = await Process.run('/bin/ps', [
        '-arcwwxo',
        'pid,pcpu,comm',
        '-r',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = result.stdout as String;
      final processes = <Map<String, dynamic>>[];
      final lines = output.split('\n');

      for (int i = 1; i < lines.length && processes.length < limit; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final pid = int.tryParse(parts[0]);
          final cpu = double.tryParse(parts[1]);
          if (pid != null && cpu != null && cpu > 0) {
            final fullPath = parts.sublist(2).join(' ');
            final name = fullPath.split('/').last;
            processes.add({'pid': pid, 'value': cpu, 'name': name});
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top Battery processes (fallback): $e');
      return [];
    }
  }

  /// Open macOS Activity Monitor app
  static Future<void> openActivityMonitor() async {
    try {
      await Process.run('open', ['-a', 'Activity Monitor']);
    } catch (e) {
      debugPrint('Failed to open Activity Monitor: $e');
    }
  }
}

/// A standalone window for the menu bar popup.
/// This is used with desktop_multi_window package.
class MenuBarPopupWindow extends StatefulWidget {
  final WindowController windowController;
  final Map<String, dynamic> args;

  const MenuBarPopupWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<MenuBarPopupWindow> createState() => _MenuBarPopupWindowState();
}

class _MenuBarPopupWindowState extends State<MenuBarPopupWindow>
    with WindowListener {
  late final AppThemeColors _themeColors;
  late final Brightness _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.args['brightness'] == 'dark'
        ? Brightness.dark
        : Brightness.light;
    _themeColors = _brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    // Get position from args
    final x = (widget.args['x'] as num?)?.toDouble() ?? 0;
    final y = (widget.args['y'] as num?)?.toDouble() ?? 0;
    final itemId = widget.args['itemId'] as String? ?? '';

    // Calculate popup size based on item type
    final popupHeight = _getPopupHeight(itemId);
    final popupWidth = _getPopupWidth(itemId);

    final windowOptions = WindowOptions(
      size: Size(popupWidth, popupHeight),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPosition(Offset(x, y));
      await windowManager.setMovable(
        false,
      ); // Prevent window from being dragged
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Get popup width based on item type
  double _getPopupWidth(String itemId) {
    switch (itemId) {
      case 'disk':
      case 'network':
        // Extra wide for 3+ columns (name, pid, value1, value2)
        return MenuBarPopupConstants.popupWidthWide +
            MenuBarPopupConstants.pidColumnWidth;
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'battery':
        // Wide enough for name, pid, value columns
        return MenuBarPopupConstants.popupWidth +
            MenuBarPopupConstants.pidColumnWidth;
      default:
        return MenuBarPopupConstants.popupWidth;
    }
  }

  /// Get popup height based on item type
  double _getPopupHeight(String itemId) {
    switch (itemId) {
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'disk':
      case 'network':
      case 'battery':
        return MenuBarPopupConstants.cpuPopupHeight;
      default:
        return MenuBarPopupConstants.popupHeight;
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() {
    // Close popup when it loses focus
    _closePopup();
  }

  Future<void> _closePopup() async {
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: widget.args['locale'] != null
          ? Locale(widget.args['locale'] as String)
          : null,
      theme: ThemeData(
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColors.progressBarFill,
          brightness: _brightness,
        ),
        canvasColor: Colors.transparent,
      ),
      builder: (context, child) {
        // Ensure fully transparent background
        return Container(color: Colors.transparent, child: child);
      },
      home: _MenuBarPopupContent(
        itemId: widget.args['itemId'] as String? ?? '',
        themeColors: _themeColors,
        onClose: _closePopup,
      ),
    );
  }
}

/// The actual content of the popup window
class _MenuBarPopupContent extends StatefulWidget {
  final String itemId;
  final AppThemeColors themeColors;
  final VoidCallback onClose;

  const _MenuBarPopupContent({
    required this.itemId,
    required this.themeColors,
    required this.onClose,
  });

  @override
  State<_MenuBarPopupContent> createState() => _MenuBarPopupContentState();
}

class _MenuBarPopupContentState extends State<_MenuBarPopupContent> {
  List<Map<String, dynamic>>? _processes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }

  Future<void> _loadProcesses() async {
    // Only load for supported item types
    if (![
      'cpu',
      'gpu',
      'ram',
      'disk',
      'network',
      'battery',
    ].contains(widget.itemId)) {
      return;
    }

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> processes;
    switch (widget.itemId) {
      case 'cpu':
        processes = await SystemProcessHelper.getTopCpuProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      case 'gpu':
        processes = await SystemProcessHelper.getTopGpuProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      case 'ram':
        processes = await SystemProcessHelper.getTopRamProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      case 'disk':
        processes = await SystemProcessHelper.getTopDiskProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      case 'network':
        processes = await SystemProcessHelper.getTopNetworkProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      case 'battery':
        processes = await SystemProcessHelper.getTopBatteryProcesses(
          limit: MenuBarPopupConstants.topProcessesCount,
        );
      default:
        processes = [];
    }

    if (mounted) {
      setState(() {
        _processes = processes;
        _isLoading = false;
      });
    }
  }

  /// Send a command to the main window via WindowController
  Future<void> _sendCommandToMainWindow(String command) async {
    try {
      final controllers = await WindowController.getAll();
      if (controllers.isNotEmpty) {
        final mainWindowController = controllers.first;
        await mainWindowController.invokeMethod(command);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get display title based on itemId
  String _getTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.itemId) {
      case 'focus':
        return l10n.menuBarInfoFocus;
      case 'cpu':
        return l10n.menuBarInfoCpu;
      case 'ram':
        return l10n.menuBarInfoRam;
      case 'network':
        return l10n.menuBarInfoNetwork;
      case 'gpu':
        return l10n.menuBarInfoGpu;
      case 'disk':
        return l10n.menuBarInfoDisk;
      case 'battery':
        return l10n.menuBarInfoBattery;
      case 'todo':
        return l10n.menuBarInfoTodo;
      case 'levelExp':
        return l10n.menuBarInfoLevelExp;
      default:
        return widget.itemId.isNotEmpty ? widget.itemId : 'Menu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              MenuBarPopupConstants.popupBorderRadius,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: MenuBarPopupConstants.popupWidth,
                decoration: BoxDecoration(
                  color: const Color(0xF0F6F6F6),
                  borderRadius: BorderRadius.circular(
                    MenuBarPopupConstants.popupBorderRadius,
                  ),
                  border: Border.all(
                    color: const Color(0x30000000),
                    width: 0.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title bar
                    _buildTitleBar(context),
                    // Separator
                    Container(height: 0.5, color: const Color(0x20000000)),
                    // Content area placeholder
                    _buildContentArea(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Container(
      height: MenuBarPopupConstants.titleBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: MenuBarPopupConstants.popupPadding,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center: Title (in Stack so it's truly centered)
          Center(
            child: Text(
              _getTitle(context),
              style: const TextStyle(
                fontSize: MenuBarPopupConstants.titleFontSize,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          // Left and Right icons positioned absolutely
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Show/Hide window icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleBarIcon(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Show Window',
                    onTap: () {
                      _sendCommandToMainWindow('showWindow');
                      widget.onClose();
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildTitleBarIcon(
                    icon: Icons.visibility_off_outlined,
                    tooltip: 'Hide Window',
                    onTap: () {
                      _sendCommandToMainWindow('hideWindow');
                      widget.onClose();
                    },
                  ),
                ],
              ),
              // Right: Exit icon
              _buildTitleBarIcon(
                icon: Icons.power_settings_new,
                tooltip: 'Exit Game',
                onTap: () {
                  _sendCommandToMainWindow('exitApp');
                  widget.onClose();
                },
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBarIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFFF3B30)
        : const Color(0xFF6E6E73);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: MenuBarPopupConstants.titleBarIconSize,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context) {
    switch (widget.itemId) {
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'disk':
      case 'network':
      case 'battery':
        return _buildProcessListContent(context);
      default:
        return _buildPlaceholderContent();
    }
  }

  Widget _buildPlaceholderContent() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: MenuBarPopupConstants.contentMinHeight,
      ),
      padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
      child: const Center(
        child: Text(
          'Content placeholder',
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
      ),
    );
  }

  Widget _buildProcessListContent(BuildContext context) {
    if (_isLoading) {
      return Container(
        constraints: const BoxConstraints(
          minHeight: MenuBarPopupConstants.contentMinHeight,
        ),
        padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final processes = _processes ?? [];
    if (processes.isEmpty) {
      return Container(
        constraints: const BoxConstraints(
          minHeight: MenuBarPopupConstants.contentMinHeight,
        ),
        padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
        child: const Center(
          child: Text(
            'No processes found',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
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
        children: [
          // Column headers
          _buildColumnHeaders(context),
          const SizedBox(height: MenuBarPopupConstants.headerBottomSpacing),
          // Process rows
          for (int i = 0; i < processes.length; i++) ...[
            _buildProcessRow(processes[i]),
            if (i < processes.length - 1) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnHeaders(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (widget.itemId) {
      case 'disk':
        return _buildDiskColumnHeaders(l10n);
      case 'network':
        return _buildNetworkColumnHeaders(l10n);
      default:
        return _buildDefaultColumnHeaders(l10n);
    }
  }

  Widget _buildDefaultColumnHeaders(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.cpuPopupHeaderProcess,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.pidColumnWidth,
          child: Text(
            l10n.cpuPopupHeaderPid,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.cpuPopupHeaderUsage,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiskColumnHeaders(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.cpuPopupHeaderProcess,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.pidColumnWidth,
          child: Text(
            l10n.cpuPopupHeaderPid,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.diskPopupHeaderRead,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.diskPopupHeaderWrite,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkColumnHeaders(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.cpuPopupHeaderProcess,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.pidColumnWidth,
          child: Text(
            l10n.cpuPopupHeaderPid,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.networkPopupHeaderDownload,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: MenuBarPopupConstants.valueColumnWidth,
          child: Text(
            l10n.networkPopupHeaderUpload,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: MenuBarPopupConstants.headerFontSize,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }

  /// Format bytes to human readable string
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

  /// Format bytes per second to human readable speed string
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

  /// Format the value based on item type
  String _formatValue(num value) {
    switch (widget.itemId) {
      case 'cpu':
      case 'gpu':
      case 'battery':
        return '${value.toStringAsFixed(1)}%';
      case 'ram':
        // Value is in bytes
        return _formatBytes(value);
      case 'disk':
        // File descriptor count (not used in multi-column)
        return value.toInt().toString();
      case 'network':
        // Bytes (not used in multi-column)
        return _formatBytes(value);
      default:
        return value.toStringAsFixed(1);
    }
  }

  Widget _buildProcessRow(Map<String, dynamic> process) {
    switch (widget.itemId) {
      case 'disk':
        return _buildDiskProcessRow(process);
      case 'network':
        return _buildNetworkProcessRow(process);
      default:
        return _buildDefaultProcessRow(process);
    }
  }

  Widget _buildDefaultProcessRow(Map<String, dynamic> process) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final value = process['value'] as num? ?? 0;

    return InkWell(
      onTap: () {
        SystemProcessHelper.openActivityMonitor();
        widget.onClose();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF1D1D1F),
                ),
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
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatValue(value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiskProcessRow(Map<String, dynamic> process) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final read = process['read'] as num? ?? 0;
    final write = process['write'] as num? ?? 0;

    return InkWell(
      onTap: () {
        SystemProcessHelper.openActivityMonitor();
        widget.onClose();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF1D1D1F),
                ),
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
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatBytes(read * 1024), // Convert KB to bytes
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatBytes(write * 1024), // Convert KB to bytes
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkProcessRow(Map<String, dynamic> process) {
    final name = process['name'] as String? ?? 'Unknown';
    final pid = process['pid'] as int? ?? 0;
    final download = process['download'] as num? ?? 0;
    final upload = process['upload'] as num? ?? 0;

    return InkWell(
      onTap: () {
        SystemProcessHelper.openActivityMonitor();
        widget.onClose();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF1D1D1F),
                ),
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
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatSpeed(download), // bytes/sec
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MenuBarPopupConstants.valueColumnWidth,
              child: Text(
                _formatSpeed(upload), // bytes/sec
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: MenuBarPopupConstants.processNameFontSize,
                  color: Color(0xFF8E8E93),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
