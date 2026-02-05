import 'package:flutter/material.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/battle_result.dart';
import '../models/explore_map.dart';

/// Shows the battle encounter dialog before fighting
/// Returns true if player chooses to fight, false if flee succeeds
/// Returns null if flee fails (player is forced to fight)
Future<bool?> showBattleEncounterDialog({
  required BuildContext context,
  required ExploreCellType enemyType,
  required double playerFC,
  required double enemyFC,
  required AppThemeColors colors,
  required AppLocalizations l10n,
}) async {
  return showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.overlay,
    builder: (context) => _BattleEncounterDialog(
      enemyType: enemyType,
      playerFC: playerFC,
      enemyFC: enemyFC,
      colors: colors,
      l10n: l10n,
    ),
  );
}

/// Shows the battle result dialog after fighting
Future<void> showBattleResultDialog({
  required BuildContext context,
  required BattleResult result,
  required AppThemeColors colors,
  required AppLocalizations l10n,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.overlay,
    builder: (context) =>
        _BattleResultDialog(result: result, colors: colors, l10n: l10n),
  );
}

/// Shows the flee result dialog
Future<void> showFleeResultDialog({
  required BuildContext context,
  required bool success,
  required AppThemeColors colors,
  required AppLocalizations l10n,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: colors.overlay,
    builder: (context) =>
        _FleeResultDialog(success: success, colors: colors, l10n: l10n),
  );
}

class _BattleEncounterDialog extends StatelessWidget {
  final ExploreCellType enemyType;
  final double playerFC;
  final double enemyFC;
  final AppThemeColors colors;
  final AppLocalizations l10n;

  const _BattleEncounterDialog({
    required this.enemyType,
    required this.playerFC,
    required this.enemyFC,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isBoss = enemyType == ExploreCellType.boss;
    final enemyColor = isBoss
        ? ExploreConstants.bossColor
        : ExploreConstants.monsterColor;

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ExploreConstants.battleDialogBorderRadius,
        ),
        side: BorderSide(color: colors.border, width: 2),
      ),
      contentPadding: const EdgeInsets.all(
        ExploreConstants.battleDialogPadding,
      ),
      content: SizedBox(
        width: ExploreConstants.battleDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  color: colors.accent,
                  size: ExploreConstants.battleDialogIconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.battleEncounterTitle,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: ExploreConstants.battleDialogTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isBoss ? l10n.battleEncounterBoss : l10n.battleEncounterMonster,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: ExploreConstants.battleDialogSubtitleFontSize,
              ),
            ),
            const SizedBox(height: 24),

            // Player vs Enemy comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Player side
                _buildFighterColumn(
                  icon: Icons.person,
                  iconColor: ExploreConstants.playerColor,
                  label: l10n.battleYourPower,
                  fc: playerFC,
                ),
                // VS
                Text(
                  'VS',
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Enemy side
                _buildFighterColumn(
                  icon: isBoss ? Icons.whatshot : Icons.bug_report,
                  iconColor: enemyColor,
                  label: l10n.battleEnemyPower,
                  fc: enemyFC,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flee button
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.secondaryText,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.directions_run, size: 18),
                  label: Text(l10n.battleFleeButton),
                ),
                const SizedBox(
                  width: ExploreConstants.battleDialogButtonSpacing,
                ),
                // Fight button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.dialogBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: Text(l10n.battleFightButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFighterColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double fc,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 40),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: colors.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormatter.format(fc),
          style: TextStyle(
            color: colors.primaryText,
            fontSize: ExploreConstants.battleDialogFCFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BattleResultDialog extends StatelessWidget {
  final BattleResult result;
  final AppThemeColors colors;
  final AppLocalizations l10n;

  const _BattleResultDialog({
    required this.result,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isVictory = result.isVictory;
    final resultColor = isVictory ? colors.accent : colors.error;
    final resultIcon = isVictory ? Icons.emoji_events : Icons.heart_broken;

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ExploreConstants.battleDialogBorderRadius,
        ),
        side: BorderSide(color: resultColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(
        ExploreConstants.battleDialogPadding,
      ),
      content: SizedBox(
        width: ExploreConstants.battleDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon
            Icon(resultIcon, color: resultColor, size: 64),
            const SizedBox(height: 16),

            // Result title
            Text(
              isVictory ? l10n.battleResultVictory : l10n.battleResultDefeat,
              style: TextStyle(
                color: resultColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Power comparison
            Text(
              '${l10n.battleYourPower}: ${NumberFormatter.format(result.playerFC)}  '
              'vs  ${l10n.battleEnemyPower}: ${NumberFormatter.format(result.enemyFC)}',
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // EXP change
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isVictory
                    ? colors.accent.withValues(alpha: 0.2)
                    : colors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isVictory
                    ? l10n.battleExpGained(
                        NumberFormatter.format(result.expChange.abs()),
                      )
                    : l10n.battleExpLost(
                        NumberFormatter.format(result.expChange.abs()),
                      ),
                style: TextStyle(
                  color: resultColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // OK button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: resultColor,
                foregroundColor: colors.dialogBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.battleOkButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleeResultDialog extends StatelessWidget {
  final bool success;
  final AppThemeColors colors;
  final AppLocalizations l10n;

  const _FleeResultDialog({
    required this.success,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor = success ? colors.accent : colors.error;
    final resultIcon = success ? Icons.directions_run : Icons.dangerous;

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ExploreConstants.battleDialogBorderRadius,
        ),
        side: BorderSide(color: resultColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(
        ExploreConstants.battleDialogPadding,
      ),
      content: SizedBox(
        width: ExploreConstants.battleDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon
            Icon(resultIcon, color: resultColor, size: 64),
            const SizedBox(height: 16),

            // Result text
            Text(
              success ? l10n.battleFleeSuccess : l10n.battleFleeFailed,
              style: TextStyle(
                color: resultColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // OK button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: resultColor,
                foregroundColor: colors.dialogBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.battleOkButton),
            ),
          ],
        ),
      ),
    );
  }
}
