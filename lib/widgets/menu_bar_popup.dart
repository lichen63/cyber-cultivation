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
  static const double popupWidth = 280.0;
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
  static const double processRowHeight = 21.0; // Includes vertical padding from InkWell
  static const double processRowSpacing = 4.0;
  static const double headerFontSize = 10.0;
  static const double headerBottomSpacing = 6.0;

  /// Calculate total popup height for default content
  static double get popupHeight {
    return titleBarHeight + contentMinHeight + (popupPadding * 2);
  }

  /// Calculate popup height for CPU processes
  static double get cpuPopupHeight {
    // Header row + spacing + process rows
    final contentHeight =
        headerFontSize +
        headerBottomSpacing +
        (processRowHeight * topProcessesCount) +
        (processRowSpacing * (topProcessesCount - 1)) +
        (popupPadding * 2);
    return titleBarHeight + contentHeight;
  }
}

/// Helper class to get top CPU processes using dart:io
class CpuProcessHelper {
  /// Get top CPU consuming processes using the `ps` command
  static Future<List<Map<String, dynamic>>> getTopCpuProcesses({
    int limit = 5,
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
            processes.add({'pid': pid, 'cpu': cpu, 'name': name});
          }
        }
      }

      return processes;
    } catch (e) {
      debugPrint('Failed to get top CPU processes: $e');
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

    // Calculate popup height based on item type
    final popupHeight = itemId == 'cpu'
        ? MenuBarPopupConstants.cpuPopupHeight
        : MenuBarPopupConstants.popupHeight;

    final windowOptions = WindowOptions(
      size: Size(MenuBarPopupConstants.popupWidth, popupHeight),
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
  List<Map<String, dynamic>>? _cpuProcesses;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId == 'cpu') {
      _loadCpuProcesses();
    }
  }

  Future<void> _loadCpuProcesses() async {
    setState(() => _isLoading = true);
    final processes = await CpuProcessHelper.getTopCpuProcesses(
      limit: MenuBarPopupConstants.topProcessesCount,
    );
    if (mounted) {
      setState(() {
        _cpuProcesses = processes;
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
        return _buildCpuContent(context);
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

  Widget _buildCpuContent(BuildContext context) {
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

    final processes = _cpuProcesses ?? [];
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
        Text(
          l10n.cpuPopupHeaderUsage,
          style: const TextStyle(
            fontSize: MenuBarPopupConstants.headerFontSize,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessRow(Map<String, dynamic> process) {
    final name = process['name'] as String? ?? 'Unknown';
    final cpu = process['cpu'] as num? ?? 0;

    return InkWell(
      onTap: () {
        CpuProcessHelper.openActivityMonitor();
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
            Text(
              '${cpu.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: MenuBarPopupConstants.processNameFontSize,
                color: Color(0xFF8E8E93),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
