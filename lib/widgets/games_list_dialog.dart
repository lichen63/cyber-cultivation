import 'package:flutter/material.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import 'flappy_bird_game_window.dart';
import 'snake_game_window.dart';
import 'sudoku_game_window.dart';

/// Model for a game entry in the games list
class GameEntry {
  final String Function(AppLocalizations) getTitle;
  final String Function(AppLocalizations) getDescription;
  final IconData icon;
  final Color iconColor;
  final Widget Function(AppThemeColors, void Function(int)) buildGame;

  const GameEntry({
    required this.getTitle,
    required this.getDescription,
    required this.icon,
    required this.iconColor,
    required this.buildGame,
  });
}

/// Dialog that displays a list of available games
class GamesListDialog extends StatelessWidget {
  final AppThemeColors themeColors;
  final void Function(int expGained) onExpGained;

  const GamesListDialog({
    super.key,
    required this.themeColors,
    required this.onExpGained,
  });

  List<GameEntry> _getGames() {
    return [
      GameEntry(
        getTitle: (l10n) => l10n.snakeGameTitle,
        getDescription: (l10n) => l10n.snakeGameDescription,
        icon: Icons.pest_control_outlined,
        iconColor: Colors.green,
        buildGame: (colors, onExp) =>
            SnakeGameWindow(themeColors: colors, onExpGained: onExp),
      ),
      GameEntry(
        getTitle: (l10n) => l10n.flappyBirdTitle,
        getDescription: (l10n) => l10n.flappyBirdDescription,
        icon: Icons.flutter_dash,
        iconColor: const Color(0xFFFFD700),
        buildGame: (colors, onExp) =>
            FlappyBirdGameWindow(themeColors: colors, onExpGained: onExp),
      ),
      GameEntry(
        getTitle: (l10n) => l10n.sudokuTitle,
        getDescription: (l10n) => l10n.sudokuDescription,
        icon: Icons.grid_3x3,
        iconColor: const Color(0xFF1976D2),
        buildGame: (colors, onExp) =>
            SudokuGameWindow(themeColors: colors, onExpGained: onExp),
      ),
      // Add more games here in the future
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;
    final games = _getGames();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(GameConstants.gamesDialogInsetPadding),
      child: Container(
        width: size.width > GameConstants.gamesDialogMaxWidth
            ? GameConstants.gamesDialogMaxWidth
            : size.width * GameConstants.gamesDialogWidthRatio,
        height: size.height > GameConstants.gamesDialogMaxHeight
            ? GameConstants.gamesDialogMaxHeight
            : size.height * GameConstants.gamesDialogHeightRatio,
        decoration: BoxDecoration(
          color: themeColors.dialogBackground,
          borderRadius: BorderRadius.circular(
            GameConstants.gamesDialogBorderRadius,
          ),
          border: Border.all(color: themeColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: themeColors.brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: GameConstants.gamesDialogShadowBlur,
              spreadRadius: GameConstants.gamesDialogShadowSpread,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context, l10n),
            Expanded(child: _buildGamesList(context, l10n, games)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GameConstants.gamesDialogHeaderPaddingH,
        vertical: GameConstants.gamesDialogHeaderPaddingV,
      ),
      decoration: BoxDecoration(
        color: themeColors.overlayLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(GameConstants.gamesDialogBorderRadius),
          topRight: Radius.circular(GameConstants.gamesDialogBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_esports,
                color: themeColors.accent,
                size: GameConstants.gamesHeaderIconSize,
              ),
              const SizedBox(width: GameConstants.gamesHeaderIconSpacing),
              Text(
                l10n.gamesTitle,
                style: TextStyle(
                  color: themeColors.primaryText,
                  fontSize: GameConstants.gamesHeaderFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: themeColors.secondaryText),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(
    BuildContext context,
    AppLocalizations l10n,
    List<GameEntry> games,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(GameConstants.gamesListPadding),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(context, l10n, game);
      },
    );
  }

  Widget _buildGameCard(
    BuildContext context,
    AppLocalizations l10n,
    GameEntry game,
  ) {
    return Card(
      color: themeColors.overlayLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameConstants.gameCardBorderRadius),
        side: BorderSide(color: themeColors.border.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(GameConstants.gameCardBorderRadius),
        onTap: () => _openGame(context, game),
        child: Padding(
          padding: const EdgeInsets.all(GameConstants.gameCardPadding),
          child: Row(
            children: [
              Container(
                width: GameConstants.gameIconContainerSize,
                height: GameConstants.gameIconContainerSize,
                decoration: BoxDecoration(
                  color: game.iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    GameConstants.gameIconContainerRadius,
                  ),
                ),
                child: Icon(
                  game.icon,
                  color: game.iconColor,
                  size: GameConstants.gameIconSize,
                ),
              ),
              const SizedBox(width: GameConstants.gameCardContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.getTitle(l10n),
                      style: TextStyle(
                        color: themeColors.primaryText,
                        fontSize: GameConstants.gameTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: GameConstants.gameTitleSpacing),
                    Text(
                      game.getDescription(l10n),
                      style: TextStyle(
                        color: themeColors.secondaryText,
                        fontSize: GameConstants.gameDescFontSize,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: themeColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  void _openGame(BuildContext context, GameEntry game) {
    Navigator.of(context).pop(); // Close games list

    showDialog(
      context: context,
      barrierColor: themeColors.overlay,
      barrierDismissible: false,
      builder: (context) => game.buildGame(themeColors, onExpGained),
    );
  }
}
