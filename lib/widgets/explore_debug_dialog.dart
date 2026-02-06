import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/npc_effect.dart';

/// Battle mode for debug purposes
enum DebugBattleMode { normal, autoWin, autoLose }

/// Debug dialog for the explore window.
/// Provides tools for testing: fog toggle, AP modification,
/// teleport, invincibility, house reset, and map regeneration.
class ExploreDebugDialog extends StatefulWidget {
  final AppThemeColors themeColors;
  final bool fogRevealed;
  final int currentAP;
  final int maxAP;
  final int playerX;
  final int playerY;
  final int gridSize;
  final DebugBattleMode battleMode;
  final void Function(bool fogRevealed) onFogToggle;
  final void Function(int ap) onSetAP;
  final void Function(int x, int y) onTeleport;
  final void Function(DebugBattleMode mode) onBattleModeChanged;
  final VoidCallback onResetHouses;
  final VoidCallback onRegenerateMap;
  final void Function(List<NpcEffect> effects) onAddEffects;

  const ExploreDebugDialog({
    super.key,
    required this.themeColors,
    required this.fogRevealed,
    required this.currentAP,
    required this.maxAP,
    required this.playerX,
    required this.playerY,
    required this.gridSize,
    required this.battleMode,
    required this.onFogToggle,
    required this.onSetAP,
    required this.onTeleport,
    required this.onBattleModeChanged,
    required this.onResetHouses,
    required this.onRegenerateMap,
    required this.onAddEffects,
  });

  @override
  State<ExploreDebugDialog> createState() => _ExploreDebugDialogState();
}

class _ExploreDebugDialogState extends State<ExploreDebugDialog> {
  late TextEditingController _apController;
  late TextEditingController _teleportXController;
  late TextEditingController _teleportYController;
  late bool _fogRevealed;
  late DebugBattleMode _battleMode;
  String? _teleportError;

  /// Selected effect type IDs
  final Set<String> _selectedEffects = {};

  /// Whether each selected effect should be positive (true) or negative (false)
  final Map<String, bool> _effectPositive = {};

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _fogRevealed = widget.fogRevealed;
    _battleMode = widget.battleMode;
    _apController = TextEditingController(text: widget.currentAP.toString());
    _teleportXController = TextEditingController(
      text: widget.playerX.toString(),
    );
    _teleportYController = TextEditingController(
      text: widget.playerY.toString(),
    );
  }

  @override
  void dispose() {
    _apController.dispose();
    _teleportXController.dispose();
    _teleportYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ExploreConstants.dialogBorderRadius,
        ),
        side: BorderSide(
          color: _colors.accent,
          width: ExploreConstants.dialogBorderWidth,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.bug_report, color: _colors.accent, size: 24),
          const SizedBox(width: 8),
          Text(
            l10n.exploreDebugTitle,
            style: TextStyle(
              color: _colors.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFogToggle(l10n),
              const SizedBox(height: 16),
              _buildApModifier(l10n),
              const SizedBox(height: 16),
              _buildTeleport(l10n),
              const SizedBox(height: 16),
              _buildBattleMode(l10n),
              const SizedBox(height: 16),
              _buildResetHouses(l10n),
              const SizedBox(height: 16),
              _buildRegenerateMap(l10n),
              const SizedBox(height: 16),
              _buildEffectsSelector(l10n),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.closeButtonText,
            style: TextStyle(color: _colors.inactive),
          ),
        ),
      ],
    );
  }

  /// Build fog of war toggle section
  Widget _buildFogToggle(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.visibility,
      label: l10n.exploreDebugToggleFog,
      child: Row(
        children: [
          Text(
            _fogRevealed ? l10n.exploreDebugFogOff : l10n.exploreDebugFogOn,
            style: TextStyle(
              color: _fogRevealed ? _colors.accent : _colors.secondaryText,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Switch(
            value: _fogRevealed,
            activeTrackColor: _colors.accent.withValues(alpha: 0.5),
            activeThumbColor: _colors.accent,
            onChanged: (value) {
              setState(() => _fogRevealed = value);
              widget.onFogToggle(value);
            },
          ),
        ],
      ),
    );
  }

  /// Build AP modifier section
  Widget _buildApModifier(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.bolt,
      label: l10n.exploreDebugModifyAp,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _apController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: _colors.primaryText, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.exploreDebugApHint,
                hintStyle: TextStyle(
                  color: _colors.secondaryText.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _colors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '/ ${widget.maxAP}',
            style: TextStyle(color: _colors.secondaryText, fontSize: 13),
          ),
          const SizedBox(width: 8),
          _buildSmallButton(
            label: l10n.debugApplyButton,
            onPressed: () {
              final ap = int.tryParse(_apController.text);
              if (ap != null && ap >= 0) {
                widget.onSetAP(ap);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build teleport section
  Widget _buildTeleport(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.place,
      label: l10n.exploreDebugTeleport,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.exploreDebugTeleportX,
                style: TextStyle(color: _colors.secondaryText, fontSize: 13),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _teleportXController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: _colors.primaryText, fontSize: 14),
                  decoration: _coordInputDecoration(),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.exploreDebugTeleportY,
                style: TextStyle(color: _colors.secondaryText, fontSize: 13),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _teleportYController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: _colors.primaryText, fontSize: 14),
                  decoration: _coordInputDecoration(),
                ),
              ),
              const SizedBox(width: 8),
              _buildSmallButton(
                label: l10n.exploreDebugTeleportGo,
                onPressed: _handleTeleport,
              ),
            ],
          ),
          if (_teleportError != null) ...[
            const SizedBox(height: 4),
            Text(
              _teleportError!,
              style: TextStyle(color: _colors.error, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTeleport() {
    final l10n = AppLocalizations.of(context)!;
    final x = int.tryParse(_teleportXController.text);
    final y = int.tryParse(_teleportYController.text);
    if (x == null ||
        y == null ||
        x < 0 ||
        x >= widget.gridSize ||
        y < 0 ||
        y >= widget.gridSize) {
      setState(() => _teleportError = l10n.exploreDebugTeleportInvalid);
      return;
    }
    setState(() => _teleportError = null);
    widget.onTeleport(x, y);
    Navigator.of(context).pop();
  }

  /// Build battle mode section
  Widget _buildBattleMode(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.shield,
      label: l10n.exploreDebugBattleMode,
      child: Row(
        children: [
          _buildModeChip(
            label: l10n.exploreDebugBattleNormal,
            selected: _battleMode == DebugBattleMode.normal,
            onTap: () => _setBattleMode(DebugBattleMode.normal),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            label: l10n.exploreDebugBattleAutoWin,
            selected: _battleMode == DebugBattleMode.autoWin,
            color: ExploreConstants.apColorHigh,
            onTap: () => _setBattleMode(DebugBattleMode.autoWin),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            label: l10n.exploreDebugBattleAutoLose,
            selected: _battleMode == DebugBattleMode.autoLose,
            color: _colors.error,
            onTap: () => _setBattleMode(DebugBattleMode.autoLose),
          ),
        ],
      ),
    );
  }

  void _setBattleMode(DebugBattleMode mode) {
    setState(() => _battleMode = mode);
    widget.onBattleModeChanged(mode);
  }

  /// Build reset houses section
  Widget _buildResetHouses(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.home,
      label: l10n.exploreDebugResetHouses,
      child: Row(
        children: [
          _buildSmallButton(
            label: l10n.exploreDebugResetHouses,
            onPressed: () {
              widget.onResetHouses();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Build regenerate map section
  Widget _buildRegenerateMap(AppLocalizations l10n) {
    return _buildSection(
      icon: Icons.refresh,
      label: l10n.exploreDebugRegenerateMap,
      child: Row(
        children: [
          _buildSmallButton(
            label: l10n.exploreDebugRegenerateMap,
            color: _colors.error,
            onPressed: () {
              widget.onRegenerateMap();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  /// Build a debug section with icon, label, and child content
  Widget _buildSection({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colors.overlay,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _colors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _colors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Build a small action button
  Widget _buildSmallButton({
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: (color ?? _colors.accent).withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: (color ?? _colors.accent).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? _colors.accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Build a battle mode selection chip
  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? _colors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? chipColor : _colors.border.withValues(alpha: 0.5),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : _colors.secondaryText,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build input decoration for coordinate fields
  InputDecoration _coordInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: _colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: _colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: _colors.accent),
      ),
    );
  }

  /// Build NPC effects selector section
  Widget _buildEffectsSelector(AppLocalizations l10n) {
    // Ensure registry is initialized
    NpcEffectRegistry.initialize();
    final allDefs = NpcEffectRegistry.all;

    return _buildSection(
      icon: Icons.auto_awesome,
      label: l10n.exploreDebugAddEffects,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Apply button row (at top for visibility)
          Row(
            children: [
              Text(
                '${_selectedEffects.length} selected',
                style: TextStyle(color: _colors.secondaryText, fontSize: 12),
              ),
              const Spacer(),
              _buildSmallButton(
                label: l10n.exploreDebugApplyEffects,
                onPressed: _selectedEffects.isEmpty
                    ? () {}
                    : _applySelectedEffects,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Effect list with checkboxes
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              border: Border.all(color: _colors.border.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allDefs.length,
              itemBuilder: (context, index) {
                final def = allDefs[index];
                final typeId = def.typeId;
                final isSelected = _selectedEffects.contains(typeId);
                final isPositive = _effectPositive[typeId] ?? true;

                // Create a dummy effect to get the name
                final dummyEffect = NpcEffect(typeId: typeId, isPositive: true);
                final effectName = def.getName(dummyEffect, l10n);

                return _buildEffectItem(
                  typeId: typeId,
                  name: effectName,
                  isSelected: isSelected,
                  isPositive: isPositive,
                  l10n: l10n,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single effect item with checkbox and positive/negative toggle
  Widget _buildEffectItem({
    required String typeId,
    required String name,
    required bool isSelected,
    required bool isPositive,
    required AppLocalizations l10n,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedEffects.remove(typeId);
          } else {
            _selectedEffects.add(typeId);
            _effectPositive[typeId] = true; // Default to positive
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _colors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                activeColor: _colors.accent,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedEffects.add(typeId);
                      _effectPositive[typeId] = true;
                    } else {
                      _selectedEffects.remove(typeId);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Effect name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected
                      ? _colors.primaryText
                      : _colors.secondaryText,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Positive/Negative toggle (only show when selected)
            if (isSelected) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _effectPositive[typeId] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? ExploreConstants.apColorHigh.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isPositive
                          ? ExploreConstants.apColorHigh
                          : _colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: isPositive
                          ? ExploreConstants.apColorHigh
                          : _colors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _effectPositive[typeId] = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: !isPositive
                        ? _colors.error.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: !isPositive
                          ? _colors.error
                          : _colors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: !isPositive
                          ? _colors.error
                          : _colors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Apply selected effects and close dialog
  void _applySelectedEffects() {
    if (_selectedEffects.isEmpty) return;

    final effects = <NpcEffect>[];
    for (final typeId in _selectedEffects) {
      final isPositive = _effectPositive[typeId] ?? true;
      final def = NpcEffectRegistry.get(typeId);
      if (def != null) {
        // Create effect with the selected polarity
        // For effects that need duration (like radar hide effects), we need special handling
        final effect = _createEffectWithPolarity(def, isPositive);
        effects.add(effect);
      }
    }

    widget.onAddEffects(effects);
    Navigator.of(context).pop();
  }

  /// Create an effect with the specified polarity
  NpcEffect _createEffectWithPolarity(
    NpcEffectDefinition def,
    bool isPositive,
  ) {
    // For radar effects that hide things, negative needs duration
    if (!isPositive &&
        (def.typeId == 'boss_radar' ||
            def.typeId == 'npc_radar' ||
            def.typeId == 'monster_radar' ||
            def.typeId == 'house_radar')) {
      return _createRadarHideEffect(def.typeId);
    }

    // For map_reveal negative, needs duration
    if (!isPositive && def.typeId == 'map_reveal') {
      return NpcEffect(
        typeId: def.typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.fovShrinkMovesDuration,
      );
    }

    // Default: create simple effect
    return NpcEffect(typeId: def.typeId, isPositive: isPositive);
  }

  /// Create radar hide effect with proper duration
  NpcEffect _createRadarHideEffect(String typeId) {
    switch (typeId) {
      case 'boss_radar':
        return NpcEffect(
          typeId: typeId,
          isPositive: false,
          durationType: EffectDurationType.moves,
          remainingMoves: NpcEffectConstants.radarHideDurationMoves,
          data: {'hiddenType': 5}, // ExploreCellType.boss.index
        );
      case 'npc_radar':
        return NpcEffect(
          typeId: typeId,
          isPositive: false,
          durationType: EffectDurationType.moves,
          remainingMoves: NpcEffectConstants.radarHideDurationMoves,
          data: {'hiddenType': 6}, // ExploreCellType.npc.index
        );
      case 'monster_radar':
        return NpcEffect(
          typeId: typeId,
          isPositive: false,
          durationType: EffectDurationType.moves,
          remainingMoves: NpcEffectConstants.radarHideDurationMoves,
          data: {
            'hiddenType': 4, // ExploreCellType.monster.index
            'range': NpcEffectConstants.monsterRadarRange,
          },
        );
      case 'house_radar':
        return NpcEffect(
          typeId: typeId,
          isPositive: false,
          durationType: EffectDurationType.moves,
          remainingMoves: NpcEffectConstants.radarHideDurationMoves,
          data: {'hiddenType': 3}, // ExploreCellType.house.index
        );
      default:
        return NpcEffect(typeId: typeId, isPositive: false);
    }
  }
}
