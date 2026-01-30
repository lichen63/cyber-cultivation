import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';

/// Dialog for debugging/customizing the current level and exp.
/// Only shown in debug mode.
class DebugLevelExpDialog extends StatefulWidget {
  final int currentLevel;
  final double currentExp;
  final AppThemeColors themeColors;
  final void Function(int level, double exp) onApply;

  const DebugLevelExpDialog({
    super.key,
    required this.currentLevel,
    required this.currentExp,
    required this.themeColors,
    required this.onApply,
  });

  @override
  State<DebugLevelExpDialog> createState() => _DebugLevelExpDialogState();
}

class _DebugLevelExpDialogState extends State<DebugLevelExpDialog> {
  late TextEditingController _levelController;
  late TextEditingController _expController;
  late int _level;
  late double _maxExp;
  double _currentExp = 0;

  AppThemeColors get _colors => widget.themeColors;

  /// Compare two non-negative integer strings.
  /// Returns true if a < b.
  bool _isStringNumberLessThan(String a, String b) {
    // Remove leading zeros
    a = a.replaceFirst(RegExp(r'^0+'), '');
    b = b.replaceFirst(RegExp(r'^0+'), '');
    if (a.isEmpty) a = '0';
    if (b.isEmpty) b = '0';

    // Different lengths - shorter number is smaller
    if (a.length != b.length) {
      return a.length < b.length;
    }
    // Same length - compare lexicographically
    return a.compareTo(b) < 0;
  }

  /// Check if the current input is valid for applying
  bool get _isValid {
    final level = int.tryParse(_levelController.text);
    if (level == null || level < 1 || level > AppConstants.maxLevel) {
      return false;
    }
    if (_currentExp < 0) {
      return false;
    }
    // At max level, any exp is valid
    if (level >= AppConstants.maxLevel) {
      return true;
    }

    // For large numbers, compare as strings to avoid floating-point precision issues
    final expStr = _expController.text.trim();
    if (expStr.isEmpty) return false;

    // Get integer part of the exp input
    final expIntStr = expStr.contains('.') ? expStr.split('.')[0] : expStr;

    // Get max exp as integer string
    final maxExpIntStr = _maxExp.toStringAsFixed(0);

    // If exp has decimal part, it's valid as long as integer part is less than max
    // If exp has no decimal, it must be strictly less than max
    if (expStr.contains('.')) {
      // Has decimal - integer part must be <= max - 1, or if equal, the decimal makes it valid
      return _isStringNumberLessThan(expIntStr, maxExpIntStr) ||
          expIntStr == maxExpIntStr; // e.g., 100.5 < 101 is valid
    } else {
      // No decimal - must be strictly less than max
      return _isStringNumberLessThan(expIntStr, maxExpIntStr);
    }
  }

  @override
  void initState() {
    super.initState();
    _level = widget.currentLevel;
    _maxExp = _calculateMaxExp(_level);
    _currentExp = widget.currentExp;
    _levelController = TextEditingController(text: _level.toString());
    _expController = TextEditingController(
      text: widget.currentExp.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _levelController.dispose();
    _expController.dispose();
    super.dispose();
  }

  /// Calculate max exp needed for a given level
  double _calculateMaxExp(int level) {
    if (level >= AppConstants.maxLevel) {
      return double.infinity;
    }
    return AppConstants.initialMaxExp *
        pow(AppConstants.expGrowthFactor, level - 1);
  }

  void _onLevelChanged(String value) {
    final newLevel = int.tryParse(value);
    if (newLevel != null &&
        newLevel >= 1 &&
        newLevel <= AppConstants.maxLevel) {
      setState(() {
        _level = newLevel;
        _maxExp = _calculateMaxExp(newLevel);
      });
    } else {
      // Still trigger rebuild to update button state
      setState(() {});
    }
  }

  void _apply() {
    if (!_isValid) return;
    widget.onApply(_level, _currentExp);
    Navigator.of(context).pop();
  }

  void _onExpChanged(String value) {
    final exp = double.tryParse(value);
    setState(() {
      _currentExp = exp ?? 0;
    });
  }

  String _formatMaxExp(double value) {
    if (value == double.infinity) {
      return '∞';
    }
    // Show full number for debug purposes
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        side: BorderSide(color: _colors.border, width: 2),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.bug_report, color: _colors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.debugSetLevelExpTitle,
                  style: TextStyle(
                    color: _colors.primaryText,
                    fontSize: AppConstants.fontSizeDialogTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Level input
            Text(
              l10n.debugLevelLabel,
              style: TextStyle(
                color: _colors.secondaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _levelController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                  borderSide: BorderSide(color: _colors.accent, width: 2),
                ),
                hintText: '1 - ${AppConstants.maxLevel}',
                hintStyle: TextStyle(color: _colors.inactive),
              ),
              onChanged: _onLevelChanged,
            ),
            const SizedBox(height: 16),

            // Current EXP input
            Text(
              l10n.debugExpLabel,
              style: TextStyle(
                color: _colors.secondaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _expController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                  borderSide: BorderSide(color: _colors.accent, width: 2),
                ),
                hintText: '0',
                hintStyle: TextStyle(color: _colors.inactive),
              ),
              onChanged: _onExpChanged,
            ),
            const SizedBox(height: 16),

            // Max EXP display (read-only, updates based on level)
            Text(
              l10n.debugMaxExpLabel,
              style: TextStyle(
                color: _colors.secondaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SelectableText(
                _formatMaxExp(_maxExp),
                style: TextStyle(
                  color: _colors.accent,
                  fontSize: AppConstants.fontSizeDialogContent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.cancelButtonText,
                    style: TextStyle(color: _colors.secondaryText),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValid ? _apply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid
                        ? _colors.accent
                        : _colors.inactive,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.debugApplyButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
