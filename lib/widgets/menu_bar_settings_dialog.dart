import 'package:flutter/material.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/menu_bar_settings.dart';

/// Dialog for configuring menu bar info display settings
class MenuBarSettingsDialog extends StatefulWidget {
  final MenuBarSettings settings;
  final AppThemeColors themeColors;
  final ValueChanged<MenuBarSettings> onSettingsChanged;

  const MenuBarSettingsDialog({
    super.key,
    required this.settings,
    required this.themeColors,
    required this.onSettingsChanged,
  });

  @override
  State<MenuBarSettingsDialog> createState() => _MenuBarSettingsDialogState();
}

class _MenuBarSettingsDialogState extends State<MenuBarSettingsDialog> {
  late MenuBarSettings _settings;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(MenuBarSettings newSettings) {
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
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
          l10n.menuBarSettingsTitle,
          style: TextStyle(color: _colors.accent),
        ),
      ),
      content: SizedBox(
        width: MenuBarConstants.settingsDialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tray icon toggle
            _buildSwitchTile(
              title: l10n.menuBarShowTrayIcon,
              value: _settings.showTrayIcon,
              onChanged: (value) {
                _updateSettings(_settings.copyWith(showTrayIcon: value));
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // App Info section
            _buildSectionHeader(l10n.menuBarSectionApp),
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: l10n.menuBarInfoFocus,
              type: MenuBarInfoType.focus,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoTodo,
              type: MenuBarInfoType.todo,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoLevelExp,
              type: MenuBarInfoType.levelExp,
            ),

            const SizedBox(height: 16),

            // System Stats section
            _buildSectionHeader(l10n.menuBarSectionSystem),
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: l10n.menuBarInfoCpu,
              type: MenuBarInfoType.cpu,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoGpu,
              type: MenuBarInfoType.gpu,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoRam,
              type: MenuBarInfoType.ram,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoDisk,
              type: MenuBarInfoType.disk,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoNetwork,
              type: MenuBarInfoType.network,
            ),

            const SizedBox(height: 16),

            // Input Tracking section
            _buildSectionHeader(l10n.menuBarSectionTracking),
            const SizedBox(height: 8),
            _buildCheckboxTile(
              title: l10n.menuBarInfoKeyboard,
              type: MenuBarInfoType.keyboard,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoMouse,
              type: MenuBarInfoType.mouse,
            ),
            _buildCheckboxTile(
              title: l10n.menuBarInfoSystemTime,
              type: MenuBarInfoType.systemTime,
            ),
          ],
        ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _colors.accent,
        fontSize: AppConstants.fontSizeDialogContent,
        fontWeight: FontWeight.bold,
      ),
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
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
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

  Widget _buildCheckboxTile({
    required String title,
    required MenuBarInfoType type,
  }) {
    final isEnabled = _settings.isEnabled(type);
    return InkWell(
      onTap: () => _updateSettings(_settings.toggleType(type)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isEnabled,
                onChanged: (_) => _updateSettings(_settings.toggleType(type)),
                activeColor: _colors.accent,
                checkColor: _colors.primaryText,
                side: BorderSide(color: _colors.inactive),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: AppConstants.fontSizeDialogContent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
