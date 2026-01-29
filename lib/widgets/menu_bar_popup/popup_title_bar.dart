import 'package:flutter/material.dart';

import 'menu_bar_popup_constants.dart';
import 'popup_styles.dart';

/// Title bar widget for the popup window
class PopupTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onShowWindow;
  final VoidCallback onHideWindow;
  final VoidCallback onExitApp;

  const PopupTitleBar({
    super.key,
    required this.title,
    required this.onShowWindow,
    required this.onHideWindow,
    required this.onExitApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MenuBarPopupConstants.titleBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: MenuBarPopupConstants.popupPadding,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center: Title (in Stack so it's truly centered)
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: MenuBarPopupConstants.titleFontSize,
                fontWeight: FontWeight.w500,
                color: PopupColors.titleText,
              ),
            ),
          ),
          // Left and Right icons positioned absolutely
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Show/Hide window icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TitleBarIcon(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Show Window',
                    onTap: onShowWindow,
                  ),
                  const SizedBox(width: 4),
                  _TitleBarIcon(
                    icon: Icons.visibility_off_outlined,
                    tooltip: 'Hide Window',
                    onTap: onHideWindow,
                  ),
                ],
              ),
              // Right: Exit icon
              _TitleBarIcon(
                icon: Icons.power_settings_new,
                tooltip: 'Exit Game',
                onTap: onExitApp,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TitleBarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const _TitleBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? PopupColors.iconDestructive
        : PopupColors.iconDefault;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: MenuBarPopupConstants.titleBarIconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}
