import 'package:flutter/material.dart';
import '../constants.dart';

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double scale;

  const StyledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.scale = 1.0,
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
          color: AppConstants.blackOverlayColor,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius * scale),
          border: Border.all(
            color: AppConstants.whiteColor,
            width: AppConstants.thinBorderWidth * scale,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppConstants.whiteColor,
            fontSize: 14 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
