import 'package:flutter/material.dart';
import '../constants.dart';

class ExpDisplay extends StatelessWidget {
  final int level;
  final double currentExp;
  final double maxExp;
  final double scale;

  const ExpDisplay({
    super.key,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    this.scale = 1.0,
  });

  /// Formats a large number with K/M/B/T suffixes for readability.
  String _formatNumber(double value) {
    if (value >= 1e12) {
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
    final double progress = maxExp.isInfinite ? 1.0 : (currentExp / maxExp).clamp(0.0, 1.0);
    final String expText = maxExp.isInfinite 
        ? '∞ / ∞' 
        : '${_formatNumber(currentExp)} / ${_formatNumber(maxExp)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Lv. $level',
          style: TextStyle(
            color: AppConstants.whiteColor,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * scale),
        Container(
          width: 200 * scale,
          height: 20 * scale,
          decoration: BoxDecoration(
            border: Border.all(color: AppConstants.whiteColor, width: 1),
            borderRadius: BorderRadius.circular(10 * scale),
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9 * scale),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primarySeedColor,
                  ),
                  minHeight: 20 * scale,
                ),
              ),
              Center(
                child: Text(
                  expText,
                  style: TextStyle(
                    color: AppConstants.whiteColor,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black,
                        offset: Offset(1, 1),
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
