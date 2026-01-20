import 'package:flutter/services.dart';

/// Helper class to set menu bar title with custom font size on macOS.
/// Uses native code to support NSAttributedString with custom font.
class MenuBarHelper {
  static const MethodChannel _channel = MethodChannel('menu_bar_helper');

  /// Set the menu bar title with a custom font size.
  ///
  /// [title] - The text to display in the menu bar
  /// [fontSize] - The font size (default is ~12 for standard menu bar)
  /// [fontWeight] - The font weight: 'light', 'regular', 'medium', 'semibold', 'bold'
  static Future<bool> setAttributedTitle({
    required String title,
    double fontSize = 9.0,
    String fontWeight = 'regular',
  }) async {
    try {
      final result = await _channel.invokeMethod('setAttributedTitle', {
        'title': title,
        'fontSize': fontSize,
        'fontWeight': fontWeight,
      });
      return result == true;
    } catch (e) {
      // Fallback silently if native method fails
      return false;
    }
  }

  /// Set multiple separate menu bar items, each with top and bottom text.
  ///
  /// [items] - List of items, each with 'id', 'top', and 'bottom' keys
  /// [fontSize] - The font size for all items
  /// [fontWeight] - The font weight for all items
  static Future<bool> setMenuBarItems({
    required List<MenuBarItem> items,
    double fontSize = 9.0,
    String fontWeight = 'light',
  }) async {
    try {
      final result = await _channel.invokeMethod('setMenuBarItems', {
        'items': items.map((item) => item.toMap()).toList(),
        'fontSize': fontSize,
        'fontWeight': fontWeight,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all custom menu bar items.
  static Future<bool> clearMenuBarItems() async {
    try {
      final result = await _channel.invokeMethod('clearMenuBarItems');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}

/// Represents a single menu bar item with top and bottom text.
class MenuBarItem {
  final String id;
  final String top;
  final String bottom;
  final String alignment; // 'center', 'left', or 'right'
  final double? fixedWidth; // Fixed width in pixels (null = variable)
  final double? topFontSize; // Font size for top row (null = use default)
  final double? bottomFontSize; // Font size for bottom row (null = use default)

  const MenuBarItem({
    required this.id,
    required this.top,
    required this.bottom,
    this.alignment = 'center',
    this.fixedWidth,
    this.topFontSize,
    this.bottomFontSize,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'top': top,
        'bottom': bottom,
        'alignment': alignment,
        'fixedWidth': fixedWidth ?? -1,
        'topFontSize': topFontSize ?? -1,
        'bottomFontSize': bottomFontSize ?? -1,
      };
}
