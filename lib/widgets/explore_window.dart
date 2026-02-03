import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/explore_map.dart';

/// Singleton to track if explore window is open (main window only)
/// Note: Each window has its own Flutter engine with separate memory,
/// so this singleton only works within the same window process.
class ExploreWindowManager {
  static int? _windowId;

  static bool get isWindowOpen => _windowId != null;

  static void setWindowId(int? id) {
    _windowId = id;
  }

  static int? get windowId => _windowId;

  /// Clear window ID - call this when window is closed
  static void clearWindow() {
    _windowId = null;
  }

  /// Setup method handler to receive messages from sub-windows (main window only)
  static void setupMethodHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'exploreWindowClosed') {
        clearWindow();
        return 'ok';
      }
      return null;
    });
  }
}

/// Opens the Explore window as a separate native window
Future<void> showExploreWindow({
  required BuildContext context,
  required AppThemeColors themeColors,
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

  // Pass theme data to the new window
  final args = jsonEncode({
    'themeMode': themeColors.brightness == Brightness.dark ? 'dark' : 'light',
  });

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
class ExploreWindowApp extends StatelessWidget {
  final Map<String, dynamic> args;
  final int windowId;

  const ExploreWindowApp({
    super.key,
    required this.args,
    required this.windowId,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = args['themeMode'] == 'dark'
        ? AppThemeMode.dark
        : AppThemeMode.light;
    final themeColors = AppThemeColors.fromMode(themeMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: themeColors.brightness,
        fontFamily: 'NotoSansSC',
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ExploreWindowContent(themeColors: themeColors, windowId: windowId),
    );
  }
}

/// The Explore window content - displays a 50x50 grid map
class ExploreWindowContent extends StatefulWidget {
  final AppThemeColors themeColors;
  final int windowId;

  const ExploreWindowContent({
    super.key,
    required this.themeColors,
    required this.windowId,
  });

  @override
  State<ExploreWindowContent> createState() => _ExploreWindowContentState();
}

class _ExploreWindowContentState extends State<ExploreWindowContent> {
  late ExploreMap _map;
  late TransformationController _transformationController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = true;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _generateMap();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    // Note: Don't call ExploreWindowManager.clearWindow() here
    // because this runs in the sub-window's memory space, not main window's.
    // The notification via invokeMethod in _closeWindow handles this.
    super.dispose();
  }

  void _generateMap() {
    setState(() => _isLoading = true);

    // Generate map
    final generator = ExploreMapGenerator();
    _map = generator.generate();

    // Center the view on grid center initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnGrid();
    });

    setState(() => _isLoading = false);
  }

  void _centerOnGrid() {
    final cellSize = ExploreConstants.cellSize;
    final gridPixelSize = ExploreConstants.gridSize * cellSize;
    final gridCenterX = gridPixelSize / 2;
    final gridCenterY = gridPixelSize / 2;

    // Get window size for center calculation
    final size = MediaQuery.of(context).size;
    final viewportCenterX = size.width / 2;
    final viewportCenterY = (size.height - ExploreConstants.headerHeight) / 2;

    final matrix = Matrix4.identity()
      ..setTranslationRaw(
        viewportCenterX - gridCenterX,
        viewportCenterY - gridCenterY,
        0,
      );

    _transformationController.value = _clampMatrix(matrix);
  }

  void _centerOnPlayer() {
    final cellSize = ExploreConstants.cellSize;
    final playerCenterX = _map.playerX * cellSize + cellSize / 2;
    final playerCenterY = _map.playerY * cellSize + cellSize / 2;

    // Get window size for center calculation
    final size = MediaQuery.of(context).size;
    final viewportCenterX = size.width / 2;
    final viewportCenterY = (size.height - ExploreConstants.headerHeight) / 2;

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
    final viewHeight = size.height - ExploreConstants.headerHeight;

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

    final key = event.logicalKey;
    bool moved = false;

    // WASD movement
    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      moved = _map.movePlayer(0, -1);
    } else if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.arrowDown) {
      moved = _map.movePlayer(0, 1);
    } else if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowLeft) {
      moved = _map.movePlayer(-1, 0);
    } else if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      moved = _map.movePlayer(1, 0);
    } else if (key == LogicalKeyboardKey.escape) {
      _confirmClose();
      return;
    }

    if (moved) {
      setState(() {});
      _panToKeepPlayerVisible();
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
              _closeWindow();
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

  Future<void> _closeWindow() async {
    final windowId = widget.windowId;

    // Notify main window (window 0) that this window is closing
    // This is critical because each window has its own memory space
    try {
      await DesktopMultiWindow.invokeMethod(
        0, // Main window ID is always 0
        'exploreWindowClosed',
        windowId,
      );
    } catch (e) {
      // Notification failure is not critical, window will still close
      debugPrint('Failed to notify main window: $e');
    }

    // Close this window
    try {
      final controller = WindowController.fromWindowId(windowId);
      await controller.close();
    } catch (e) {
      debugPrint('Window close error (can be ignored): $e');
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
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _colors.accent),
                    )
                  : _buildMapView(),
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

  Widget _buildMapView() {
    final gridPixelSize = ExploreConstants.gridSize * ExploreConstants.cellSize;

    // Calculate minimum scale to fill viewport
    final size = MediaQuery.of(context).size;
    final viewWidth = size.width;
    final viewHeight = size.height - ExploreConstants.headerHeight;
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
            painter: ExploreMapPainter(map: _map, themeColors: _colors),
            size: Size(gridPixelSize, gridPixelSize),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for rendering the explore map
class ExploreMapPainter extends CustomPainter {
  final ExploreMap map;
  final AppThemeColors themeColors;

  ExploreMapPainter({required this.map, required this.themeColors});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = ExploreConstants.cellSize;
    final isDark = themeColors.brightness == Brightness.dark;

    // Draw grid background (theme-aware)
    final blankColor = isDark
        ? ExploreConstants.blankColorDark
        : ExploreConstants.blankColorLight;
    final backgroundPaint = Paint()..color = blankColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw grid lines (theme-aware)
    final gridLineColor = isDark
        ? ExploreConstants.gridLineColorDark
        : ExploreConstants.gridLineColorLight;
    final gridLinePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = ExploreConstants.gridLineWidth;

    for (int i = 0; i <= ExploreConstants.gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridLinePaint);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridLinePaint);
    }

    // Draw cells
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

    // Draw player
    _drawPlayer(canvas, map.playerX, map.playerY, cellSize);
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
        oldDelegate.map.playerY != map.playerY;
  }
}
