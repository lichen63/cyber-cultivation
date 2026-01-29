import 'package:flutter/services.dart';

/// Callback type for menu bar item clicks.
/// Provides itemId, the screen position of the clicked item, and screen height.
typedef MenuBarItemClickCallback =
    void Function(String itemId, Rect screenRect, double screenHeight);

/// Callback type for when a native popup (like calendar) is about to show.
typedef NativePopupShowingCallback = void Function();

/// Helper class to set menu bar title with custom font size on macOS.
/// Uses native code to support NSAttributedString with custom font.
class MenuBarHelper {
  static const MethodChannel _channel = MethodChannel('menu_bar_helper');
  static MenuBarItemClickCallback? _onItemClicked;
  static NativePopupShowingCallback? _onNativePopupShowing;

  /// Initialize the helper and set up method call handlers.
  static void initialize({
    MenuBarItemClickCallback? onItemClicked,
    NativePopupShowingCallback? onNativePopupShowing,
  }) {
    _onItemClicked = onItemClicked;
    _onNativePopupShowing = onNativePopupShowing;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Dispose of the helper and clean up.
  static void dispose() {
    _onItemClicked = null;
    _onNativePopupShowing = null;
    _channel.setMethodCallHandler(null);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMenuBarItemClicked':
        final args = call.arguments as Map<dynamic, dynamic>;
        final itemId = args['itemId'] as String;
        final x = (args['x'] as num).toDouble();
        final y = (args['y'] as num).toDouble();
        final width = (args['width'] as num).toDouble();
        final height = (args['height'] as num).toDouble();
        final screenHeight = (args['screenHeight'] as num).toDouble();
        // Store screenHeight in the Rect's unused property by encoding it
        // We pass it as a 5-element list in a custom way
        _onItemClicked?.call(
          itemId,
          Rect.fromLTWH(x, y, width, height),
          screenHeight,
        );
        return true;
      case 'onNativePopupShowing':
        // Native popup (like calendar) is about to show, hide any Flutter popup
        _onNativePopupShowing?.call();
        return true;
      default:
        return null;
    }
  }

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

  /// Show the main window.
  static Future<bool> showWindow() async {
    try {
      final result = await _channel.invokeMethod('showWindow');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Hide the main window.
  static Future<bool> hideWindow() async {
    try {
      final result = await _channel.invokeMethod('hideWindow');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Exit the application.
  static Future<bool> exitApp() async {
    try {
      final result = await _channel.invokeMethod('exitApp');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Set the theme for native UI components (like calendar popup).
  ///
  /// [isDark] - true for dark theme, false for light theme
  static Future<bool> setTheme({required bool isDark}) async {
    try {
      final result = await _channel.invokeMethod('setTheme', {
        'brightness': isDark ? 'dark' : 'light',
      });
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
