import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import 'base_game_window.dart';

/// Direction the snake is moving
enum SnakeDirection { up, down, left, right }

/// State of the snake game
enum SnakeGameState { waiting, playing, gameOver }

/// Classic Snake game widget
class SnakeGameWindow extends StatefulWidget {
  final AppThemeColors themeColors;
  final void Function(int expGained) onExpGained;

  const SnakeGameWindow({
    super.key,
    required this.themeColors,
    required this.onExpGained,
  });

  @override
  State<SnakeGameWindow> createState() => _SnakeGameWindowState();
}

class _SnakeGameWindowState extends State<SnakeGameWindow>
    with GameKeyboardMixin, GameRestartCooldownMixin {
  // Game state
  SnakeGameState _gameState = SnakeGameState.waiting;
  List<Point<int>> _snake = [];
  Point<int> _food = const Point(0, 0);
  SnakeDirection _direction = SnakeDirection.right;
  SnakeDirection _nextDirection = SnakeDirection.right;
  int _score = 0;
  int _expGained = 0;

  // Game timer
  Timer? _gameTimer;
  final Random _random = Random();

  // Gesture tracking for swipe
  Offset? _swipeStart;

  // Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame() {
    _snake = [
      Point(SnakeGameConstants.gridSize ~/ 2, SnakeGameConstants.gridSize ~/ 2),
      Point(
        SnakeGameConstants.gridSize ~/ 2 - 1,
        SnakeGameConstants.gridSize ~/ 2,
      ),
      Point(
        SnakeGameConstants.gridSize ~/ 2 - 2,
        SnakeGameConstants.gridSize ~/ 2,
      ),
    ];
    _direction = SnakeDirection.right;
    _nextDirection = SnakeDirection.right;
    _score = 0;
    _expGained = 0;
    _spawnFood();
  }

  void _spawnFood() {
    Point<int> newFood;
    do {
      newFood = Point(
        _random.nextInt(SnakeGameConstants.gridSize),
        _random.nextInt(SnakeGameConstants.gridSize),
      );
    } while (_snake.contains(newFood));
    _food = newFood;
  }

  void _startGame() {
    if (_gameState == SnakeGameState.playing) return;

    setState(() {
      if (_gameState == SnakeGameState.gameOver) {
        _initGame();
      }
      _gameState = SnakeGameState.playing;
    });

    _gameTimer = Timer.periodic(
      const Duration(milliseconds: SnakeGameConstants.gameTickMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (_gameState != SnakeGameState.playing) return;

    setState(() {
      _direction = _nextDirection;

      // Calculate new head position
      final head = _snake.first;
      Point<int> newHead;

      switch (_direction) {
        case SnakeDirection.up:
          newHead = Point(head.x, head.y - 1);
        case SnakeDirection.down:
          newHead = Point(head.x, head.y + 1);
        case SnakeDirection.left:
          newHead = Point(head.x - 1, head.y);
        case SnakeDirection.right:
          newHead = Point(head.x + 1, head.y);
      }

      // Check wall collision
      if (newHead.x < 0 ||
          newHead.x >= SnakeGameConstants.gridSize ||
          newHead.y < 0 ||
          newHead.y >= SnakeGameConstants.gridSize) {
        _endGame();
        return;
      }

      // Check self collision
      if (_snake.contains(newHead)) {
        _endGame();
        return;
      }

      // Move snake
      _snake.insert(0, newHead);

      // Check food collision
      if (newHead == _food) {
        _score += SnakeGameConstants.scorePerFood;
        _expGained += SnakeGameConstants.expPerFood;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _gameState = SnakeGameState.gameOver;

    // Prevent accidental restart by adding cooldown
    startRestartCooldown();

    // Notify parent about exp gained
    if (_expGained > 0) {
      widget.onExpGained(_expGained);
    }
  }

  void _changeDirection(SnakeDirection newDirection) {
    if (_gameState != SnakeGameState.playing) return;

    // Prevent 180-degree turns
    final isOpposite =
        (_direction == SnakeDirection.up &&
            newDirection == SnakeDirection.down) ||
        (_direction == SnakeDirection.down &&
            newDirection == SnakeDirection.up) ||
        (_direction == SnakeDirection.left &&
            newDirection == SnakeDirection.right) ||
        (_direction == SnakeDirection.right &&
            newDirection == SnakeDirection.left);

    if (!isOpposite) {
      _nextDirection = newDirection;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    // Handle common keys (ESC to close)
    if (handleCommonKeyEvent(event)) return;
    if (event is! KeyDownEvent) return;

    if (_gameState == SnakeGameState.waiting) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _startGame();
        return;
      }
    }

    if (_gameState == SnakeGameState.gameOver) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        tryRestart(_startGame);
      }
      return;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _changeDirection(SnakeDirection.up);
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _changeDirection(SnakeDirection.down);
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _changeDirection(SnakeDirection.left);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _changeDirection(SnakeDirection.right);
    }
  }

  void _handleSwipe(Offset delta) {
    if (_gameState != SnakeGameState.playing) return;

    if (delta.dx.abs() > delta.dy.abs()) {
      // Horizontal swipe
      if (delta.dx > 0) {
        _changeDirection(SnakeDirection.right);
      } else {
        _changeDirection(SnakeDirection.left);
      }
    } else {
      // Vertical swipe
      if (delta.dy > 0) {
        _changeDirection(SnakeDirection.down);
      } else {
        _changeDirection(SnakeDirection.up);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        SnakeGameConstants.gameDialogInsetPadding,
      ),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: size.width > SnakeGameConstants.gameDialogMaxWidth
              ? SnakeGameConstants.gameDialogMaxWidth
              : size.width * SnakeGameConstants.gameDialogWidthRatio,
          height: size.height > SnakeGameConstants.gameDialogMaxHeight
              ? SnakeGameConstants.gameDialogMaxHeight
              : size.height * SnakeGameConstants.gameDialogHeightRatio,
          decoration: BoxDecoration(
            color: _colors.dialogBackground,
            borderRadius: BorderRadius.circular(
              SnakeGameConstants.gameDialogBorderRadius,
            ),
            border: Border.all(color: _colors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _colors.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: SnakeGameConstants.gameDialogShadowBlur,
                spreadRadius: SnakeGameConstants.gameDialogShadowSpread,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(l10n),
              Expanded(child: _buildGameArea(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SnakeGameConstants.gameHeaderPaddingH,
        vertical: SnakeGameConstants.gameHeaderPaddingV,
      ),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SnakeGameConstants.gameDialogBorderRadius),
          topRight: Radius.circular(SnakeGameConstants.gameDialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.pest_control_outlined,
                color: SnakeGameConstants.snakeColor,
                size: SnakeGameConstants.gameHeaderIconSize,
              ),
              const SizedBox(width: SnakeGameConstants.gameHeaderIconSpacing),
              Text(
                l10n.snakeGameTitle,
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: SnakeGameConstants.gameHeaderFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SnakeGameConstants.scorePaddingH,
                  vertical: SnakeGameConstants.scorePaddingV,
                ),
                decoration: BoxDecoration(
                  color: _colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    SnakeGameConstants.scoreBorderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _colors.accent,
                      size: SnakeGameConstants.scoreIconSize,
                    ),
                    const SizedBox(width: SnakeGameConstants.scoreIconSpacing),
                    Text(
                      '$_score',
                      style: TextStyle(
                        color: _colors.accent,
                        fontSize: SnakeGameConstants.scoreFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SnakeGameConstants.headerButtonSpacing),
              IconButton(
                icon: Icon(Icons.close, color: _colors.secondaryText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(AppLocalizations l10n) {
    return GestureDetector(
      onTapDown: (_) {
        if (_gameState != SnakeGameState.playing) {
          _startGame();
        }
      },
      onPanStart: (details) => _swipeStart = details.localPosition,
      onPanUpdate: (details) {
        if (_swipeStart != null) {
          final delta = details.localPosition - _swipeStart!;
          if (delta.distance > SnakeGameConstants.swipeThreshold) {
            _handleSwipe(delta);
            _swipeStart = details.localPosition;
          }
        }
      },
      onPanEnd: (_) => _swipeStart = null,
      child: Container(
        padding: const EdgeInsets.all(SnakeGameConstants.gameAreaPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gameSize =
                min(constraints.maxWidth, constraints.maxHeight) -
                SnakeGameConstants.gameAreaMargin;
            final cellSize = gameSize / SnakeGameConstants.gridSize;

            return Center(
              child: Stack(
                children: [
                  _buildGrid(gameSize, cellSize),
                  if (_gameState == SnakeGameState.waiting)
                    _buildStartOverlay(l10n, gameSize),
                  if (_gameState == SnakeGameState.gameOver)
                    _buildGameOverOverlay(l10n, gameSize),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(double gameSize, double cellSize) {
    return Container(
      width: gameSize,
      height: gameSize,
      decoration: BoxDecoration(
        color: _colors.brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          SnakeGameConstants.gridBorderRadius,
        ),
        border: Border.all(
          color: _colors.border.withValues(alpha: 0.3),
          width: SnakeGameConstants.gridBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          SnakeGameConstants.gridBorderRadius - 1,
        ),
        child: SizedBox(
          width: gameSize,
          height: gameSize,
          child: CustomPaint(
            size: Size(gameSize, gameSize),
            painter: SnakeGamePainter(
              snake: _snake,
              food: _food,
              cellSize: cellSize,
              gridSize: SnakeGameConstants.gridSize,
              snakeColor: SnakeGameConstants.snakeColor,
              snakeHeadColor: SnakeGameConstants.snakeHeadColor,
              foodColor: SnakeGameConstants.foodColor,
              gridColor: _colors.border.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartOverlay(AppLocalizations l10n, double gameSize) {
    return SizedBox(
      width: gameSize,
      height: gameSize,
      child: GameOverlayBuilder.buildStartOverlay(
        title: l10n.snakeGameTitle,
        pressToStartText: l10n.gamePressToStart,
        controlHintText: l10n.gameUseArrowKeys,
        icon: Icons.pest_control_outlined,
        iconColor: SnakeGameConstants.snakeColor,
        borderRadius: SnakeGameConstants.gridBorderRadius,
      ),
    );
  }

  Widget _buildGameOverOverlay(AppLocalizations l10n, double gameSize) {
    return SizedBox(
      width: gameSize,
      height: gameSize,
      child: GameOverlayBuilder.buildGameOverOverlay(
        gameOverText: l10n.gameOver,
        scoreText: '${l10n.gameScore}: $_score',
        expGainedText: l10n.gameExpGained(_expGained),
        playAgainText: l10n.gamePlayAgain,
        onPlayAgain: _startGame,
        errorColor: _colors.error,
        accentColor: _colors.accent,
        buttonColor: SnakeGameConstants.snakeColor,
        buttonTextColor: Colors.white,
        borderRadius: SnakeGameConstants.gridBorderRadius,
      ),
    );
  }
}

/// Custom painter for the snake game grid
class SnakeGamePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final double cellSize;
  final int gridSize;
  final Color snakeColor;
  final Color snakeHeadColor;
  final Color foodColor;
  final Color gridColor;

  SnakeGamePainter({
    required this.snake,
    required this.food,
    required this.cellSize,
    required this.gridSize,
    required this.snakeColor,
    required this.snakeHeadColor,
    required this.foodColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), gridPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), gridPaint);
    }

    // Draw food
    final foodPaint = Paint()..color = foodColor;
    final foodRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        food.x * cellSize + SnakeGameConstants.cellPadding,
        food.y * cellSize + SnakeGameConstants.cellPadding,
        cellSize - SnakeGameConstants.cellPadding * 2,
        cellSize - SnakeGameConstants.cellPadding * 2,
      ),
      const Radius.circular(SnakeGameConstants.foodBorderRadius),
    );
    canvas.drawRRect(foodRect, foodPaint);

    // Draw snake
    for (int i = 0; i < snake.length; i++) {
      final segment = snake[i];
      final isHead = i == 0;

      final paint = Paint()..color = isHead ? snakeHeadColor : snakeColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          segment.x * cellSize + SnakeGameConstants.cellPadding,
          segment.y * cellSize + SnakeGameConstants.cellPadding,
          cellSize - SnakeGameConstants.cellPadding * 2,
          cellSize - SnakeGameConstants.cellPadding * 2,
        ),
        Radius.circular(
          isHead
              ? SnakeGameConstants.snakeHeadBorderRadius
              : SnakeGameConstants.snakeBodyBorderRadius,
        ),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnakeGamePainter oldDelegate) {
    return snake != oldDelegate.snake || food != oldDelegate.food;
  }
}
