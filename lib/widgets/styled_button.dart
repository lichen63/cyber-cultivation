import 'package:flutter/material.dart';
import '../constants.dart';

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const StyledButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.buttonPaddingHorizontal,
          vertical: AppConstants.buttonPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: AppConstants.blackOverlayColor,
          borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
          border: Border.all(
            color: AppConstants.whiteColor,
            width: AppConstants.thinBorderWidth,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppConstants.whiteColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
