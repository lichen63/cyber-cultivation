import 'package:flutter/material.dart';
import '../constants.dart';

/// Widget that displays mouse position and click feedback.
class MouseMonitor extends StatelessWidget {
  final double mouseX;
  final double mouseY;
  final double screenWidth;
  final double screenHeight;
  final bool isClicking;
  final double scale;
  final AppThemeColors themeColors;

  const MouseMonitor({
    super.key,
    required this.mouseX,
    required this.mouseY,
    required this.screenWidth,
    required this.screenHeight,
    required this.isClicking,
    required this.scale,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topRight,
      child: Container(
        width: AppConstants.monitorWidgetSize,
        height: AppConstants.monitorWidgetSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: themeColors.border,
            width: AppConstants.thinBorderWidth,
          ),
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          color: themeColors.overlay,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the position of the red dot relative to the container
            // Use actual screen dimensions from native side
            final dotX = (mouseX / screenWidth) * constraints.maxWidth;
            final dotY = (mouseY / screenHeight) * constraints.maxHeight;

            // Clamp the dot position to keep it fully within bounds
            final halfDot = AppConstants.mouseDotSize / 2;
            final clampedLeft = (dotX - halfDot).clamp(
              0.0,
              constraints.maxWidth - AppConstants.mouseDotSize,
            );
            final clampedTop = (dotY - halfDot).clamp(
              0.0,
              constraints.maxHeight - AppConstants.mouseDotSize,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Red dot representing mouse position with blink on click
                Positioned(
                  left: clampedLeft,
                  top: clampedTop,
                  child: AnimatedScale(
                    duration: const Duration(
                      milliseconds: AppConstants.mouseClickBlinkDurationMs,
                    ),
                    scale: isClicking ? 1.8 : 1.0,
                    child: Container(
                      width: AppConstants.mouseDotSize,
                      height: AppConstants.mouseDotSize,
                      decoration: BoxDecoration(
                        color: isClicking
                            ? themeColors.accent
                            : themeColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
