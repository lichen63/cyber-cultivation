import 'package:flutter/material.dart';

import '../constants.dart';
import 'styled_button.dart';

/// Data class for action button configuration
class ActionButtonConfig {
  final String text;
  final VoidCallback onPressed;

  const ActionButtonConfig({required this.text, required this.onPressed});
}

/// A row of styled action buttons with consistent spacing
class ActionButtonsRow extends StatelessWidget {
  final List<ActionButtonConfig> buttons;
  final double scale;
  final AppThemeColors themeColors;

  const ActionButtonsRow({
    super.key,
    required this.buttons,
    required this.scale,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          StyledButton(
            text: buttons[i].text,
            onPressed: buttons[i].onPressed,
            scale: scale,
            themeColors: themeColors,
          ),
          if (i < buttons.length - 1) SizedBox(width: 10 * scale),
        ],
      ],
    );
  }
}
