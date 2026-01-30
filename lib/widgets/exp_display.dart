import 'package:flutter/material.dart';
import '../constants.dart';

class ExpDisplay extends StatelessWidget {
  final int level;
  final double currentExp;
  final double maxExp;
  final double scale;
  final AppThemeColors themeColors;

  const ExpDisplay({
    super.key,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    this.scale = 1.0,
    required this.themeColors,
  });

  /// Formats a large number with K/M/B/T/Q/Qi suffixes for readability.
  String _formatNumber(double value) {
    if (value >= 1e18) {
      return '${(value / 1e18).toStringAsFixed(1)}Qi';
    } else if (value >= 1e15) {
      return '${(value / 1e15).toStringAsFixed(1)}Q';
    } else if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T';
    } else if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e4) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      return value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = maxExp.isInfinite
        ? 1.0
        : (currentExp / maxExp).clamp(0.0, 1.0);
    final String expText = maxExp.isInfinite
        ? '∞ / ∞'
        : '${_formatNumber(currentExp)} / ${_formatNumber(maxExp)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: AppConstants.expBarHeight * scale,
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.expBarPaddingHorizontal * scale,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: themeColors.expBarBackground,
            borderRadius: BorderRadius.circular(
              AppConstants.expBarBorderRadius * scale,
            ),
            border: Border.all(color: themeColors.border, width: 1),
          ),
          child: Text(
            'Lv. $level',
            style: TextStyle(
              color: themeColors.primaryText,
              fontSize: AppConstants.fontSizeLevel * scale,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
        SizedBox(width: AppConstants.expBarSpacing * scale),
        Container(
          width: AppConstants.expBarWidth * scale,
          height: AppConstants.expBarHeight * scale,
          decoration: BoxDecoration(
            border: Border.all(color: themeColors.border, width: 1),
            borderRadius: BorderRadius.circular(
              AppConstants.expBarBorderRadius * scale,
            ),
            color: themeColors.expBarBackground,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  (AppConstants.expBarBorderRadius - 1) * scale,
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeColors.progressBarFill,
                  ),
                  minHeight: AppConstants.expBarHeight * scale,
                ),
              ),
              Center(
                child: Text(
                  expText,
                  style: TextStyle(
                    color: themeColors.expBarText,
                    fontSize: AppConstants.fontSizeExpProgress * scale,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: themeColors.expBarTextShadow,
                        offset: const Offset(1, 1),
                      ),
                      Shadow(
                        blurRadius: 2,
                        color: themeColors.expBarTextShadow,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
