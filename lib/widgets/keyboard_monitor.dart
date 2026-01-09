import 'package:flutter/material.dart';
import '../constants.dart';

class KeyboardMonitor extends StatelessWidget {
  final String currentKey;
  final double scale;

  const KeyboardMonitor({
    super.key,
    required this.currentKey,
    required this.scale,
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
          color: AppConstants.blackOverlayColor,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          border: Border.all(
            color: AppConstants.whiteColor,
            width: AppConstants.thinBorderWidth,
          ),
        ),
        child: Text(
          currentKey,
          style: const TextStyle(
            color: AppConstants.whiteColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
