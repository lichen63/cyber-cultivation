import 'package:flutter/material.dart';

import 'menu_bar_popup_constants.dart';
import 'popup_styles.dart';

/// Common reusable widgets for popup content
class PopupWidgets {
  PopupWidgets._();

  /// Build a simple info row with label and value
  static Widget buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PopupTextStyles.labelText),
        Text(value, style: PopupTextStyles.valueText),
      ],
    );
  }

  /// Build a loading indicator
  static Widget buildLoading() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: MenuBarPopupConstants.contentMinHeight,
      ),
      padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// Build an empty state message
  static Widget buildEmpty(String message) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: MenuBarPopupConstants.contentMinHeight,
      ),
      padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
      child: Center(child: Text(message, style: PopupTextStyles.emptyText)),
    );
  }

  /// Build a standard content container
  static Widget buildContentContainer({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: MenuBarPopupConstants.contentMinHeight,
      ),
      padding: const EdgeInsets.all(MenuBarPopupConstants.popupPadding),
      child: child,
    );
  }
}
