import 'package:flutter/material.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';

class SettingsDialog extends StatefulWidget {
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final String? currentLanguage;
  final ValueChanged<bool> onAlwaysOnTopChanged;
  final ValueChanged<bool> onAntiSleepChanged;
  final ValueChanged<bool> onAlwaysShowActionButtonsChanged;
  final ValueChanged<String?> onLanguageChanged;

  const SettingsDialog({
    super.key,
    required this.isAlwaysOnTop,
    required this.isAntiSleepEnabled,
    required this.isAlwaysShowActionButtons,
    this.currentLanguage,
    required this.onAlwaysOnTopChanged,
    required this.onAntiSleepChanged,
    required this.onAlwaysShowActionButtonsChanged,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _isAlwaysOnTop;
  late bool _isAntiSleepEnabled;
  late bool _isAlwaysShowActionButtons;
  late String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _isAlwaysOnTop = widget.isAlwaysOnTop;
    _isAntiSleepEnabled = widget.isAntiSleepEnabled;
    _isAlwaysShowActionButtons = widget.isAlwaysShowActionButtons;
    _currentLanguage = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      scrollable: true,
      backgroundColor: AppConstants.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: const BorderSide(color: AppConstants.whiteColor, width: 2),
      ),
      title: Center(
        child: Text(
          l10n.settingsTitle,
          style: const TextStyle(color: AppConstants.cyanAccentColor),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchTile(
            title: l10n.forceForegroundText,
            value: _isAlwaysOnTop,
            onChanged: (value) {
              setState(() => _isAlwaysOnTop = value);
              widget.onAlwaysOnTopChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: l10n.antiSleepText,
            value: _isAntiSleepEnabled,
            onChanged: (value) {
              setState(() => _isAntiSleepEnabled = value);
              widget.onAntiSleepChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: l10n.alwaysShowActionsText,
            value: _isAlwaysShowActionButtons,
            onChanged: (value) {
              setState(() => _isAlwaysShowActionButtons = value);
              widget.onAlwaysShowActionButtonsChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildLanguageSelector(l10n),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.closeButtonText,
            style: const TextStyle(color: AppConstants.cyanAccentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.language,
          style: const TextStyle(color: AppConstants.whiteColor, fontSize: 16),
        ),
        DropdownButton<String?>(
          value: _currentLanguage,
          dropdownColor: AppConstants.dialogBackgroundColor,
          style: const TextStyle(color: AppConstants.whiteColor),
          iconEnabledColor: AppConstants.cyanAccentColor,
          underline: Container(height: 1, color: AppConstants.cyanAccentColor),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.systemLanguage)),
            const DropdownMenuItem(value: 'en', child: Text('English')),
            const DropdownMenuItem(value: 'zh', child: Text('中文')),
          ],
          onChanged: (value) {
            setState(() => _currentLanguage = value);
            widget.onLanguageChanged(value);
            // Rebuild happens due to parent setState usually, but here we update local state too.
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppConstants.whiteColor, fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppConstants.cyanAccentColor,
          activeTrackColor: AppConstants.cyanAccentColor.withValues(alpha: 0.5),
          inactiveThumbColor: AppConstants.greyColor,
          inactiveTrackColor: AppConstants.greyColor.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
