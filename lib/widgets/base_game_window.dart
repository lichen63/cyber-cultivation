import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mixin for common game window keyboard handling
/// Add this to any game window state to get ESC key support
mixin GameKeyboardMixin<T extends StatefulWidget> on State<T> {
  /// Handle common keyboard events (ESC to close)
  /// Returns true if the key was handled
  bool handleCommonKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return true;
    }

    return false;
  }
}

/// Mixin for restart cooldown logic to prevent accidental restart
/// Add this to any game window state to get restart cooldown support
mixin GameRestartCooldownMixin<T extends StatefulWidget> on State<T> {
  /// Cooldown duration in milliseconds
  static const int restartCooldownMs = 1000;

  /// Whether restart is currently allowed
  bool _canRestart = true;

  /// Check if restart is allowed
  bool get canRestart => _canRestart;

  /// Start the cooldown timer (call this when game ends)
  void startRestartCooldown() {
    _canRestart = false;
    Future.delayed(const Duration(milliseconds: restartCooldownMs), () {
      if (mounted) {
        setState(() {
          _canRestart = true;
        });
      }
    });
  }

  /// Reset the cooldown (call this when initializing game)
  void resetRestartCooldown() {
    _canRestart = true;
  }

  /// Try to restart the game if cooldown has passed
  /// Returns true if restart was allowed, false otherwise
  bool tryRestart(VoidCallback startGame) {
    if (_canRestart) {
      startGame();
      return true;
    }
    return false;
  }
}

/// Common overlay constants for all games
class GameOverlayConstants {
  static const double iconSize = 40.0;
  static const double spacing = 12.0;
  static const double smallSpacing = 6.0;
  static const double largeSpacing = 16.0;
  static const double titleFontSize = 22.0;
  static const double subtitleFontSize = 12.0;
  static const double hintFontSize = 10.0;
  static const double gameOverTitleFontSize = 24.0;
  static const double scoreFontSize = 14.0;
  static const double expFontSize = 12.0;
  static const double buttonPaddingH = 16.0;
  static const double buttonPaddingV = 8.0;
  static const double buttonBorderRadius = 12.0;
  static const double borderRadius = 8.0;
}

/// Helper class to build common game overlays
class GameOverlayBuilder {
  /// Build a standard start overlay
  static Widget buildStartOverlay({
    required String title,
    required String pressToStartText,
    required String controlHintText,
    required IconData icon,
    required Color iconColor,
    double borderRadius = GameOverlayConstants.borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: GameOverlayConstants.iconSize,
                ),
                const SizedBox(height: GameOverlayConstants.spacing),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: GameOverlayConstants.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: GameOverlayConstants.spacing),
                Text(
                  pressToStartText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: GameOverlayConstants.subtitleFontSize,
                  ),
                ),
                const SizedBox(height: GameOverlayConstants.smallSpacing),
                Text(
                  controlHintText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: GameOverlayConstants.hintFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a standard game over overlay
  static Widget buildGameOverOverlay({
    required String gameOverText,
    required String scoreText,
    required String expGainedText,
    required String playAgainText,
    required VoidCallback onPlayAgain,
    required Color errorColor,
    required Color accentColor,
    required Color buttonColor,
    required Color buttonTextColor,
    double borderRadius = GameOverlayConstants.borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gameOverText,
                  style: TextStyle(
                    color: errorColor,
                    fontSize: GameOverlayConstants.gameOverTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: GameOverlayConstants.spacing),
                Text(
                  scoreText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: GameOverlayConstants.scoreFontSize,
                  ),
                ),
                const SizedBox(height: GameOverlayConstants.smallSpacing),
                Text(
                  expGainedText,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: GameOverlayConstants.expFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: GameOverlayConstants.largeSpacing),
                ElevatedButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay),
                  label: Text(playAgainText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: GameOverlayConstants.buttonPaddingH,
                      vertical: GameOverlayConstants.buttonPaddingV,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        GameOverlayConstants.buttonBorderRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
