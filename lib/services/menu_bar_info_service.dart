import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/menu_bar_settings.dart';
import '../models/todo_item.dart';
import '../services/menu_bar_helper.dart';
import '../services/pomodoro_service.dart';
import '../widgets/system_stats_panel.dart';

/// Data class to hold all info needed for menu bar display
class MenuBarInfoData {
  final PomodoroState? pomodoroState;
  final List<TodoItem> todos;
  final int level;
  final double currentExp;
  final double maxExp;
  final double cpuUsage;
  final double gpuUsage;
  final double ramUsage;
  final double diskUsage;
  final int networkUpload;
  final int networkDownload;
  final String currentKey;
  final int todayMouseDistance;
  final int todayKeyboardCount;
  final int batteryLevel;
  final bool isBatteryCharging;

  const MenuBarInfoData({
    this.pomodoroState,
    this.todos = const [],
    this.level = 1,
    this.currentExp = 0,
    this.maxExp = 100,
    this.cpuUsage = 0,
    this.gpuUsage = 0,
    this.ramUsage = 0,
    this.diskUsage = 0,
    this.networkUpload = 0,
    this.networkDownload = 0,
    this.currentKey = '',
    this.todayMouseDistance = 0,
    this.todayKeyboardCount = 0,
    this.batteryLevel = -1,
    this.isBatteryCharging = false,
  });

  MenuBarInfoData copyWith({
    PomodoroState? pomodoroState,
    List<TodoItem>? todos,
    int? level,
    double? currentExp,
    double? maxExp,
    double? cpuUsage,
    double? gpuUsage,
    double? ramUsage,
    double? diskUsage,
    int? networkUpload,
    int? networkDownload,
    String? currentKey,
    int? todayMouseDistance,
    int? todayKeyboardCount,
    int? batteryLevel,
    bool? isBatteryCharging,
  }) {
    return MenuBarInfoData(
      pomodoroState: pomodoroState ?? this.pomodoroState,
      todos: todos ?? this.todos,
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      maxExp: maxExp ?? this.maxExp,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      gpuUsage: gpuUsage ?? this.gpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      networkUpload: networkUpload ?? this.networkUpload,
      networkDownload: networkDownload ?? this.networkDownload,
      currentKey: currentKey ?? this.currentKey,
      todayMouseDistance: todayMouseDistance ?? this.todayMouseDistance,
      todayKeyboardCount: todayKeyboardCount ?? this.todayKeyboardCount,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isBatteryCharging: isBatteryCharging ?? this.isBatteryCharging,
    );
  }
}

/// Service that builds the menu bar title string based on enabled info types
class MenuBarInfoService extends ChangeNotifier {
  Timer? _statsTimer;
  MenuBarInfoData _data = const MenuBarInfoData();
  MenuBarSettings _settings = const MenuBarSettings();
  int _refreshSeconds = AppConstants.defaultSystemStatsRefreshSeconds;

  /// Simulation mode for testing battery on devices without batteries
  bool _simulateBattery = false;
  int _simulatedBatteryLevel = 59;
  bool _simulatedBatteryCharging = true;

  MenuBarInfoData get data => _data;
  MenuBarSettings get settings => _settings;

  /// Whether battery simulation is enabled
  bool get isSimulatingBattery => _simulateBattery;

  /// Get the current simulated battery level
  int get simulatedBatteryLevel => _simulatedBatteryLevel;

  /// Get the current simulated charging state
  bool get simulatedBatteryCharging => _simulatedBatteryCharging;

  /// Toggle battery simulation mode (for testing on Macs without battery)
  void toggleBatterySimulation() {
    _simulateBattery = !_simulateBattery;
    notifyListeners();
  }

  /// Set simulated battery values
  void setSimulatedBattery({int? level, bool? isCharging}) {
    if (level != null) _simulatedBatteryLevel = level.clamp(0, 100);
    if (isCharging != null) _simulatedBatteryCharging = isCharging;
    notifyListeners();
  }

  /// Initialize the service with optional refresh interval
  void initialize({int? refreshSeconds}) {
    _refreshSeconds =
        refreshSeconds ?? AppConstants.defaultSystemStatsRefreshSeconds;
    _startStatsTimer();
    _updateSystemStats();
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      Duration(seconds: _refreshSeconds),
      (_) => _updateSystemStats(),
    );
  }

  /// Update the refresh interval
  void updateRefreshInterval(int seconds) {
    if (seconds != _refreshSeconds) {
      _refreshSeconds = seconds;
      _startStatsTimer();
    }
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  /// Update settings and notify listeners for immediate UI update
  void updateSettings(MenuBarSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Update all info data (with notification)
  void updateData({
    PomodoroState? pomodoroState,
    List<TodoItem>? todos,
    int? level,
    double? currentExp,
    double? maxExp,
    String? currentKey,
    int? todayMouseDistance,
  }) {
    _updateDataInternal(
      pomodoroState: pomodoroState,
      todos: todos,
      level: level,
      currentExp: currentExp,
      maxExp: maxExp,
      currentKey: currentKey,
      todayMouseDistance: todayMouseDistance,
    );
    notifyListeners();
  }

  /// Update all info data silently (without notification, to avoid recursion)
  void updateDataSilently({
    PomodoroState? pomodoroState,
    List<TodoItem>? todos,
    int? level,
    double? currentExp,
    double? maxExp,
    String? currentKey,
    int? todayMouseDistance,
    int? todayKeyboardCount,
  }) {
    _updateDataInternal(
      pomodoroState: pomodoroState,
      todos: todos,
      level: level,
      currentExp: currentExp,
      maxExp: maxExp,
      currentKey: currentKey,
      todayMouseDistance: todayMouseDistance,
      todayKeyboardCount: todayKeyboardCount,
    );
  }

  void _updateDataInternal({
    PomodoroState? pomodoroState,
    List<TodoItem>? todos,
    int? level,
    double? currentExp,
    double? maxExp,
    String? currentKey,
    int? todayMouseDistance,
    int? todayKeyboardCount,
  }) {
    _data = _data.copyWith(
      pomodoroState: pomodoroState,
      todos: todos,
      level: level,
      currentExp: currentExp,
      maxExp: maxExp,
      currentKey: currentKey,
      todayMouseDistance: todayMouseDistance,
      todayKeyboardCount: todayKeyboardCount,
    );
  }

  Future<void> _updateSystemStats() async {
    try {
      final stats = await SystemInfoService.getAllStats();

      // Use simulated battery values if simulation is enabled
      final batteryLevel = _simulateBattery
          ? _simulatedBatteryLevel
          : (stats['batteryLevel'] as num?)?.toInt() ?? -1;
      final isBatteryCharging = _simulateBattery
          ? _simulatedBatteryCharging
          : (stats['isBatteryCharging'] as bool?) ?? false;

      _data = _data.copyWith(
        cpuUsage: (stats['cpu'] as num?)?.toDouble() ?? 0.0,
        gpuUsage: (stats['gpu'] as num?)?.toDouble() ?? 0.0,
        ramUsage: (stats['ram'] as num?)?.toDouble() ?? 0.0,
        diskUsage: (stats['disk'] as num?)?.toDouble() ?? 0.0,
        networkUpload: (stats['networkUp'] as num?)?.toInt() ?? 0,
        networkDownload: (stats['networkDown'] as num?)?.toInt() ?? 0,
        batteryLevel: batteryLevel,
        isBatteryCharging: isBatteryCharging,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update system stats for menu bar: $e');
    }
  }

  /// Build the menu bar title string
  /// Format: two-row format with labels on top and values on bottom
  /// Example: "Focus  CPU  RAM\n--:--  15%  54%"
  String buildMenuBarTitle() {
    final topParts = <String>[];
    final bottomParts = <String>[];

    // Order of items as specified by user
    for (final type in _getEnabledTypesInOrder()) {
      final (top, bottom) = _buildInfoPart(type);
      if (top.isNotEmpty) {
        topParts.add(top);
        bottomParts.add(bottom);
      }
    }

    if (topParts.isEmpty) {
      return '';
    }

    final topRow = topParts.join(' ');
    final bottomRow = bottomParts.join(' ');
    return '$topRow\n$bottomRow';
  }

  /// Build separate menu bar items for each enabled info type
  List<MenuBarItem> buildMenuBarItems() {
    final items = <MenuBarItem>[];

    for (final type in _getEnabledTypesInOrder()) {
      final (top, bottom) = _buildInfoPart(type);
      if (top.isNotEmpty) {
        final alignment = _getAlignmentForType(type);
        final fixedWidth = _getFixedWidthForType(type);
        final (topFontSize, bottomFontSize) = _getFontSizesForType(type);
        items.add(
          MenuBarItem(
            id: type.name,
            top: top,
            bottom: bottom,
            alignment: alignment,
            fixedWidth: fixedWidth,
            topFontSize: topFontSize,
            bottomFontSize: bottomFontSize,
          ),
        );
      }
    }

    return items;
  }

  /// Get alignment for each info type
  String _getAlignmentForType(MenuBarInfoType type) {
    switch (type) {
      case MenuBarInfoType.network:
        return 'left';
      case MenuBarInfoType.trayIcon:
      case MenuBarInfoType.focus:
      case MenuBarInfoType.todo:
      case MenuBarInfoType.levelExp:
      case MenuBarInfoType.cpu:
      case MenuBarInfoType.gpu:
      case MenuBarInfoType.ram:
      case MenuBarInfoType.disk:
      case MenuBarInfoType.keyboard:
      case MenuBarInfoType.mouse:
      case MenuBarInfoType.systemTime:
      case MenuBarInfoType.battery:
        return 'center';
    }
  }

  /// Get font sizes (top, bottom) for each info type
  (double, double) _getFontSizesForType(MenuBarInfoType type) {
    switch (type) {
      case MenuBarInfoType.levelExp:
      case MenuBarInfoType.network:
        return (10.0, 10.0); // Same size for both rows
      case MenuBarInfoType.trayIcon:
      case MenuBarInfoType.focus:
      case MenuBarInfoType.todo:
      case MenuBarInfoType.cpu:
      case MenuBarInfoType.gpu:
      case MenuBarInfoType.ram:
      case MenuBarInfoType.disk:
      case MenuBarInfoType.keyboard:
      case MenuBarInfoType.mouse:
      case MenuBarInfoType.systemTime:
      case MenuBarInfoType.battery:
        return (8.0, 12.0); // Smaller top, larger bottom
    }
  }

  /// Get fixed width in pixels for each info type
  double _getFixedWidthForType(MenuBarInfoType type) {
    switch (type) {
      case MenuBarInfoType.trayIcon:
        return 24; // Icon only
      case MenuBarInfoType.focus:
        return 50; // "🍅" + "F 25:00"
      case MenuBarInfoType.todo:
        return 35; // "✅" + "99/99"
      case MenuBarInfoType.levelExp:
        return 80; // "Lv99" + "999K/999K"
      case MenuBarInfoType.cpu:
      case MenuBarInfoType.gpu:
      case MenuBarInfoType.ram:
      case MenuBarInfoType.disk:
        return 32; // "CPU" + "100%"
      case MenuBarInfoType.network:
        return 55; // "↑ 999M/s"
      case MenuBarInfoType.keyboard:
        return 50; // "⌨️" + "999.9K"
      case MenuBarInfoType.mouse:
        return 50; // "🖱" + "99.9km"
      case MenuBarInfoType.systemTime:
        return 120; // "2026-01-19 12:34" single row
      case MenuBarInfoType.battery:
        return 45; // Battery icon with percentage inside
    }
  }

  List<MenuBarInfoType> _getEnabledTypesInOrder() {
    // Define the order as requested by user
    const order = [
      MenuBarInfoType.focus,
      MenuBarInfoType.todo,
      MenuBarInfoType.levelExp,
      MenuBarInfoType.cpu,
      MenuBarInfoType.gpu,
      MenuBarInfoType.ram,
      MenuBarInfoType.disk,
      MenuBarInfoType.network,
      MenuBarInfoType.keyboard,
      MenuBarInfoType.mouse,
      MenuBarInfoType.battery,
      MenuBarInfoType.systemTime,
    ];

    return order.where((type) => _settings.isEnabled(type)).toList();
  }

  /// Returns (topLabel, bottomValue) tuple for each info type
  (String, String) _buildInfoPart(MenuBarInfoType type) {
    switch (type) {
      case MenuBarInfoType.trayIcon:
        return ('', ''); // Not a text item
      case MenuBarInfoType.focus:
        return _buildFocusInfo();
      case MenuBarInfoType.todo:
        return _buildTodoInfo();
      case MenuBarInfoType.levelExp:
        return _buildLevelExpInfo();
      case MenuBarInfoType.cpu:
        return _buildStatInfo('CPU', _data.cpuUsage);
      case MenuBarInfoType.gpu:
        return _buildStatInfo('GPU', _data.gpuUsage);
      case MenuBarInfoType.ram:
        return _buildStatInfo('RAM', _data.ramUsage);
      case MenuBarInfoType.disk:
        return _buildStatInfo('DISK', _data.diskUsage);
      case MenuBarInfoType.network:
        return _buildNetworkInfo();
      case MenuBarInfoType.keyboard:
        return _buildKeyboardInfo();
      case MenuBarInfoType.mouse:
        return _buildMouseInfo();
      case MenuBarInfoType.systemTime:
        return _buildSystemTimeInfo();
      case MenuBarInfoType.battery:
        return _buildBatteryInfo();
    }
  }

  (String, String) _buildSystemTimeInfo() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return (date, time);
  }

  (String, String) _buildFocusInfo() {
    final state = _data.pomodoroState;
    if (state == null || !state.isActive) {
      return ('🍅', '--:--');
    }

    // Show loop info on top row (e.g., "🍅 1/4"), time with F/R prefix on bottom
    final loopInfo = '🍅 ${state.currentLoop}/${state.totalLoops}';
    final prefix = state.isRelaxing ? 'R' : 'F';
    final time = '$prefix ${state.formattedTime}';
    return (loopInfo, time);
  }

  (String, String) _buildTodoInfo() {
    final todos = _data.todos;
    final doneCount = todos.where((t) => t.status == TodoStatus.done).length;
    final totalCount = todos.length;

    // Always show checkmark emoji on top, done/all on bottom
    return ('✅', '$doneCount/$totalCount');
  }

  (String, String) _buildLevelExpInfo() {
    final level = _data.level;
    final current = _data.currentExp.isInfinite
        ? '∞'
        : _formatNumber(_data.currentExp);
    final max = _data.maxExp.isInfinite ? '∞' : _formatNumber(_data.maxExp);

    return ('Lv$level', '$current/$max');
  }

  (String, String) _buildStatInfo(String label, double usage) {
    final percentage = '${usage.toStringAsFixed(0)}%';
    return (label, percentage);
  }

  (String, String) _buildNetworkInfo() {
    final upSpeed = _formatNetworkSpeed(_data.networkUpload);
    final downSpeed = _formatNetworkSpeed(_data.networkDownload);
    return ('↑ $upSpeed', '↓ $downSpeed');
  }

  (String, String) _buildKeyboardInfo() {
    final count = _formatNumber(_data.todayKeyboardCount.toDouble());
    return ('⌨️', count);
  }

  (String, String) _buildMouseInfo() {
    final distance = _formatDistance(_data.todayMouseDistance);
    return ('🖱', distance);
  }

  (String, String) _buildBatteryInfo() {
    final level = _data.batteryLevel;
    final isCharging = _data.isBatteryCharging;

    // If battery level is -1, it means no battery (desktop Mac)
    if (level < 0) {
      return ('🔌', 'AC');
    }

    // Use special marker for battery - native code will render the icon
    // Format: "BATTERY:<level>:<charging>" for native parsing
    return ('BATTERY:$level:${isCharging ? '1' : '0'}', '');
  }

  String _formatNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  String _formatNetworkSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond}B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(0)}K/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)}M/s';
    }
  }

  String _formatDistance(int pixels) {
    // Convert pixels to kilometers (rough estimate: 96 DPI, 1 inch = 2.54 cm)
    final cm = pixels / 96 * 2.54;
    if (cm < 100) {
      return '${cm.toStringAsFixed(0)}cm';
    } else if (cm < 100000) {
      return '${(cm / 100).toStringAsFixed(1)}m';
    } else {
      return '${(cm / 100000).toStringAsFixed(1)}km';
    }
  }
}
