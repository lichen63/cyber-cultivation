import 'package:flutter/material.dart';
import '../constants.dart';

class KeyboardMonitor extends StatelessWidget {
  final String currentKey;
  final double scale;
  final AppThemeColors themeColors;

  const KeyboardMonitor({
    super.key,
    required this.currentKey,
    required this.scale,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topLeft,
      child: Container(
        width: AppConstants.monitorWidgetSize,
        height: AppConstants.monitorWidgetSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: themeColors.overlay,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          border: Border.all(
            color: themeColors.border,
            width: AppConstants.thinBorderWidth,
          ),
        ),
        child: Text(
          currentKey,
          style: TextStyle(
            color: themeColors.primaryText,
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
