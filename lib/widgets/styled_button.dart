import 'package:flutter/material.dart';
import '../constants.dart';

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double scale;
  final AppThemeColors themeColors;

  const StyledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.scale = 1.0,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.buttonPaddingHorizontal * scale,
          vertical: AppConstants.buttonPaddingVertical * scale,
        ),
        decoration: BoxDecoration(
          color: themeColors.overlay,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius * scale),
          border: Border.all(
            color: themeColors.border,
            width: AppConstants.thinBorderWidth * scale,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: themeColors.primaryText,
            fontSize: AppConstants.fontSizeButton * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
