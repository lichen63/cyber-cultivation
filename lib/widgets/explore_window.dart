import 'dart:convert';
import 'dart:math';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/battle_result.dart';
import '../models/explore_map.dart';
import '../models/npc_effect.dart';
import 'battle_dialog.dart';
import 'explore_debug_dialog.dart';
import 'npc_effect_dialog.dart';

/// Callback type for EXP changes from explore window
typedef ExpChangeCallback = void Function(double newExp);

/// Singleton to track if explore window is open (main window only)
/// Note: Each window has its own Flutter engine with separate memory,
/// so this singleton only works within the same window process.
class ExploreWindowManager {
  static int? _windowId;
  static Map<String, dynamic>? _savedMapData;
  static ExpChangeCallback? _onExpChanged;
  static VoidCallback? _onMapDataChanged;

  static bool get isWindowOpen => _windowId != null;

  static void setWindowId(int? id) {
    _windowId = id;
  }

  static int? get windowId => _windowId;

  /// Get saved map data for restoring previous progress
  static Map<String, dynamic>? get savedMapData => _savedMapData;

  /// Set saved map data (e.g. restored from persistent storage)
  static void setSavedMapData(Map<String, dynamic>? data) {
    _savedMapData = data;
  }

  /// Clear saved map data
  static void clearSavedMapData() {
    _savedMapData = null;
    _onMapDataChanged?.call();
  }

  /// Clear window ID - call this when window is closed
  static void clearWindow() {
    _windowId = null;
  }

  /// Register a callback to be notified when EXP changes in explore window
  static void setExpChangeCallback(ExpChangeCallback? callback) {
    _onExpChanged = callback;
  }

  /// Register a callback to be notified when map data changes
  static void setMapDataChangedCallback(VoidCallback? callback) {
    _onMapDataChanged = callback;
  }

  /// Setup method handler to receive messages from sub-windows (main window only)
  static void setupMethodHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      try {
        if (call.method == 'expUpdated') {
          // Immediate EXP sync after battle
          final dataJson = call.arguments as String?;
          if (dataJson != null && dataJson.isNotEmpty) {
            final data = jsonDecode(dataJson) as Map<String, dynamic>;
            final currentExp = (data['currentExp'] as num?)?.toDouble();
            if (currentExp != null && _onExpChanged != null) {
              _onExpChanged!(currentExp);
            }
          }
          return 'ok';
        } else if (call.method == 'exploreWindowClosed') {
          // User left without saving - check if there's EXP change to apply
          final dataJson = call.arguments as String?;
          if (dataJson != null && dataJson.isNotEmpty) {
            final data = jsonDecode(dataJson) as Map<String, dynamic>;
            final currentExp = (data['currentExp'] as num?)?.toDouble();
            if (currentExp != null && _onExpChanged != null) {
              _onExpChanged!(currentExp);
            }
          }
          // Clear any previously saved map data
          clearSavedMapData();
          // Close the sub-window from main window to avoid race conditions
          await _closeSubWindow(fromWindowId);
          return 'ok';
        } else if (call.method == 'exploreMapSaved') {
          // Save map data and apply EXP change from sub-window
          final dataJson = call.arguments as String?;
          if (dataJson != null && dataJson.isNotEmpty) {
            final data = jsonDecode(dataJson) as Map<String, dynamic>;
            // Extract and apply current EXP
            final currentExp = (data['currentExp'] as num?)?.toDouble();
            if (currentExp != null && _onExpChanged != null) {
              _onExpChanged!(currentExp);
            }
            // Store map data (without currentExp, it's in the map's own data)
            _savedMapData = data['mapData'] as Map<String, dynamic>?;
            _onMapDataChanged?.call();
          }
          // Close the sub-window from main window to avoid race conditions
          await _closeSubWindow(fromWindowId);
          return 'ok';
        }
      } catch (e) {
        debugPrint('ExploreWindowManager method handler error: $e');
      }
      return null;
    });
  }

  /// Close a sub-window from the main window to avoid vsync race conditions
  static Future<void> _closeSubWindow(int windowId) async {
    clearWindow();
    // Wait a bit to ensure the sub-window's Flutter engine has fully settled
    // after hiding. This prevents vsync/channel errors during shutdown.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      final controller = WindowController.fromWindowId(windowId);
      await controller.close();
    } catch (e) {
      // Window may already be closed
      debugPrint('Sub-window close: $e');
    }
  }
}

/// Opens the Explore window as a separate native window
Future<void> showExploreWindow({
  required BuildContext context,
  required AppThemeColors themeColors,
  required int level,
  required double currentExp,
  required double maxExp,
  String? locale,
}) async {
  // Check what sub-windows actually exist
  final existingWindows = await DesktopMultiWindow.getAllSubWindowIds();

  if (ExploreWindowManager.isWindowOpen) {
    final windowId = ExploreWindowManager.windowId;
    if (windowId != null) {
      // Check if our tracked window actually exists
      if (existingWindows.contains(windowId)) {
        try {
          final controller = WindowController.fromWindowId(windowId);
          await controller.show();
          return;
        } catch (e) {
          debugPrint('Window show failed: $e');
        }
      }
      // Window doesn't exist, clear our tracking
      ExploreWindowManager.clearWindow();
    }
  }

  // Pass theme data, locale, level/exp, and saved map data to the new window
  final argsMap = <String, dynamic>{
    'themeMode': themeColors.brightness == Brightness.dark ? 'dark' : 'light',
    'locale': locale,
    'level': level,
    'currentExp': currentExp.isInfinite ? 0.0 : currentExp,
    'maxExp': maxExp.isInfinite ? 1.0 : maxExp,
  };

  // Include saved map data if available
  if (ExploreWindowManager.savedMapData != null) {
    argsMap['savedMapData'] = ExploreWindowManager.savedMapData;
  }

  final args = jsonEncode(argsMap);

  try {
    final window = await DesktopMultiWindow.createWindow(args);
    ExploreWindowManager.setWindowId(window.windowId);

    // Configure the new window
    await window.setFrame(
      const Rect.fromLTWH(
        100,
        100,
        ExploreConstants.defaultWindowWidth,
        ExploreConstants.defaultWindowHeight,
      ),
    );
    await window.setTitle('Explore');
    await window.center();
    await window.show();
    // Set non-resizable after showing (must be called after window is visible)
    await window.resizable(false);
  } catch (e) {
    debugPrint('Failed to create explore window: $e');
    ExploreWindowManager.clearWindow();
  }
}

/// Entry point for the explore window - called from main.dart
class ExploreWindowApp extends StatefulWidget {
  final Map<String, dynamic> args;
  final int windowId;

  const ExploreWindowApp({
    super.key,
    required this.args,
    required this.windowId,
  });

  @override
  State<ExploreWindowApp> createState() => _ExploreWindowAppState();
}

class _ExploreWindowAppState extends State<ExploreWindowApp> {
  late AppThemeColors _themeColors;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    final themeMode = widget.args['themeMode'] == 'dark'
        ? AppThemeMode.dark
        : AppThemeMode.light;
    _themeColors = AppThemeColors.fromMode(themeMode);

    final localeStr = widget.args['locale'] as String?;
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }

    // Listen for theme/locale change messages from the main window
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'themeChanged') {
        final newThemeMode = call.arguments == 'dark'
            ? AppThemeMode.dark
            : AppThemeMode.light;
        setState(() {
          _themeColors = AppThemeColors.fromMode(newThemeMode);
        });
        return 'ok';
      } else if (call.method == 'localeChanged') {
        final newLocale = call.arguments as String?;
        setState(() {
          _locale = (newLocale != null && newLocale.isNotEmpty)
              ? Locale(newLocale)
              : null;
        });
        return 'ok';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract saved map data if available
    final savedMapData = widget.args['savedMapData'] as Map<String, dynamic>?;

    // Extract level and exp
    final level = widget.args['level'] as int? ?? 1;
    final currentExp = (widget.args['currentExp'] as num?)?.toDouble() ?? 0.0;
    final maxExp = (widget.args['maxExp'] as num?)?.toDouble() ?? 100.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _themeColors.brightness,
        fontFamily: 'NotoSansSC',
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      home: ExploreWindowContent(
        themeColors: _themeColors,
        windowId: widget.windowId,
        savedMapData: savedMapData,
        level: level,
        currentExp: currentExp,
        maxExp: maxExp,
      ),
    );
  }
}

/// The Explore window content - displays a 50x50 grid map
class ExploreWindowContent extends StatefulWidget {
  final AppThemeColors themeColors;
  final int windowId;
  final Map<String, dynamic>? savedMapData;
  final int level;
  final double currentExp;
  final double maxExp;

  const ExploreWindowContent({
    super.key,
    required this.themeColors,
    required this.windowId,
    this.savedMapData,
    required this.level,
    required this.currentExp,
    required this.maxExp,
  });

  @override
  State<ExploreWindowContent> createState() => _ExploreWindowContentState();
}

class _ExploreWindowContentState extends State<ExploreWindowContent>
    with TickerProviderStateMixin {
  late ExploreMap _map;
  late TransformationController _transformationController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;
  bool _isClosing = false;
  bool _isBattleInProgress = false;

  // Mutable state for exp changes during battles
  late double _currentExp;

  // Floating toast animation
  AnimationController? _toastController;
  String _toastMessage = '';
  Color _toastColor = Colors.white;

  // Battle service
  final BattleService _battleService = BattleService();

  // NPC effect service
  final NpcEffectService _npcEffectService = NpcEffectService();

  /// Track current theme colors locally so we react to parent rebuilds
  late AppThemeColors _colors;

  // Debug state
  bool _debugFogRevealed = false;
  DebugBattleMode _debugBattleMode = DebugBattleMode.normal;

  /// Mark cells within the current FOV as visited (Manhattan distance)
  void _updateVisitedCells() {
    final fovRadius = ExploreConstants.defaultFovRadius;
    final px = _map.playerX;
    final py = _map.playerY;
    for (int dy = -fovRadius; dy <= fovRadius; dy++) {
      final remainingX = fovRadius - dy.abs();
      for (int dx = -remainingX; dx <= remainingX; dx++) {
        _map.markVisited(px + dx, py + dy);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _colors = widget.themeColors;
    _currentExp = widget.currentExp;
    _transformationController = TransformationController();
    _generateMap();
  }

  @override
  void didUpdateWidget(ExploreWindowContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeColors != widget.themeColors) {
      _colors = widget.themeColors;
    }
  }

  @override
  void dispose() {
    _toastController?.dispose();
    _transformationController.dispose();
    _focusNode.dispose();
    // Note: Don't call ExploreWindowManager.clearWindow() here
    // because this runs in the sub-window's memory space, not main window's.
    // The notification via invokeMethod in _closeWindow handles this.
    super.dispose();
  }

  void _generateMap() {
    setState(() => _isLoading = true);

    // Restore from saved data if available, otherwise generate new map
    if (widget.savedMapData != null) {
      try {
        _map = ExploreMap.fromJson(widget.savedMapData!);
        // Re-entry: recalculate max AP from current level but
        // keep the saved current AP so exhausted maps stay exhausted
        _map.maxAP = ExploreMap.calculateMaxAP(widget.level);
        // Mark current FOV as visited (in case of old saves without visited data)
        _updateVisitedCells();
        // Center on player position when restoring
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerOnPlayer();
        });
      } catch (e) {
        // If restoration fails, generate new map
        debugPrint('Failed to restore map: $e');
        final generator = ExploreMapGenerator();
        _map = generator.generate(
          playerLevel: widget.level,
          playerExp: widget.currentExp,
        );
        _initializeAP();
        _updateVisitedCells();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerOnPlayer();
        });
      }
    } else {
      // Generate new map
      final generator = ExploreMapGenerator();
      _map = generator.generate(
        playerLevel: widget.level,
        playerExp: widget.currentExp,
      );
      _initializeAP();
      // Mark initial FOV as visited
      _updateVisitedCells();
      // Center the view on player initially (FOV is centered on player)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnPlayer();
      });
    }

    setState(() => _isLoading = false);
  }

  /// Initialize AP for this session based on current player level
  void _initializeAP() {
    final maxAP = ExploreMap.calculateMaxAP(widget.level);
    _map.maxAP = maxAP;
    _map.currentAP = maxAP;
    _map.usedHouses.clear();
  }

  /// Consume AP for an action. Returns true if enough AP, false otherwise.
  bool _consumeAP(int cost) {
    if (_map.currentAP < cost) return false;
    setState(() {
      _map.currentAP -= cost;
    });
    return true;
  }

  /// Check if player has enough AP and show exhausted dialog if not
  bool _checkAP(int cost) {
    if (_map.currentAP >= cost) return true;
    _showApExhaustedDialog();
    return false;
  }

  /// Show AP exhausted dialog prompting player to leave
  void _showApExhaustedDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ExploreConstants.dialogBorderRadius,
          ),
          side: BorderSide(
            color: _colors.border,
            width: ExploreConstants.dialogBorderWidth,
          ),
        ),
        title: Text(
          l10n.exploreApExhaustedTitle,
          style: TextStyle(color: _colors.primaryText),
        ),
        content: Text(
          l10n.exploreApExhaustedContent,
          style: TextStyle(color: _colors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancelButtonText,
              style: TextStyle(color: _colors.inactive),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _closeWindow(saveProgress: false);
            },
            child: Text(
              l10n.exploreExitButton,
              style: TextStyle(color: _colors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a floating toast message in the center of the screen
  void _showFloatingToast(String message, {Color? color}) {
    _toastController?.dispose();

    final totalDuration =
        ExploreConstants.toastFadeInDuration +
        ExploreConstants.toastDisplayDuration +
        ExploreConstants.toastFadeOutDuration;

    _toastController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    setState(() {
      _toastMessage = message;
      _toastColor = color ?? _colors.primaryText;
    });

    _toastController!.forward().then((_) {
      if (mounted) {
        setState(() {
          _toastMessage = '';
        });
      }
    });
  }

  /// Build the floating toast opacity based on animation progress
  double _toastOpacity() {
    final controller = _toastController;
    if (controller == null ||
        !controller.isAnimating && !controller.isCompleted) {
      return 0.0;
    }

    final totalMs =
        (ExploreConstants.toastFadeInDuration +
                ExploreConstants.toastDisplayDuration +
                ExploreConstants.toastFadeOutDuration)
            .inMilliseconds;
    final fadeInEnd =
        ExploreConstants.toastFadeInDuration.inMilliseconds / totalMs;
    final fadeOutStart =
        (ExploreConstants.toastFadeInDuration +
                ExploreConstants.toastDisplayDuration)
            .inMilliseconds /
        totalMs;

    final t = controller.value;
    if (t <= fadeInEnd) {
      // Fade in
      return (t / fadeInEnd).clamp(0.0, 1.0);
    } else if (t <= fadeOutStart) {
      // Fully visible
      return 1.0;
    } else {
      // Fade out
      return ((1.0 - t) / (1.0 - fadeOutStart)).clamp(0.0, 1.0);
    }
  }

  /// Handle stepping on a house cell
  void _handleHouseInteraction(int x, int y) {
    final l10n = AppLocalizations.of(context)!;
    if (_map.isHouseUsed(x, y)) {
      _showFloatingToast(
        l10n.exploreHouseAlreadyUsed,
        color: _colors.secondaryText,
      );
    } else {
      // Restore AP and mark house as used
      _map.markHouseUsed(x, y);
      final restored = ExploreConstants.apHouseRestore;
      setState(() {
        _map.currentAP = (_map.currentAP + restored).clamp(0, _map.maxAP);
      });
      _showFloatingToast(
        l10n.exploreHouseRestoreAp(restored),
        color: ExploreConstants.apColorHigh,
      );
    }
  }

  /// Handle stepping on an NPC cell — generate and apply a random effect
  Future<void> _handleNpcInteraction() async {
    final l10n = AppLocalizations.of(context)!;
    final effect = _npcEffectService.generateEffect(
      currentExp: _currentExp,
      maxExp: widget.maxExp,
    );

    // Get effect description for the dialog
    final description = _getNpcEffectDescription(effect, l10n);

    // Apply immediate EXP changes for instant effects
    final expChange = _npcEffectService.calculateImmediateExpChange(
      effect,
      _currentExp,
      widget.maxExp,
    );
    if (expChange != 0.0) {
      _applyBattleExpChange(expChange);
    }

    // Add duration-based effects to the active effects list
    if (effect.type == NpcEffectType.expMultiplier ||
        effect.type == NpcEffectType.expInsurance ||
        effect.type == NpcEffectType.expFloor) {
      setState(() {
        _map.activeEffects.add(effect);
      });
    }

    // Show encounter dialog
    if (!mounted) return;
    await showNpcEncounterDialog(
      context: context,
      effect: effect,
      effectDescription: description,
      colors: _colors,
      l10n: l10n,
    );
  }

  /// Get localized description string for an NPC effect
  String _getNpcEffectDescription(NpcEffect effect, AppLocalizations l10n) {
    switch (effect.type) {
      case NpcEffectType.expGiftSteal:
        final expChange = _npcEffectService.calculateImmediateExpChange(
          effect,
          _currentExp,
          widget.maxExp,
        );
        final amount = NumberFormatter.format(expChange.abs());
        return effect.isPositive
            ? l10n.npcEffectExpGiftPositive(amount)
            : l10n.npcEffectExpStealNegative(amount);

      case NpcEffectType.expMultiplier:
        return effect.isPositive
            ? l10n.npcEffectExpMultiplierPositive(
                NpcEffectConstants.multiplierDurationBattles,
              )
            : l10n.npcEffectExpMultiplierNegative(
                NpcEffectConstants.multiplierDurationBattles,
              );

      case NpcEffectType.expInsurance:
        return effect.isPositive
            ? l10n.npcEffectExpInsurancePositive
            : l10n.npcEffectExpInsuranceNegative;

      case NpcEffectType.expFloor:
        return effect.isPositive
            ? l10n.npcEffectExpFloorPositive(
                NpcEffectConstants.floorDurationBattles,
              )
            : l10n.npcEffectExpFloorNegative(
                NpcEffectConstants.floorDurationBattles,
              );

      case NpcEffectType.expGamble:
        return effect.isPositive
            ? l10n.npcEffectExpGamblePositive
            : l10n.npcEffectExpGambleNegative;
    }
  }

  void _centerOnPlayer() {
    final cellSize = ExploreConstants.cellSize;
    final playerCenterX = _map.playerX * cellSize + cellSize / 2;
    final playerCenterY = _map.playerY * cellSize + cellSize / 2;

    // Get window size for center calculation
    final size = MediaQuery.of(context).size;
    final viewportCenterX = size.width / 2;
    final viewportCenterY =
        (size.height -
            ExploreConstants.headerHeight -
            ExploreConstants.bottomPanelHeight) /
        2;

    // Keep current scale
    final currentScale = _transformationController.value.storage[0];

    final matrix = Matrix4.identity();
    matrix.storage[0] = currentScale; // scaleX
    matrix.storage[5] = currentScale; // scaleY
    matrix.storage[10] = 1.0; // scaleZ
    matrix.storage[12] = viewportCenterX - playerCenterX * currentScale;
    matrix.storage[13] = viewportCenterY - playerCenterY * currentScale;
    matrix.storage[15] = 1.0;

    _transformationController.value = _clampMatrix(matrix);
  }

  /// Clamp the transformation matrix so the grid always fills the viewport
  /// (no blank space beyond grid boundaries)
  Matrix4 _clampMatrix(Matrix4 matrix) {
    final size = MediaQuery.of(context).size;
    final viewWidth = size.width;
    final viewHeight =
        size.height -
        ExploreConstants.headerHeight -
        ExploreConstants.bottomPanelHeight;

    final gridPixelSize = ExploreConstants.gridSize * ExploreConstants.cellSize;

    // Calculate minimum scale needed to fill the viewport
    final minScaleToFillWidth = viewWidth / gridPixelSize;
    final minScaleToFillHeight = viewHeight / gridPixelSize;
    final minScaleToFill = minScaleToFillWidth > minScaleToFillHeight
        ? minScaleToFillWidth
        : minScaleToFillHeight;

    // Clamp scale to ensure grid always fills viewport
    double scale = matrix.storage[0]; // Uniform scale
    if (scale < minScaleToFill) {
      scale = minScaleToFill;
    }
    // Also respect the max scale from constants
    if (scale > ExploreConstants.maxScale) {
      scale = ExploreConstants.maxScale;
    }

    final scaledGridSize = gridPixelSize * scale;

    double tx = matrix.storage[12];
    double ty = matrix.storage[13];

    // Horizontal clamping - grid must cover entire viewport width
    final minTx = viewWidth - scaledGridSize;
    final maxTx = 0.0;
    tx = tx.clamp(minTx, maxTx);

    // Vertical clamping - grid must cover entire viewport height
    final minTy = viewHeight - scaledGridSize;
    final maxTy = 0.0;
    ty = ty.clamp(minTy, maxTy);

    // Build the clamped matrix with potentially adjusted scale
    final clampedMatrix = Matrix4.identity();
    clampedMatrix.storage[0] = scale; // scaleX
    clampedMatrix.storage[5] = scale; // scaleY
    clampedMatrix.storage[10] = 1.0; // scaleZ
    clampedMatrix.storage[12] = tx;
    clampedMatrix.storage[13] = ty;
    clampedMatrix.storage[15] = 1.0;

    return clampedMatrix;
  }

  void _handleKeyEvent(KeyEvent event) {
    // Handle both KeyDownEvent and KeyRepeatEvent for continuous movement
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    // Ignore input during battle
    if (_isBattleInProgress) return;

    final key = event.logicalKey;

    // WASD movement
    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      _tryMove(0, -1);
    } else if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.arrowDown) {
      _tryMove(0, 1);
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowLeft) {
      _tryMove(-1, 0);
    } else if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      _tryMove(1, 0);
    } else if (key == LogicalKeyboardKey.escape) {
      _confirmClose();
      return;
    }
  }

  /// Try to move player in direction, handling enemy encounters
  void _tryMove(int dx, int dy) {
    final newX = _map.playerX + dx;
    final newY = _map.playerY + dy;
    final targetCell = _map.getCell(newX, newY);

    if (targetCell == null || !targetCell.isWalkable) return;

    // Check for enemy encounters
    if (targetCell.type == ExploreCellType.monster ||
        targetCell.type == ExploreCellType.boss) {
      // AP check is done inside _initiateBattle (fight/flee have different costs)
      _initiateBattle(targetCell, dx, dy);
      return;
    }

    // Check for NPC interaction
    if (targetCell.type == ExploreCellType.npc) {
      if (!_checkAP(ExploreConstants.apCostMove + ExploreConstants.apCostNpc)) {
        return;
      }
      _consumeAP(ExploreConstants.apCostMove + ExploreConstants.apCostNpc);
      if (_map.movePlayer(dx, dy)) {
        _updateVisitedCells();
        setState(() {});
        _panToKeepPlayerVisible();
        _handleNpcInteraction();
      }
      return;
    }

    // Check for house interaction
    if (targetCell.type == ExploreCellType.house) {
      if (!_checkAP(ExploreConstants.apCostMove)) return;
      _consumeAP(ExploreConstants.apCostMove);
      if (_map.movePlayer(dx, dy)) {
        _updateVisitedCells();
        setState(() {});
        _panToKeepPlayerVisible();
        _handleHouseInteraction(newX, newY);
      }
      return;
    }

    // Normal move — check AP
    if (!_checkAP(ExploreConstants.apCostMove)) return;
    _consumeAP(ExploreConstants.apCostMove);
    if (_map.movePlayer(dx, dy)) {
      _updateVisitedCells();
      setState(() {});
      _panToKeepPlayerVisible();
    }
  }

  /// Initiate a battle with an enemy
  Future<void> _initiateBattle(ExploreCell enemyCell, int dx, int dy) async {
    if (_isBattleInProgress) return;
    setState(() => _isBattleInProgress = true);

    final l10n = AppLocalizations.of(context)!;
    final playerFC = _calculateFightingCapacity();

    // Calculate enemy FC using the level when the map was generated
    // This ensures consistent difficulty within a map session
    final enemyFC = _battleService.calculateEnemyFC(
      _map.generatedAtLevel,
      widget.maxExp,
      enemyCell.type,
    );

    // Determine AP cost for this fight
    final fightCost = enemyCell.type == ExploreCellType.boss
        ? ExploreConstants.apCostFightBoss
        : ExploreConstants.apCostFightMonster;

    // Check if player has enough AP to fight (move + fight cost)
    // We need at least move cost + flee cost to even attempt the encounter
    if (!_checkAP(
      ExploreConstants.apCostMove + ExploreConstants.apCostFleeSuccess,
    )) {
      setState(() => _isBattleInProgress = false);
      return;
    }

    // Show encounter dialog
    final shouldFight = await showBattleEncounterDialog(
      context: context,
      enemyType: enemyCell.type,
      playerFC: playerFC,
      enemyFC: enemyFC,
      colors: _colors,
      l10n: l10n,
    );

    if (!mounted) {
      return;
    }

    if (shouldFight == true) {
      // Player chose to fight — consume move + fight AP
      _consumeAP(ExploreConstants.apCostMove + fightCost);
      await _performBattle(enemyCell, playerFC, enemyFC, dx, dy);
    } else if (shouldFight == false) {
      // Player chose to flee
      await _handleFlee(enemyCell, playerFC, enemyFC, dx, dy, fightCost);
    }

    if (!mounted) return;
    setState(() => _isBattleInProgress = false);
  }

  /// Perform the actual battle
  Future<void> _performBattle(
    ExploreCell enemyCell,
    double playerFC,
    double enemyFC,
    int dx,
    int dy,
  ) async {
    await _executeBattleAndApply(enemyCell, playerFC, enemyFC, dx, dy);
  }

  /// Handle flee attempt
  Future<void> _handleFlee(
    ExploreCell enemyCell,
    double playerFC,
    double enemyFC,
    int dx,
    int dy,
    int fightCost,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fleeSuccess = _battleService.attemptFlee();

    if (fleeSuccess) {
      // Flee success costs move + flee AP
      _consumeAP(
        ExploreConstants.apCostMove + ExploreConstants.apCostFleeSuccess,
      );
    } else {
      // Flee failed → forced fight costs move + fight AP
      _consumeAP(ExploreConstants.apCostMove + fightCost);
    }

    // Show flee result
    await showFleeResultDialog(
      context: context,
      success: fleeSuccess,
      colors: _colors,
      l10n: l10n,
    );

    if (!mounted) return;

    if (!fleeSuccess) {
      // Flee failed - forced to fight (no escape)
      await _executeBattleAndApply(enemyCell, playerFC, enemyFC, dx, dy);
    }
    // If flee succeeded, just return to exploration (enemy stays)
  }

  /// Apply EXP change from battle and sync to main window immediately
  void _applyBattleExpChange(double expChange) {
    setState(() {
      _currentExp = (_currentExp + expChange).clamp(0.0, double.infinity);
    });
    // Sync to main window immediately
    _syncExpToMainWindow();
  }

  /// Judge battle outcome, respecting debug battle mode overrides
  BattleOutcome _judgeBattleOutcome(double playerFC, double enemyFC) {
    if (_debugBattleMode == DebugBattleMode.autoWin) {
      return BattleOutcome.victory;
    } else if (_debugBattleMode == DebugBattleMode.autoLose) {
      return BattleOutcome.defeat;
    }
    return _battleService.judgeBattle(playerFC, enemyFC);
  }

  /// Execute a battle: judge outcome, calculate rewards, show result dialog,
  /// and apply map changes. Shared by direct fights and flee-failed fights.
  Future<void> _executeBattleAndApply(
    ExploreCell enemyCell,
    double playerFC,
    double enemyFC,
    int dx,
    int dy,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = _judgeBattleOutcome(playerFC, enemyFC);

    var expChange = _battleService.calculateExpChange(
      outcome,
      enemyCell.type,
      _currentExp,
      widget.maxExp,
    );

    // Apply active NPC effects to the EXP change
    expChange = _npcEffectService.applyBattleEffects(
      baseExpChange: expChange,
      isVictory: outcome == BattleOutcome.victory,
      currentExp: _currentExp,
      activeEffects: _map.activeEffects,
    );

    // Consume battle charges from duration-based effects and remove expired
    setState(() {
      _npcEffectService.consumeBattleCharges(_map.activeEffects);
    });

    final result = BattleResult(
      enemyType: enemyCell.type,
      playerFC: playerFC,
      enemyFC: enemyFC,
      outcome: outcome,
      expChange: expChange,
    );

    // Apply EXP change and sync to main window BEFORE showing dialog
    _applyBattleExpChange(result.expChange);

    // Show result dialog
    await showBattleResultDialog(
      context: context,
      result: result,
      colors: _colors,
      l10n: l10n,
    );

    // Apply map changes (cell update, player move) after dialog
    if (!mounted) return;
    _applyBattleMapChanges(result, enemyCell, dx, dy);
  }

  /// Apply map changes after battle (cell update, player movement)
  void _applyBattleMapChanges(
    BattleResult result,
    ExploreCell enemyCell,
    int dx,
    int dy,
  ) {
    if (result.isVictory) {
      setState(() {
        _map.grid[enemyCell.y][enemyCell.x] = enemyCell.copyWith(
          type: ExploreCellType.blank,
        );
        _map.movePlayer(dx, dy);
        _updateVisitedCells();
        _panToKeepPlayerVisible();
      });
    }
    // If defeat, player stays in place (enemy remains)
  }

  /// Send current EXP to main window immediately
  Future<void> _syncExpToMainWindow() async {
    try {
      final expData = jsonEncode({'currentExp': _currentExp});
      await DesktopMultiWindow.invokeMethod(0, 'expUpdated', expData);
    } catch (e) {
      debugPrint('Failed to sync EXP to main window: $e');
    }
  }

  void _panToKeepPlayerVisible() {
    final matrix = _transformationController.value;
    final cellSize = ExploreConstants.cellSize;
    final playerWorldX = _map.playerX * cellSize + cellSize / 2;
    final playerWorldY = _map.playerY * cellSize + cellSize / 2;

    // Apply current transform to get viewport position
    final scale = matrix.storage[0];
    final translatedX = playerWorldX * scale + matrix.storage[12];
    final translatedY = playerWorldY * scale + matrix.storage[13];

    // Get current window size
    final size = MediaQuery.of(context).size;
    const margin = 100.0;
    final viewWidth = size.width;
    final viewHeight = size.height - ExploreConstants.headerHeight;

    double dx = 0;
    double dy = 0;

    if (translatedX < margin) {
      dx = margin - translatedX;
    } else if (translatedX > viewWidth - margin) {
      dx = viewWidth - margin - translatedX;
    }

    if (translatedY < margin) {
      dy = margin - translatedY;
    } else if (translatedY > viewHeight - margin) {
      dy = viewHeight - margin - translatedY;
    }

    if (dx != 0 || dy != 0) {
      final newMatrix = matrix.clone();
      newMatrix.storage[12] += dx;
      newMatrix.storage[13] += dy;
      // Clamp to keep grid filling the viewport
      _transformationController.value = _clampMatrix(newMatrix);
    }
  }

  void _confirmClose() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ExploreConstants.dialogBorderRadius,
          ),
          side: BorderSide(
            color: _colors.border,
            width: ExploreConstants.dialogBorderWidth,
          ),
        ),
        title: Text(
          l10n.exploreExitConfirmTitle,
          style: TextStyle(color: _colors.primaryText),
        ),
        content: Text(
          l10n.exploreExitConfirmContent,
          style: TextStyle(color: _colors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancelButtonText,
              style: TextStyle(color: _colors.inactive),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _closeWindow(saveProgress: true);
            },
            child: Text(
              l10n.exploreSaveAndLeaveButton,
              style: TextStyle(color: _colors.accent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _closeWindow(saveProgress: false);
            },
            child: Text(
              l10n.exploreExitButton,
              style: TextStyle(color: _colors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _closeWindow({bool saveProgress = false}) async {
    // Prevent multiple close attempts and stop UI updates
    if (_isClosing) return;
    setState(() => _isClosing = true);

    final windowId = widget.windowId;
    final controller = WindowController.fromWindowId(windowId);

    // Step 1: Hide window to stop rendering new frames
    try {
      await controller.hide();
    } catch (e) {
      debugPrint('Window hide error: $e');
    }

    // Step 2: Wait for current frame to complete
    // This ensures no vsync callbacks are pending
    await SchedulerBinding.instance.endOfFrame;

    // Step 3: Additional delay to ensure Flutter engine settles
    // The engine may have internal async operations still in flight
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Step 4: Notify main window and request close
    try {
      if (saveProgress) {
        // Send both map data and current EXP
        final saveData = jsonEncode({
          'mapData': _map.toJson(),
          'currentExp': _currentExp,
        });
        await DesktopMultiWindow.invokeMethod(0, 'exploreMapSaved', saveData);
      } else {
        // Even when not saving map, send current EXP so battles count
        final closeData = jsonEncode({'currentExp': _currentExp});
        await DesktopMultiWindow.invokeMethod(
          0,
          'exploreWindowClosed',
          closeData,
        );
      }
      // Main window will close this window
    } catch (e) {
      // If notification fails, close from here as fallback
      debugPrint('Failed to notify main window: $e');
      await _forceClose(controller);
    }
  }

  /// Force close as a fallback when main window communication fails
  Future<void> _forceClose(WindowController controller) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      await controller.close();
    } catch (e) {
      debugPrint('Force close error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _colors.dialogBackground,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(l10n),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: _colors.accent,
                          ),
                        )
                      : _buildMapView(),
                ),
                _buildBottomPanel(l10n),
              ],
            ),
            // Floating toast overlay
            if (_toastMessage.isNotEmpty && _toastController != null)
              AnimatedBuilder(
                animation: _toastController!,
                builder: (context, child) {
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: _toastOpacity(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ExploreConstants.toastPaddingH,
                              vertical: ExploreConstants.toastPaddingV,
                            ),
                            decoration: BoxDecoration(
                              color: _colors.dialogBackground,
                              borderRadius: BorderRadius.circular(
                                ExploreConstants.toastBorderRadius,
                              ),
                              border: Border.all(color: _colors.border),
                            ),
                            child: Text(
                              _toastMessage,
                              style: TextStyle(
                                color: _toastColor,
                                fontSize: ExploreConstants.toastFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      height: ExploreConstants.headerHeight,
      decoration: BoxDecoration(
        color: _colors.dialogBackground,
        border: Border(bottom: BorderSide(color: _colors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExploreConstants.headerPaddingH,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Hide legend when width is too small (less than 500px)
            final showLegend = constraints.maxWidth >= 500;

            return Row(
              children: [
                Icon(Icons.explore, color: _colors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.exploreTitle,
                  style: TextStyle(
                    color: _colors.primaryText,
                    fontSize: ExploreConstants.headerFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showLegend) ...[
                  const SizedBox(width: 16),
                  // Legend
                  _buildLegend(l10n),
                ],
                const Spacer(),
                // Position display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colors.overlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '(${_map.playerX}, ${_map.playerY})',
                    style: TextStyle(
                      color: _colors.secondaryText,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Locate player button
                IconButton(
                  onPressed: _centerOnPlayer,
                  icon: Icon(
                    Icons.my_location,
                    color: _colors.accent,
                    size: 15,
                  ),
                  tooltip: l10n.exploreLocatePlayer,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (kDebugMode) ...[
                  const SizedBox(width: 8),
                  // Debug tools button
                  IconButton(
                    onPressed: _showDebugDialog,
                    icon: Icon(
                      Icons.bug_report,
                      color: _colors.accent,
                      size: 18,
                    ),
                    tooltip: l10n.exploreDebugTitle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  onPressed: _confirmClose,
                  icon: Icon(Icons.close, color: _colors.secondaryText),
                  tooltip: l10n.closeButtonText,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Show the debug tools dialog
  void _showDebugDialog() {
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => ExploreDebugDialog(
        themeColors: _colors,
        fogRevealed: _debugFogRevealed,
        currentAP: _map.currentAP,
        maxAP: _map.maxAP,
        playerX: _map.playerX,
        playerY: _map.playerY,
        gridSize: ExploreConstants.gridSize,
        battleMode: _debugBattleMode,
        onFogToggle: (revealed) {
          setState(() => _debugFogRevealed = revealed);
        },
        onSetAP: (ap) {
          setState(() {
            _map.currentAP = ap.clamp(0, _map.maxAP);
          });
        },
        onTeleport: (x, y) {
          if (_map.canMoveTo(x, y)) {
            setState(() {
              _map.playerX = x;
              _map.playerY = y;
              _updateVisitedCells();
            });
            _centerOnPlayer();
          }
        },
        onBattleModeChanged: (mode) {
          setState(() => _debugBattleMode = mode);
        },
        onResetHouses: () {
          setState(() {
            _map.usedHouses.clear();
          });
          final l10n = AppLocalizations.of(context)!;
          _showFloatingToast(
            l10n.exploreDebugHousesReset,
            color: _colors.accent,
          );
        },
        onRegenerateMap: () {
          setState(() {
            final generator = ExploreMapGenerator();
            _map = generator.generate(
              playerLevel: widget.level,
              playerExp: widget.currentExp,
            );
            _initializeAP();
            _updateVisitedCells();
            _debugFogRevealed = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _centerOnPlayer();
          });
          final l10n = AppLocalizations.of(context)!;
          _showFloatingToast(
            l10n.exploreDebugMapRegenerated,
            color: _colors.accent,
          );
        },
      ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem(
          ExploreConstants.playerColor,
          l10n.exploreLegendPlayer,
        ),
        const SizedBox(width: 12),
        _buildLegendItem(
          ExploreConstants.mountainColor,
          l10n.exploreLegendMountain,
        ),
        const SizedBox(width: 12),
        _buildLegendItem(ExploreConstants.riverColor, l10n.exploreLegendRiver),
        const SizedBox(width: 12),
        _buildLegendItem(ExploreConstants.houseColor, l10n.exploreLegendHouse),
        const SizedBox(width: 12),
        _buildLegendItem(
          ExploreConstants.monsterColor,
          l10n.exploreLegendMonster,
        ),
        const SizedBox(width: 12),
        _buildLegendItem(ExploreConstants.bossColor, l10n.exploreLegendBoss),
        const SizedBox(width: 12),
        _buildLegendItem(ExploreConstants.npcColor, l10n.exploreLegendNpc),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: _colors.border, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: _colors.secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  /// Calculate fighting capacity based on level and EXP progress
  double _calculateFightingCapacity() {
    final level = widget.level;
    final maxExp = widget.maxExp;

    // Base power: exponential growth with level
    final basePower =
        ExploreConstants.initialBasePower *
        pow(ExploreConstants.levelGrowthFactor, level - 1);

    // EXP contribution: partial progress toward next level (use local _currentExp)
    final expProgress = maxExp <= 0
        ? 1.0
        : (_currentExp / maxExp).clamp(0.0, 1.0);
    final expBonus =
        basePower * ExploreConstants.expProgressMultiplier * expProgress;

    // Milestone bonus for cultivation realm breakthroughs (every 10 levels)
    final realm = (level - 1) ~/ 10;
    final milestoneBonus = realm > 0
        ? ExploreConstants.realmBaseBonus *
              pow(ExploreConstants.realmGrowthFactor, realm - 1)
        : 0.0;

    return basePower + expBonus + milestoneBonus;
  }

  Widget _buildBottomPanel(AppLocalizations l10n) {
    final fightingCapacity = _calculateFightingCapacity();
    final apRatio = _map.maxAP > 0 ? _map.currentAP / _map.maxAP : 0.0;
    final apColor = apRatio > 0.5
        ? ExploreConstants.apColorHigh
        : apRatio > 0.25
        ? ExploreConstants.apColorMedium
        : ExploreConstants.apColorLow;

    return Container(
      height: ExploreConstants.bottomPanelHeight,
      decoration: BoxDecoration(
        color: _colors.dialogBackground,
        border: Border(top: BorderSide(color: _colors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExploreConstants.bottomPanelPaddingH,
        ),
        child: Row(
          children: [
            // Level display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _colors.overlay,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv. ${widget.level}',
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: ExploreConstants.bottomPanelFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Fighting capacity display
            Icon(Icons.local_fire_department, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Text(
              NumberFormatter.format(fightingCapacity),
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: ExploreConstants.bottomPanelFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            // Action Points display
            Icon(Icons.bolt, color: apColor, size: 18),
            const SizedBox(width: 4),
            Text(
              '${l10n.exploreApLabel}: ',
              style: TextStyle(
                color: _colors.secondaryText,
                fontSize: ExploreConstants.bottomPanelFontSize,
              ),
            ),
            Text(
              '${_map.currentAP} / ${_map.maxAP}',
              style: TextStyle(
                color: apColor,
                fontSize: ExploreConstants.bottomPanelFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Active Effects button
            _buildEffectsButton(l10n),
          ],
        ),
      ),
    );
  }

  /// Build the active effects button for the bottom panel
  Widget _buildEffectsButton(AppLocalizations l10n) {
    final effectCount = _map.activeEffects.length;
    final hasEffects = effectCount > 0;

    return Tooltip(
      message: l10n.npcEffectsButtonTooltip,
      child: InkWell(
        onTap: () {
          showActiveEffectsDialog(
            context: context,
            effects: _map.activeEffects,
            colors: _colors,
            l10n: l10n,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasEffects
                ? _colors.accent.withValues(alpha: 0.15)
                : _colors.overlay,
            borderRadius: BorderRadius.circular(8),
            border: hasEffects
                ? Border.all(color: _colors.accent.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: hasEffects ? _colors.accent : _colors.secondaryText,
                size: 16,
              ),
              if (hasEffects) ...[
                const SizedBox(width: 4),
                Text(
                  '$effectCount',
                  style: TextStyle(
                    color: _colors.accent,
                    fontSize: ExploreConstants.bottomPanelFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final gridPixelSize = ExploreConstants.gridSize * ExploreConstants.cellSize;

    // Calculate minimum scale to fill viewport (account for header and bottom panel)
    final size = MediaQuery.of(context).size;
    final viewWidth = size.width;
    final viewHeight =
        size.height -
        ExploreConstants.headerHeight -
        ExploreConstants.bottomPanelHeight;
    final minScaleToFillWidth = viewWidth / gridPixelSize;
    final minScaleToFillHeight = viewHeight / gridPixelSize;
    final minScale = minScaleToFillWidth > minScaleToFillHeight
        ? minScaleToFillWidth
        : minScaleToFillHeight;

    return ClipRect(
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: minScale,
        maxScale: ExploreConstants.maxScale,
        constrained: false,
        boundaryMargin: EdgeInsets.zero,
        onInteractionEnd: (_) {
          // Clamp the matrix after user finishes panning/zooming
          _transformationController.value = _clampMatrix(
            _transformationController.value,
          );
        },
        child: SizedBox(
          width: gridPixelSize,
          height: gridPixelSize,
          child: CustomPaint(
            painter: ExploreMapPainter(
              map: _map,
              themeColors: _colors,
              visitedCells: _map.visitedCells,
              fogRevealed: _debugFogRevealed,
            ),
            size: Size(gridPixelSize, gridPixelSize),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for rendering the explore map with field of view
class ExploreMapPainter extends CustomPainter {
  final ExploreMap map;
  final AppThemeColors themeColors;
  final Set<int> visitedCells;
  final bool fogRevealed;

  ExploreMapPainter({
    required this.map,
    required this.themeColors,
    required this.visitedCells,
    this.fogRevealed = false,
  });

  /// Check if a cell is within the current FOV (Manhattan distance)
  bool _isInFov(int x, int y, int playerX, int playerY, int fovRadius) {
    return (x - playerX).abs() + (y - playerY).abs() <= fovRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = ExploreConstants.cellSize;
    final isDark = themeColors.brightness == Brightness.dark;
    final fovRadius = ExploreConstants.defaultFovRadius;
    final playerX = map.playerX;
    final playerY = map.playerY;
    final mapWidth = map.width;

    // Draw fog background over entire grid (skip if fog is revealed)
    if (!fogRevealed) {
      final fogColor = isDark
          ? ExploreConstants.fogColorDark
          : ExploreConstants.fogColorLight;
      final fogPaint = Paint()..color = fogColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);
    }

    // When fog is revealed, draw all cells with blank background first
    if (fogRevealed) {
      final blankAll = isDark
          ? ExploreConstants.blankColorDark
          : ExploreConstants.blankColorLight;
      final blankAllPaint = Paint()..color = blankAll;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        blankAllPaint,
      );
    }

    // Draw grid lines across entire grid so cell shapes are visible in fog
    final fogGridLineColor = isDark
        ? const Color(0xFF50506A) // Lighter than fog for contrast
        : const Color(0xFF858598); // Darker than fog for contrast
    final fogGridLinePaint = Paint()
      ..color = fogGridLineColor
      ..strokeWidth = ExploreConstants.gridLineWidth;

    for (int i = 0; i <= ExploreConstants.gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(
        Offset(0, pos),
        Offset(size.width, pos),
        fogGridLinePaint,
      );
      canvas.drawLine(
        Offset(pos, 0),
        Offset(pos, size.height),
        fogGridLinePaint,
      );
    }

    // When fog is revealed, draw all cell contents
    if (fogRevealed) {
      for (int y = 0; y < map.height; y++) {
        for (int x = 0; x < map.width; x++) {
          final cell = map.grid[y][x];
          if (cell.type == ExploreCellType.blank) continue;
          final cellRect = Rect.fromLTWH(
            x * cellSize + 1,
            y * cellSize + 1,
            cellSize - 2,
            cellSize - 2,
          );
          final paint = Paint()..color = _getCellColor(cell.type, isDark);
          canvas.drawRect(cellRect, paint);
        }
      }
      // Draw player on top and return early
      _drawPlayer(canvas, playerX, playerY, cellSize);
      return;
    }

    // Prepare paints
    final blankColor = isDark
        ? ExploreConstants.blankColorDark
        : ExploreConstants.blankColorLight;
    final blankPaint = Paint()..color = blankColor;
    final gridLineColor = isDark
        ? ExploreConstants.gridLineColorDark
        : ExploreConstants.gridLineColorLight;
    final gridLinePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = ExploreConstants.gridLineWidth;

    // Bounding box for all visible cells (FOV + visited)
    // Start with FOV bounds, then expand with visited cells
    final fovMinX = (playerX - fovRadius).clamp(0, map.width - 1);
    final fovMaxX = (playerX + fovRadius).clamp(0, map.width - 1);
    final fovMinY = (playerY - fovRadius).clamp(0, map.height - 1);
    final fovMaxY = (playerY + fovRadius).clamp(0, map.height - 1);

    // Draw visited cells that are outside current FOV
    for (final encoded in visitedCells) {
      final vy = encoded ~/ mapWidth;
      final vx = encoded % mapWidth;
      if (_isInFov(vx, vy, playerX, playerY, fovRadius)) continue;

      // Draw blank background for visited cell
      final cellRect = Rect.fromLTWH(
        vx * cellSize,
        vy * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(cellRect, blankPaint);

      // Draw grid lines around this cell
      canvas.drawLine(
        Offset(vx * cellSize, vy * cellSize),
        Offset((vx + 1) * cellSize, vy * cellSize),
        gridLinePaint,
      );
      canvas.drawLine(
        Offset(vx * cellSize, (vy + 1) * cellSize),
        Offset((vx + 1) * cellSize, (vy + 1) * cellSize),
        gridLinePaint,
      );
      canvas.drawLine(
        Offset(vx * cellSize, vy * cellSize),
        Offset(vx * cellSize, (vy + 1) * cellSize),
        gridLinePaint,
      );
      canvas.drawLine(
        Offset((vx + 1) * cellSize, vy * cellSize),
        Offset((vx + 1) * cellSize, (vy + 1) * cellSize),
        gridLinePaint,
      );

      // Draw cell content
      final cell = map.grid[vy][vx];
      if (cell.type != ExploreCellType.blank) {
        final contentRect = Rect.fromLTWH(
          vx * cellSize + 1,
          vy * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        final paint = Paint()..color = _getCellColor(cell.type, isDark);
        canvas.drawRect(contentRect, paint);
      }
    }

    // Draw current FOV cells (Manhattan distance diamond)
    for (int y = fovMinY; y <= fovMaxY; y++) {
      for (int x = fovMinX; x <= fovMaxX; x++) {
        if (!_isInFov(x, y, playerX, playerY, fovRadius)) continue;

        // Draw blank background
        final cellRect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(cellRect, blankPaint);
      }
    }

    // Draw grid lines for FOV area
    for (int y = fovMinY; y <= fovMaxY; y++) {
      for (int x = fovMinX; x <= fovMaxX; x++) {
        if (!_isInFov(x, y, playerX, playerY, fovRadius)) continue;

        final left = x * cellSize;
        final top = y * cellSize;
        final right = (x + 1) * cellSize;
        final bottom = (y + 1) * cellSize;

        // Draw cell borders (only on edges where neighbor is not in FOV)
        canvas.drawLine(Offset(left, top), Offset(right, top), gridLinePaint);
        canvas.drawLine(
          Offset(left, bottom),
          Offset(right, bottom),
          gridLinePaint,
        );
        canvas.drawLine(Offset(left, top), Offset(left, bottom), gridLinePaint);
        canvas.drawLine(
          Offset(right, top),
          Offset(right, bottom),
          gridLinePaint,
        );
      }
    }

    // Draw cell contents in FOV
    for (int y = fovMinY; y <= fovMaxY; y++) {
      for (int x = fovMinX; x <= fovMaxX; x++) {
        if (!_isInFov(x, y, playerX, playerY, fovRadius)) continue;

        final cell = map.grid[y][x];
        if (cell.type == ExploreCellType.blank) continue;

        final cellRect = Rect.fromLTWH(
          x * cellSize + 1,
          y * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );

        final paint = Paint()..color = _getCellColor(cell.type, isDark);
        canvas.drawRect(cellRect, paint);
      }
    }

    // Draw player (always visible)
    _drawPlayer(canvas, playerX, playerY, cellSize);
  }

  Color _getCellColor(ExploreCellType type, bool isDark) {
    switch (type) {
      case ExploreCellType.blank:
        return isDark
            ? ExploreConstants.blankColorDark
            : ExploreConstants.blankColorLight;
      case ExploreCellType.mountain:
        return ExploreConstants.mountainColor;
      case ExploreCellType.river:
        return ExploreConstants.riverColor;
      case ExploreCellType.house:
        return ExploreConstants.houseColor;
      case ExploreCellType.monster:
        return ExploreConstants.monsterColor;
      case ExploreCellType.boss:
        return ExploreConstants.bossColor;
      case ExploreCellType.npc:
        return ExploreConstants.npcColor;
    }
  }

  void _drawPlayer(Canvas canvas, int x, int y, double cellSize) {
    final playerRect = Rect.fromLTWH(
      x * cellSize + 1,
      y * cellSize + 1,
      cellSize - 2,
      cellSize - 2,
    );

    final borderPaint = Paint()
      ..color = ExploreConstants.playerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final playerPaint = Paint()..color = ExploreConstants.playerColor;

    canvas.drawRect(playerRect.inflate(-1), playerPaint);
    canvas.drawRect(playerRect, borderPaint);

    final center = playerRect.center;
    final iconPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, cellSize / 4, iconPaint);
  }

  @override
  bool shouldRepaint(ExploreMapPainter oldDelegate) {
    return oldDelegate.map.playerX != map.playerX ||
        oldDelegate.map.playerY != map.playerY ||
        oldDelegate.visitedCells.length != visitedCells.length ||
        oldDelegate.themeColors != themeColors ||
        oldDelegate.fogRevealed != fogRevealed;
  }
}
