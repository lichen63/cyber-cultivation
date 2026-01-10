import 'package:flutter/material.dart';
import '../constants.dart';

class MouseMonitor extends StatelessWidget {
  final double mouseX;
  final double mouseY;
  final double screenWidth;
  final double screenHeight;
  final double scale;
  final AppThemeColors themeColors;

  const MouseMonitor({
    super.key,
    required this.mouseX,
    required this.mouseY,
    required this.screenWidth,
    required this.screenHeight,
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
          color: themeColors.overlayLight,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the position of the red dot relative to the container
            // Use actual screen dimensions from native side
            final dotX = (mouseX / screenWidth) * constraints.maxWidth;
            final dotY = (mouseY / screenHeight) * constraints.maxHeight;
            
            return Stack(
              children: [
                // Red dot representing mouse position
                Positioned(
                  left: dotX.clamp(0, constraints.maxWidth) - (AppConstants.mouseDotSize / 2),
                  top: dotY.clamp(0, constraints.maxHeight) - (AppConstants.mouseDotSize / 2),
                  child: Container(
                    width: AppConstants.mouseDotSize,
                    height: AppConstants.mouseDotSize,
                    decoration: BoxDecoration(
                      color: themeColors.error,
                      shape: BoxShape.circle,
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
