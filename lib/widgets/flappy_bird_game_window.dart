import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import 'base_game_window.dart';

/// State of the flappy bird game
enum FlappyBirdGameState { waiting, playing, gameOver }

/// Represents a pipe obstacle
class Pipe {
  double x;
  final double gapY;
  bool passed;

  Pipe({required this.x, required this.gapY, this.passed = false});
}

/// Classic Flappy Bird game widget
class FlappyBirdGameWindow extends StatefulWidget {
  final AppThemeColors themeColors;
  final void Function(int expGained) onExpGained;

  const FlappyBirdGameWindow({
    super.key,
    required this.themeColors,
    required this.onExpGained,
  });

  @override
  State<FlappyBirdGameWindow> createState() => _FlappyBirdGameWindowState();
}

class _FlappyBirdGameWindowState extends State<FlappyBirdGameWindow>
    with GameKeyboardMixin, GameRestartCooldownMixin {
  // Game state
  FlappyBirdGameState _gameState = FlappyBirdGameState.waiting;
  double _birdY = FlappyBirdConstants.birdStartY;
  double _birdVelocity = 0;
  List<Pipe> _pipes = [];
  int _score = 0;
  int _expGained = 0;

  // Game timer
  Timer? _gameTimer;
  Timer? _pipeSpawnTimer;
  final Random _random = Random();

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
    _pipeSpawnTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame() {
    _birdY = FlappyBirdConstants.birdStartY;
    _birdVelocity = 0;
    _pipes = [];
    _score = 0;
    _expGained = 0;
  }

  void _startGame() {
    if (_gameState == FlappyBirdGameState.playing) return;

    setState(() {
      if (_gameState == FlappyBirdGameState.gameOver) {
        _initGame();
      }
      _gameState = FlappyBirdGameState.playing;
      _birdVelocity = FlappyBirdConstants.birdJumpVelocity;
    });

    _gameTimer = Timer.periodic(
      const Duration(milliseconds: FlappyBirdConstants.gameTickMs),
      (_) => _tick(),
    );

    _pipeSpawnTimer = Timer.periodic(
      Duration(
        milliseconds: FlappyBirdConstants.pipeSpawnInterval.toInt(),
      ),
      (_) => _spawnPipe(),
    );

    // Spawn first pipe immediately
    _spawnPipe();
  }

  void _spawnPipe() {
    if (_gameState != FlappyBirdGameState.playing) return;

    final maxGapY = FlappyBirdConstants.gameHeight -
        FlappyBirdConstants.pipeGap -
        FlappyBirdConstants.minPipeHeight;
    final gapY = FlappyBirdConstants.minPipeHeight +
        _random.nextDouble() * (maxGapY - FlappyBirdConstants.minPipeHeight);

    setState(() {
      _pipes.add(
        Pipe(x: FlappyBirdConstants.gameWidth, gapY: gapY),
      );
    });
  }

  void _tick() {
    if (_gameState != FlappyBirdGameState.playing) return;

    setState(() {
      // Apply gravity to bird
      _birdVelocity += FlappyBirdConstants.gravity;
      if (_birdVelocity > FlappyBirdConstants.maxFallVelocity) {
        _birdVelocity = FlappyBirdConstants.maxFallVelocity;
      }
      _birdY += _birdVelocity;

      // Check ceiling/floor collision
      if (_birdY < 0 ||
          _birdY + FlappyBirdConstants.birdSize >
              FlappyBirdConstants.gameHeight) {
        _endGame();
        return;
      }

      // Move pipes and check collisions
      for (int i = _pipes.length - 1; i >= 0; i--) {
        final pipe = _pipes[i];
        pipe.x -= FlappyBirdConstants.pipeSpeed;

        // Remove pipes that are off screen
        if (pipe.x + FlappyBirdConstants.pipeWidth < 0) {
          _pipes.removeAt(i);
          continue;
        }

        // Check if bird passed the pipe
        if (!pipe.passed &&
            pipe.x + FlappyBirdConstants.pipeWidth < FlappyBirdConstants.birdX) {
          pipe.passed = true;
          _score += FlappyBirdConstants.scorePerPipe;
          _expGained += FlappyBirdConstants.expPerScore;
        }

        // Check collision with pipe
        if (_checkPipeCollision(pipe)) {
          _endGame();
          return;
        }
      }
    });
  }

  bool _checkPipeCollision(Pipe pipe) {
    final birdLeft = FlappyBirdConstants.birdX;
    final birdRight = FlappyBirdConstants.birdX + FlappyBirdConstants.birdSize;
    final birdTop = _birdY;
    final birdBottom = _birdY + FlappyBirdConstants.birdSize;

    final pipeLeft = pipe.x;
    final pipeRight = pipe.x + FlappyBirdConstants.pipeWidth;
    final gapTop = pipe.gapY;
    final gapBottom = pipe.gapY + FlappyBirdConstants.pipeGap;

    // Check if bird is within pipe's horizontal range
    if (birdRight > pipeLeft && birdLeft < pipeRight) {
      // Check if bird hits top or bottom pipe
      if (birdTop < gapTop || birdBottom > gapBottom) {
        return true;
      }
    }

    return false;
  }

  void _endGame() {
    _gameTimer?.cancel();
    _pipeSpawnTimer?.cancel();
    _gameState = FlappyBirdGameState.gameOver;

    // Prevent accidental restart by adding cooldown
    startRestartCooldown();

    // Notify parent about exp gained
    if (_expGained > 0) {
      widget.onExpGained(_expGained);
    }
  }

  void _flap() {
    if (_gameState == FlappyBirdGameState.waiting) {
      _startGame();
      return;
    }

    if (_gameState == FlappyBirdGameState.gameOver) {
      tryRestart(_startGame);
      return;
    }

    if (_gameState == FlappyBirdGameState.playing) {
      setState(() {
        _birdVelocity = FlappyBirdConstants.birdJumpVelocity;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    // Handle common keys (ESC to close)
    if (handleCommonKeyEvent(event)) return;
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _flap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        FlappyBirdConstants.gameDialogInsetPadding,
      ),
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: size.width > FlappyBirdConstants.gameDialogMaxWidth
              ? FlappyBirdConstants.gameDialogMaxWidth
              : size.width * FlappyBirdConstants.gameDialogWidthRatio,
          height: size.height > FlappyBirdConstants.gameDialogMaxHeight
              ? FlappyBirdConstants.gameDialogMaxHeight
              : size.height * FlappyBirdConstants.gameDialogHeightRatio,
          decoration: BoxDecoration(
            color: _colors.dialogBackground,
            borderRadius: BorderRadius.circular(
              FlappyBirdConstants.gameDialogBorderRadius,
            ),
            border: Border.all(color: _colors.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _colors.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: FlappyBirdConstants.gameDialogShadowBlur,
                spreadRadius: FlappyBirdConstants.gameDialogShadowSpread,
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
        horizontal: FlappyBirdConstants.gameHeaderPaddingH,
        vertical: FlappyBirdConstants.gameHeaderPaddingV,
      ),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(FlappyBirdConstants.gameDialogBorderRadius),
          topRight: Radius.circular(FlappyBirdConstants.gameDialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.flutter_dash,
                color: FlappyBirdConstants.birdColor,
                size: FlappyBirdConstants.gameHeaderIconSize,
              ),
              const SizedBox(width: FlappyBirdConstants.gameHeaderIconSpacing),
              Text(
                l10n.flappyBirdTitle,
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: FlappyBirdConstants.gameHeaderFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlappyBirdConstants.scorePaddingH,
                  vertical: FlappyBirdConstants.scorePaddingV,
                ),
                decoration: BoxDecoration(
                  color: _colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    FlappyBirdConstants.scoreBorderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: _colors.accent,
                      size: FlappyBirdConstants.scoreIconSize,
                    ),
                    const SizedBox(width: FlappyBirdConstants.scoreIconSpacing),
                    Text(
                      '$_score',
                      style: TextStyle(
                        color: _colors.accent,
                        fontSize: FlappyBirdConstants.scoreFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FlappyBirdConstants.headerButtonSpacing),
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
      onTapDown: (_) => _flap(),
      child: Container(
        padding: const EdgeInsets.all(FlappyBirdConstants.gameAreaPadding),
        child: Center(
          child: AspectRatio(
            aspectRatio:
                FlappyBirdConstants.gameWidth / FlappyBirdConstants.gameHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    constraints.maxWidth / FlappyBirdConstants.gameWidth;

                return Stack(
                  children: [
                    _buildGameCanvas(scale),
                    if (_gameState == FlappyBirdGameState.waiting)
                      _buildStartOverlay(l10n),
                    if (_gameState == FlappyBirdGameState.gameOver)
                      _buildGameOverOverlay(l10n),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCanvas(double scale) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FlappyBirdConstants.skyColorTop,
            FlappyBirdConstants.skyColorBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(
          FlappyBirdConstants.gameBorderRadius,
        ),
        border: Border.all(
          color: _colors.border.withValues(alpha: 0.3),
          width: FlappyBirdConstants.gameBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          FlappyBirdConstants.gameBorderRadius - 1,
        ),
        child: CustomPaint(
          painter: FlappyBirdPainter(
            birdY: _birdY,
            pipes: _pipes,
            scale: scale,
          ),
          size: Size(
            FlappyBirdConstants.gameWidth * scale,
            FlappyBirdConstants.gameHeight * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildStartOverlay(AppLocalizations l10n) {
    return GameOverlayBuilder.buildStartOverlay(
      title: l10n.flappyBirdTitle,
      pressToStartText: l10n.gamePressToStart,
      controlHintText: l10n.flappyBirdTapToFlap,
      icon: Icons.flutter_dash,
      iconColor: FlappyBirdConstants.birdColor,
      borderRadius: FlappyBirdConstants.gameBorderRadius,
    );
  }

  Widget _buildGameOverOverlay(AppLocalizations l10n) {
    return GameOverlayBuilder.buildGameOverOverlay(
      gameOverText: l10n.gameOver,
      scoreText: '${l10n.gameScore}: $_score',
      expGainedText: l10n.gameExpGained(_expGained),
      playAgainText: l10n.gamePlayAgain,
      onPlayAgain: _startGame,
      errorColor: _colors.error,
      accentColor: _colors.accent,
      buttonColor: FlappyBirdConstants.birdColor,
      buttonTextColor: Colors.black,
      borderRadius: FlappyBirdConstants.gameBorderRadius,
    );
  }
}

/// Custom painter for the Flappy Bird game
class FlappyBirdPainter extends CustomPainter {
  final double birdY;
  final List<Pipe> pipes;
  final double scale;

  FlappyBirdPainter({
    required this.birdY,
    required this.pipes,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw pipes
    final pipePaint = Paint()..color = FlappyBirdConstants.pipeColor;
    final pipeOutlinePaint = Paint()
      ..color = FlappyBirdConstants.pipeOutlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    for (final pipe in pipes) {
      final pipeLeft = pipe.x * scale;
      final pipeWidth = FlappyBirdConstants.pipeWidth * scale;
      final gapTop = pipe.gapY * scale;
      final gapBottom = (pipe.gapY + FlappyBirdConstants.pipeGap) * scale;

      // Top pipe
      final topPipeRect = Rect.fromLTWH(pipeLeft, 0, pipeWidth, gapTop);
      canvas.drawRect(topPipeRect, pipePaint);
      canvas.drawRect(topPipeRect, pipeOutlinePaint);

      // Top pipe cap
      final topCapRect = Rect.fromLTWH(
        pipeLeft - 3 * scale,
        gapTop - 20 * scale,
        pipeWidth + 6 * scale,
        20 * scale,
      );
      canvas.drawRect(topCapRect, pipePaint);
      canvas.drawRect(topCapRect, pipeOutlinePaint);

      // Bottom pipe
      final bottomPipeRect = Rect.fromLTWH(
        pipeLeft,
        gapBottom,
        pipeWidth,
        size.height - gapBottom,
      );
      canvas.drawRect(bottomPipeRect, pipePaint);
      canvas.drawRect(bottomPipeRect, pipeOutlinePaint);

      // Bottom pipe cap
      final bottomCapRect = Rect.fromLTWH(
        pipeLeft - 3 * scale,
        gapBottom,
        pipeWidth + 6 * scale,
        20 * scale,
      );
      canvas.drawRect(bottomCapRect, pipePaint);
      canvas.drawRect(bottomCapRect, pipeOutlinePaint);
    }

    // Draw bird
    final birdPaint = Paint()..color = FlappyBirdConstants.birdColor;
    final birdOutlinePaint = Paint()
      ..color = FlappyBirdConstants.birdOutlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    final birdCenter = Offset(
      (FlappyBirdConstants.birdX + FlappyBirdConstants.birdSize / 2) * scale,
      (birdY + FlappyBirdConstants.birdSize / 2) * scale,
    );
    final birdRadius = (FlappyBirdConstants.birdSize / 2) * scale;

    canvas.drawCircle(birdCenter, birdRadius, birdPaint);
    canvas.drawCircle(birdCenter, birdRadius, birdOutlinePaint);

    // Draw bird eye
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    final eyeCenter = Offset(
      birdCenter.dx + 5 * scale,
      birdCenter.dy - 3 * scale,
    );
    canvas.drawCircle(eyeCenter, 5 * scale, eyePaint);
    canvas.drawCircle(
      Offset(eyeCenter.dx + 1 * scale, eyeCenter.dy),
      2 * scale,
      pupilPaint,
    );

    // Draw bird beak
    final beakPaint = Paint()..color = Colors.orange;
    final beakPath = Path()
      ..moveTo(birdCenter.dx + birdRadius * 0.7, birdCenter.dy)
      ..lineTo(birdCenter.dx + birdRadius * 1.5, birdCenter.dy + 2 * scale)
      ..lineTo(birdCenter.dx + birdRadius * 0.7, birdCenter.dy + 5 * scale)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
  }

  @override
  bool shouldRepaint(covariant FlappyBirdPainter oldDelegate) {
    return birdY != oldDelegate.birdY || pipes != oldDelegate.pipes;
  }
}
