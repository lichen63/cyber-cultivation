import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';

/// Constants for menu bar popup
class MenuBarPopupConstants {
  static const double popupWidth = 160.0;
  static const double popupItemHeight = 22.0;
  static const double popupBorderRadius = 6.0;
  static const double popupPadding = 5.0;
  static const double popupItemPadding = 10.0;
  static const double popupIconSize = 14.0;
  static const double popupFontSize = 13.0;
  static const double popupSeparatorHeight = 1.0;
  static const double popupSeparatorMargin = 4.0;

  /// Calculate total popup height based on content
  /// Adding extra padding for border and safety margin
  static double get popupHeight {
    // 3 menu items + 1 separator + padding + border + safety margin
    return (popupItemHeight * 3) +
        popupSeparatorHeight +
        (popupSeparatorMargin * 2) +
        (popupPadding * 2) +
        4.0; // Safety margin for border and rounding
  }
}

/// A standalone window for the menu bar popup.
/// This is used with desktop_multi_window package.
class MenuBarPopupWindow extends StatefulWidget {
  final WindowController windowController;
  final Map<String, dynamic> args;

  const MenuBarPopupWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<MenuBarPopupWindow> createState() => _MenuBarPopupWindowState();
}

class _MenuBarPopupWindowState extends State<MenuBarPopupWindow>
    with WindowListener {
  late final AppThemeColors _themeColors;
  late final Brightness _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.args['brightness'] == 'dark'
        ? Brightness.dark
        : Brightness.light;
    _themeColors = _brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
    _initWindow();
  }

  Future<void> _initWindow() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    // Get position from args
    final x = (widget.args['x'] as num?)?.toDouble() ?? 0;
    final y = (widget.args['y'] as num?)?.toDouble() ?? 0;

    final windowOptions = WindowOptions(
      size: Size(
        MenuBarPopupConstants.popupWidth,
        MenuBarPopupConstants.popupHeight,
      ),
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPosition(Offset(x, y));
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() {
    // Close popup when it loses focus
    _closePopup();
  }

  Future<void> _closePopup() async {
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: widget.args['locale'] != null
          ? Locale(widget.args['locale'] as String)
          : null,
      theme: ThemeData(
        fontFamily: 'NotoSansSC',
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColors.progressBarFill,
          brightness: _brightness,
        ),
        canvasColor: Colors.transparent,
      ),
      home: _MenuBarPopupContent(
        themeColors: _themeColors,
        onClose: _closePopup,
      ),
    );
  }
}

/// The actual content of the popup window
class _MenuBarPopupContent extends StatelessWidget {
  final AppThemeColors themeColors;
  final VoidCallback onClose;

  const _MenuBarPopupContent({
    required this.themeColors,
    required this.onClose,
  });

  /// Send a command to the main window via WindowController
  /// The main window has windowId "0" (or we can get it from WindowController.getAll())
  Future<void> _sendCommandToMainWindow(String command) async {
    try {
      // Get all window controllers and find the main window (first one, or id "0")
      final controllers = await WindowController.getAll();
      if (controllers.isNotEmpty) {
        // The main window is typically the first one created
        final mainWindowController = controllers.first;
        await mainWindowController.invokeMethod(command);
      }
    } catch (e) {
      // Ignore errors - the command might fail if window is already closed
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              MenuBarPopupConstants.popupBorderRadius,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: MenuBarPopupConstants.popupWidth,
                decoration: BoxDecoration(
                  // Native macOS menu uses a light translucent background
                  color: const Color(0xF0F6F6F6),
                  borderRadius: BorderRadius.circular(
                    MenuBarPopupConstants.popupBorderRadius,
                  ),
                  border: Border.all(
                    color: const Color(0x30000000),
                    width: 0.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: MenuBarPopupConstants.popupPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.open_in_new,
                      label: l10n.menuBarShowWindow,
                      onTap: () {
                        _sendCommandToMainWindow('showWindow');
                        onClose();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.visibility_off_outlined,
                      label: l10n.menuBarHideWindow,
                      onTap: () {
                        _sendCommandToMainWindow('hideWindow');
                        onClose();
                      },
                    ),
                    _buildSeparator(),
                    _buildMenuItem(
                      icon: Icons.exit_to_app,
                      label: l10n.menuBarExit,
                      onTap: () {
                        _sendCommandToMainWindow('exitApp');
                        onClose();
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    // Native macOS menu uses black text, red for destructive actions
    final color = isDestructive
        ? const Color(0xFFFF3B30)
        : const Color(0xFF1D1D1F);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF007AFF), // macOS selection blue
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          child: Container(
            height: MenuBarPopupConstants.popupItemHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: MenuBarPopupConstants.popupItemPadding,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: MenuBarPopupConstants.popupIconSize,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: MenuBarPopupConstants.popupFontSize,
                      color: color,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: MenuBarPopupConstants.popupSeparatorHeight,
      margin: const EdgeInsets.symmetric(
        vertical: MenuBarPopupConstants.popupSeparatorMargin,
        horizontal: MenuBarPopupConstants.popupItemPadding,
      ),
      color: const Color(0x20000000), // Light gray separator like macOS
    );
  }
}
