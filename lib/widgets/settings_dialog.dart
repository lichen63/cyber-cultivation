import 'package:flutter/material.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';

class SettingsDialog extends StatefulWidget {
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final bool isAutoStartEnabled;
  final String? currentLanguage;
  final AppThemeMode themeMode;
  final AppThemeColors themeColors;
  final ValueChanged<bool> onAlwaysOnTopChanged;
  final ValueChanged<bool> onAntiSleepChanged;
  final ValueChanged<bool> onAlwaysShowActionButtonsChanged;
  final ValueChanged<bool> onAutoStartChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  const SettingsDialog({
    super.key,
    required this.isAlwaysOnTop,
    required this.isAntiSleepEnabled,
    required this.isAlwaysShowActionButtons,
    required this.isAutoStartEnabled,
    this.currentLanguage,
    required this.themeMode,
    required this.themeColors,
    required this.onAlwaysOnTopChanged,
    required this.onAntiSleepChanged,
    required this.onAlwaysShowActionButtonsChanged,
    required this.onAutoStartChanged,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _isAlwaysOnTop;
  late bool _isAntiSleepEnabled;
  late bool _isAlwaysShowActionButtons;
  late bool _isAutoStartEnabled;
  late String? _currentLanguage;
  late AppThemeMode _themeMode;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _isAlwaysOnTop = widget.isAlwaysOnTop;
    _isAntiSleepEnabled = widget.isAntiSleepEnabled;
    _isAlwaysShowActionButtons = widget.isAlwaysShowActionButtons;
    _isAutoStartEnabled = widget.isAutoStartEnabled;
    _currentLanguage = widget.currentLanguage;
    _themeMode = widget.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      scrollable: true,
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: _colors.border, width: 2),
      ),
      title: Center(
        child: Text(
          l10n.settingsTitle,
          style: TextStyle(color: _colors.accent),
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
          _buildSwitchTile(
            title: l10n.autoStartText,
            value: _isAutoStartEnabled,
            onChanged: (value) {
              setState(() => _isAutoStartEnabled = value);
              widget.onAutoStartChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildThemeModeSelector(l10n),
          const SizedBox(height: 16),
          _buildLanguageSelector(l10n),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.closeButtonText,
            style: TextStyle(color: _colors.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.themeMode,
          style: TextStyle(color: _colors.primaryText, fontSize: AppConstants.fontSizeLarge),
        ),
        ToggleButtons(
          isSelected: [
            _themeMode == AppThemeMode.light,
            _themeMode == AppThemeMode.dark,
          ],
          onPressed: (index) {
            final newMode = index == 0 ? AppThemeMode.light : AppThemeMode.dark;
            setState(() => _themeMode = newMode);
            widget.onThemeModeChanged(newMode);
          },
          borderRadius: BorderRadius.circular(8),
          selectedColor: _colors.primaryText,
          fillColor: _colors.accent.withValues(alpha: 0.3),
          color: _colors.secondaryText,
          borderColor: _colors.inactive,
          selectedBorderColor: _colors.accent,
          constraints: const BoxConstraints(minWidth: 60, minHeight: 32),
          children: [
            Text(l10n.lightMode),
            Text(l10n.darkMode),
          ],
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
          style: TextStyle(color: _colors.primaryText, fontSize: AppConstants.fontSizeLarge),
        ),
        DropdownButton<String?>(
          value: _currentLanguage,
          dropdownColor: _colors.dialogBackground,
          style: TextStyle(color: _colors.primaryText),
          iconEnabledColor: _colors.accent,
          underline: Container(height: 1, color: _colors.accent),
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
          style: TextStyle(color: _colors.primaryText, fontSize: AppConstants.fontSizeLarge),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _colors.accent,
          activeTrackColor: _colors.accent.withValues(alpha: 0.5),
          inactiveThumbColor: _colors.inactive,
          inactiveTrackColor: _colors.inactive.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
