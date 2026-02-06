import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';

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
        width: 360,
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
}
