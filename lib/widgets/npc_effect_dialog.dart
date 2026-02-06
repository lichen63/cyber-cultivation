import 'package:flutter/material.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/npc_effect.dart';

/// Show NPC encounter result dialog
Future<void> showNpcEncounterDialog({
  required BuildContext context,
  required NpcEffect effect,
  required String effectDescription,
  required AppThemeColors colors,
  required AppLocalizations l10n,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NpcEncounterDialog(
      effect: effect,
      effectDescription: effectDescription,
      colors: colors,
      l10n: l10n,
    ),
  );
}

class _NpcEncounterDialog extends StatelessWidget {
  final NpcEffect effect;
  final String effectDescription;
  final AppThemeColors colors;
  final AppLocalizations l10n;

  const _NpcEncounterDialog({
    required this.effect,
    required this.effectDescription,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = effect.isPositive;
    final effectColor = isPositive
        ? NpcEffectConstants.positiveEffectColor
        : NpcEffectConstants.negativeEffectColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: NpcEffectConstants.npcDialogWidth,
        padding: const EdgeInsets.all(NpcEffectConstants.npcDialogPadding),
        decoration: BoxDecoration(
          color: colors.dialogBackground,
          borderRadius: BorderRadius.circular(
            NpcEffectConstants.npcDialogBorderRadius,
          ),
          border: Border.all(color: effectColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: effectColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NPC icon
            Icon(
              Icons.person,
              color: ExploreConstants.npcColor,
              size: NpcEffectConstants.npcDialogIconSize,
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              l10n.npcEncounterTitle,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: NpcEffectConstants.npcDialogTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Positive/negative message
            Text(
              isPositive ? l10n.npcEffectPositive : l10n.npcEffectNegative,
              style: TextStyle(
                color: effectColor,
                fontSize: NpcEffectConstants.npcDialogDescFontSize,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Effect description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: effectColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: effectColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                effectDescription,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: NpcEffectConstants.npcDialogDescFontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // OK button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: effectColor.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.battleOkButton,
                style: TextStyle(
                  color: effectColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Show active effects list dialog
Future<void> showActiveEffectsDialog({
  required BuildContext context,
  required List<NpcEffect> effects,
  required AppThemeColors colors,
  required AppLocalizations l10n,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _ActiveEffectsDialog(effects: effects, colors: colors, l10n: l10n),
  );
}

class _ActiveEffectsDialog extends StatelessWidget {
  final List<NpcEffect> effects;
  final AppThemeColors colors;
  final AppLocalizations l10n;

  const _ActiveEffectsDialog({
    required this.effects,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: NpcEffectConstants.effectDialogMaxWidth,
          maxHeight: NpcEffectConstants.effectDialogMaxHeight,
        ),
        padding: const EdgeInsets.all(NpcEffectConstants.effectDialogPadding),
        decoration: BoxDecoration(
          color: colors.dialogBackground,
          borderRadius: BorderRadius.circular(
            NpcEffectConstants.effectDialogBorderRadius,
          ),
          border: Border.all(color: colors.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.npcEffectsDialogTitle,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: NpcEffectConstants.effectDialogTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: colors.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Effects list
            if (effects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.npcEffectsEmpty,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: NpcEffectConstants.effectDialogDescFontSize,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: effects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildEffectItem(effects[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectItem(NpcEffect effect) {
    final effectColor = effect.isPositive
        ? NpcEffectConstants.positiveEffectColor
        : NpcEffectConstants.negativeEffectColor;

    final def = NpcEffectRegistry.get(effect.typeId);
    final icon = def?.getIcon(effect) ?? Icons.help_outline;
    final effectName = def?.getName(effect, l10n) ?? effect.typeId;
    final effectDesc = def?.getActiveDescription(effect, l10n) ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NpcEffectConstants.effectItemPaddingH,
        vertical: NpcEffectConstants.effectItemPaddingV,
      ),
      decoration: BoxDecoration(
        color: effectColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          NpcEffectConstants.effectItemBorderRadius,
        ),
        border: Border.all(color: effectColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: effectColor,
            size: NpcEffectConstants.effectItemIconSize,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectName,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: NpcEffectConstants.effectItemTitleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  effectDesc,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: NpcEffectConstants.effectItemDetailFontSize,
                  ),
                ),
              ],
            ),
          ),
          if (effect.remainingBattles > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: effectColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.npcEffectRemainingBattles(effect.remainingBattles),
                style: TextStyle(
                  color: effectColor,
                  fontSize: NpcEffectConstants.effectItemDetailFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
