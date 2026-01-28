import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/daily_stats.dart';
import '../../models/game_data.dart';
import '../../services/game_data_service.dart';
import '../../services/system_process_helper.dart';
import '../../services/window_pool_service.dart';
import 'info_content.dart';
import 'menu_bar_popup_constants.dart';
import 'popup_styles.dart';
import 'popup_title_bar.dart';
import 'popup_widgets.dart';
import 'process_list_content.dart';

/// A pre-warmed pooled window for menu bar popups.
///
/// Unlike [MenuBarPopupWindow], this window is created at app startup and
/// stays hidden until needed. When a popup is requested, the window receives
/// new content via method channel and shows itself, providing near-instant
/// popup appearance.
class PooledPopupWindow extends StatefulWidget {
  final WindowController windowController;
  final Map<String, dynamic> initialArgs;

  const PooledPopupWindow({
    super.key,
    required this.windowController,
    required this.initialArgs,
  });

  @override
  State<PooledPopupWindow> createState() => _PooledPopupWindowState();
}

class _PooledPopupWindowState extends State<PooledPopupWindow>
    with WindowListener {
  // Current display state
  late Map<String, dynamic> _currentArgs;
  late AppThemeColors _themeColors;
  late Brightness _brightness;
  bool _isVisible = false;
  bool _isInitialized = false;

  // Pool tracking
  late final int _poolIndex;

  @override
  void initState() {
    super.initState();
    _currentArgs = Map<String, dynamic>.from(widget.initialArgs);
    _poolIndex = widget.initialArgs['poolIndex'] as int? ?? 0;

    _updateTheme();
    _setupMethodHandler();
    _initWindow();
  }

  void _updateTheme() {
    _brightness = _currentArgs['brightness'] == 'dark'
        ? Brightness.dark
        : Brightness.light;
    _themeColors = _brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
  }

  /// Set up method handler for receiving commands from the main window
  void _setupMethodHandler() {
    widget.windowController.setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'updateContent':
          await _handleUpdateContent(call.arguments as Map<dynamic, dynamic>);
          return true;
        case 'hideWindow':
          await _hideWindow();
          return true;
        default:
          return null;
      }
    });
  }

  /// Handle content update and show the window
  Future<void> _handleUpdateContent(Map<dynamic, dynamic> args) async {
    // Convert to proper type
    final newArgs = <String, dynamic>{};
    args.forEach((key, value) {
      newArgs[key.toString()] = value;
    });

    // Update state
    setState(() {
      _currentArgs = newArgs;
      _updateTheme();
    });

    // Show the window at the new position
    await _showWindow();
  }

  /// Initialize window properties (called once at startup)
  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    // Set up window properties that don't change
    await Future.wait([
      windowManager.setBackgroundColor(Colors.transparent),
      windowManager.setSkipTaskbar(true),
      windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
      windowManager.setAlwaysOnTop(true),
      windowManager.setResizable(false),
      windowManager.setMovable(false),
    ]);

    _isInitialized = true;
    debugPrint('[PooledWindow $_poolIndex] Initialized and ready');
  }

  /// Show the window with current content
  Future<void> _showWindow() async {
    if (!_isInitialized) {
      await _initWindow();
    }

    final x = (_currentArgs['x'] as num?)?.toDouble() ?? 0;
    final y = (_currentArgs['y'] as num?)?.toDouble() ?? 0;
    final itemId = _currentArgs['itemId'] as String? ?? '';

    final popupHeight = _getPopupHeight(itemId);
    final popupWidth = _getPopupWidth(itemId);

    // Update size and position
    await windowManager.setSize(Size(popupWidth, popupHeight));
    await windowManager.setPosition(Offset(x, y));

    // Show and focus
    await windowManager.show();
    windowManager.focus();

    setState(() {
      _isVisible = true;
    });

    debugPrint('[PooledWindow $_poolIndex] Shown at ($x, $y) for $itemId');
  }

  /// Hide the window and notify the pool
  Future<void> _hideWindow() async {
    if (!_isVisible) return;

    await windowManager.hide();

    setState(() {
      _isVisible = false;
      // Reset to empty state
      _currentArgs = {
        'itemId': '',
        'brightness': _currentArgs['brightness'],
        'locale': _currentArgs['locale'],
      };
    });

    debugPrint('[PooledWindow $_poolIndex] Hidden');
  }

  /// Get popup width based on item type
  double _getPopupWidth(String itemId) {
    switch (itemId) {
      case 'disk':
      case 'network':
        return MenuBarPopupConstants.popupWidthWide +
            MenuBarPopupConstants.pidColumnWidth;
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'battery':
        return MenuBarPopupConstants.popupWidth +
            MenuBarPopupConstants.pidColumnWidth;
      default:
        return MenuBarPopupConstants.popupWidth;
    }
  }

  /// Get popup height based on item type
  double _getPopupHeight(String itemId) {
    switch (itemId) {
      case 'network':
        return MenuBarPopupConstants.networkPopupHeight;
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'disk':
      case 'battery':
      case 'todo':
        return MenuBarPopupConstants.cpuPopupHeight;
      case 'levelExp':
      case 'focus':
      case 'keyboard':
      case 'mouse':
        return MenuBarPopupConstants.popupHeightMedium;
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
    // When window loses focus, hide it and notify pool
    _onClosePopup();
  }

  Future<void> _onClosePopup() async {
    if (!_isVisible) return;

    await _hideWindow();

    // Notify the pool that this window is available again
    WindowPoolService.instance.onWindowHidden(_poolIndex);
  }

  @override
  Widget build(BuildContext context) {
    final locale = _currentArgs['locale'] as String?;
    final itemId = _currentArgs['itemId'] as String? ?? '';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale != null ? Locale(locale) : null,
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
        return Container(color: Colors.transparent, child: child);
      },
      home: _isVisible && itemId.isNotEmpty
          ? _PooledPopupContent(
              key: ValueKey('$itemId-${DateTime.now().millisecondsSinceEpoch}'),
              itemId: itemId,
              args: _currentArgs,
              themeColors: _themeColors,
              onClose: _onClosePopup,
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The actual content of the pooled popup window
class _PooledPopupContent extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> args;
  final AppThemeColors themeColors;
  final VoidCallback onClose;

  const _PooledPopupContent({
    super.key,
    required this.itemId,
    required this.args,
    required this.themeColors,
    required this.onClose,
  });

  @override
  State<_PooledPopupContent> createState() => _PooledPopupContentState();
}

class _PooledPopupContentState extends State<_PooledPopupContent> {
  List<Map<String, dynamic>>? _processes;
  bool _isLoading = false;
  GameData? _gameData;
  DailyStats? _todayStats;

  // Focus state from args
  bool get _focusIsActive => widget.args['focusIsActive'] as bool? ?? false;
  bool get _focusIsRelaxing => widget.args['focusIsRelaxing'] as bool? ?? false;
  int get _focusSecondsRemaining =>
      widget.args['focusSecondsRemaining'] as int? ?? 0;
  int get _focusCurrentLoop => widget.args['focusCurrentLoop'] as int? ?? 1;
  int get _focusTotalLoops => widget.args['focusTotalLoops'] as int? ?? 1;

  // Level/Exp state from args
  int get _level => widget.args['level'] as int? ?? 1;
  double get _currentExp =>
      (widget.args['currentExp'] as num?)?.toDouble() ?? 0;
  double get _maxExp =>
      (widget.args['maxExp'] as num?)?.toDouble() ?? AppConstants.initialMaxExp;

  /// Get content width based on item type
  double _getContentWidth() {
    switch (widget.itemId) {
      case 'disk':
      case 'network':
        return MenuBarPopupConstants.popupWidthWide +
            MenuBarPopupConstants.pidColumnWidth;
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'battery':
        return MenuBarPopupConstants.popupWidth +
            MenuBarPopupConstants.pidColumnWidth;
      default:
        return MenuBarPopupConstants.popupWidth;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if ([
      'cpu',
      'gpu',
      'ram',
      'disk',
      'network',
      'battery',
    ].contains(widget.itemId)) {
      await _loadProcesses();
    }

    if ([
      'focus',
      'todo',
      'levelExp',
      'keyboard',
      'mouse',
    ].contains(widget.itemId)) {
      await _loadGameData();
    }
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);

    try {
      final gameDataService = GameDataService();
      final gameData = await gameDataService.loadGameData();

      if (mounted && gameData != null) {
        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayStats = gameData.dailyStats[todayKey] ?? DailyStats();

        setState(() {
          _gameData = gameData;
          _todayStats = todayStats;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProcesses() async {
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

  /// Platform channel to communicate with native code
  static const MethodChannel _nativeChannel = MethodChannel('menu_bar_helper');

  /// Send a command to control the main window via native platform channel
  Future<void> _sendCommandToMainWindow(String command) async {
    try {
      await _nativeChannel.invokeMethod(command);
    } catch (e) {
      // Ignore errors - channel might not be available
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
      body: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              MenuBarPopupConstants.popupBorderRadius,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: _getContentWidth(),
                decoration: BoxDecoration(
                  color: PopupColors.background,
                  borderRadius: BorderRadius.circular(
                    MenuBarPopupConstants.popupBorderRadius,
                  ),
                  border: Border.all(color: PopupColors.border, width: 0.5),
                  boxShadow: const [
                    BoxShadow(
                      color: PopupColors.shadow,
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title bar
                    PopupTitleBar(
                      title: _getTitle(context),
                      onShowWindow: () {
                        _sendCommandToMainWindow('showWindow');
                        widget.onClose();
                      },
                      onHideWindow: () {
                        _sendCommandToMainWindow('hideWindow');
                        widget.onClose();
                      },
                      onExitApp: () {
                        _sendCommandToMainWindow('exitApp');
                        widget.onClose();
                      },
                    ),
                    // Separator
                    Container(height: 0.5, color: PopupColors.separator),
                    // Content area
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

  Widget _buildContentArea(BuildContext context) {
    switch (widget.itemId) {
      case 'cpu':
      case 'gpu':
      case 'ram':
      case 'disk':
      case 'battery':
        return ProcessListContent(
          itemId: widget.itemId,
          processes: _processes,
          isLoading: _isLoading,
          onClose: widget.onClose,
        );
      case 'network':
        return NetworkContent(
          processes: _processes,
          isLoading: _isLoading,
          onClose: widget.onClose,
        );
      case 'focus':
        return FocusContent(
          focusIsActive: _focusIsActive,
          focusIsRelaxing: _focusIsRelaxing,
          focusSecondsRemaining: _focusSecondsRemaining,
          focusCurrentLoop: _focusCurrentLoop,
          focusTotalLoops: _focusTotalLoops,
        );
      case 'todo':
        return TodoContent(
          todos: _gameData?.todos ?? [],
          isLoading: _isLoading,
        );
      case 'levelExp':
        return LevelExpContent(
          level: _level,
          currentExp: _currentExp,
          maxExp: _maxExp,
        );
      case 'keyboard':
        return KeyboardContent(
          keyCount: _todayStats?.keyboardCount ?? 0,
          isLoading: _isLoading,
        );
      case 'mouse':
        return MouseContent(
          distance: _todayStats?.mouseMoveDistance ?? 0,
          isLoading: _isLoading,
        );
      default:
        return PopupWidgets.buildEmpty('Content placeholder');
    }
  }
}
