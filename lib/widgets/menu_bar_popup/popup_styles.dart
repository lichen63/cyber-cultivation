import 'package:flutter/material.dart';

import 'menu_bar_popup_constants.dart';

/// Common text styles for the menu bar popup
class PopupTextStyles {
  PopupTextStyles._();

  static const TextStyle headerText = TextStyle(
    fontSize: MenuBarPopupConstants.headerFontSize,
    fontWeight: FontWeight.w500,
    color: Color(0xFF8E8E93),
  );

  static const TextStyle processNameText = TextStyle(
    fontSize: MenuBarPopupConstants.processNameFontSize,
    color: Color(0xFF1D1D1F),
  );

  static const TextStyle processValueText = TextStyle(
    fontSize: MenuBarPopupConstants.processNameFontSize,
    color: Color(0xFF8E8E93),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle labelText = TextStyle(
    fontSize: MenuBarPopupConstants.processNameFontSize,
    color: Color(0xFF1D1D1F),
  );

  static const TextStyle valueText = TextStyle(
    fontSize: MenuBarPopupConstants.processNameFontSize,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1D1D1F),
  );

  static const TextStyle emptyText = TextStyle(
    fontSize: 12,
    color: Color(0xFF8E8E93),
  );
}

/// Common colors for the menu bar popup
class PopupColors {
  PopupColors._();

  static const Color background = Color(0xF0F6F6F6);
  static const Color border = Color(0x30000000);
  static const Color separator = Color(0x20000000);
  static const Color titleText = Color(0xFF1D1D1F);
  static const Color iconDefault = Color(0xFF6E6E73);
  static const Color iconDestructive = Color(0xFFFF3B30);
  static const Color shadow = Color(0x40000000);

  // Todo status colors
  static const Color todoDone = Color(0xFF34C759);
  static const Color todoDoing = Color(0xFFFF9500);
  static const Color todoDefault = Color(0xFF8E8E93);
}
