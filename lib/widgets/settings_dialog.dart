import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';
import '../models/menu_bar_settings.dart';
import '../services/menu_bar_info_service.dart';
import 'menu_bar_settings_dialog.dart';

class SettingsDialog extends StatefulWidget {
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final bool isAlwaysShowActionButtons;
  final bool isAutoStartEnabled;
  final bool isShowSystemStats;
  final bool isShowKeyboardTrack;
  final bool isShowMouseTrack;
  final int systemStatsRefreshSeconds;
  final String? currentLanguage;
  final AppThemeMode themeMode;
  final AppThemeColors themeColors;
  final MenuBarSettings menuBarSettings;
  final MenuBarInfoService? menuBarInfoService;
  final ValueChanged<bool> onAlwaysOnTopChanged;
  final ValueChanged<bool> onAntiSleepChanged;
  final ValueChanged<bool> onAlwaysShowActionButtonsChanged;
  final ValueChanged<bool> onAutoStartChanged;
  final ValueChanged<bool> onShowSystemStatsChanged;
  final ValueChanged<bool> onShowKeyboardTrackChanged;
  final ValueChanged<bool> onShowMouseTrackChanged;
  final ValueChanged<int> onSystemStatsRefreshSecondsChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<AppThemeMode> onThemeModeChanged;
  final ValueChanged<MenuBarSettings> onMenuBarSettingsChanged;
  final VoidCallback? onResetLevelExp;

  const SettingsDialog({
    super.key,
    required this.isAlwaysOnTop,
    required this.isAntiSleepEnabled,
    required this.isAlwaysShowActionButtons,
    required this.isAutoStartEnabled,
    required this.isShowSystemStats,
    required this.isShowKeyboardTrack,
    required this.isShowMouseTrack,
    required this.systemStatsRefreshSeconds,
    this.currentLanguage,
    required this.themeMode,
    required this.themeColors,
    required this.menuBarSettings,
    this.menuBarInfoService,
    required this.onAlwaysOnTopChanged,
    required this.onAntiSleepChanged,
    required this.onAlwaysShowActionButtonsChanged,
    required this.onAutoStartChanged,
    required this.onShowSystemStatsChanged,
    required this.onShowKeyboardTrackChanged,
    required this.onShowMouseTrackChanged,
    required this.onSystemStatsRefreshSecondsChanged,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
    required this.onMenuBarSettingsChanged,
    this.onResetLevelExp,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _isAlwaysOnTop;
  late bool _isAntiSleepEnabled;
  late bool _isAlwaysShowActionButtons;
  late bool _isAutoStartEnabled;
  late bool _isShowSystemStats;
  late bool _isShowKeyboardTrack;
  late bool _isShowMouseTrack;
  late int _systemStatsRefreshSeconds;
  late String? _currentLanguage;
  late AppThemeMode _themeMode;
  late MenuBarSettings _menuBarSettings;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _isAlwaysOnTop = widget.isAlwaysOnTop;
    _isAntiSleepEnabled = widget.isAntiSleepEnabled;
    _isAlwaysShowActionButtons = widget.isAlwaysShowActionButtons;
    _isAutoStartEnabled = widget.isAutoStartEnabled;
    _isShowSystemStats = widget.isShowSystemStats;
    _isShowKeyboardTrack = widget.isShowKeyboardTrack;
    _isShowMouseTrack = widget.isShowMouseTrack;
    _systemStatsRefreshSeconds = widget.systemStatsRefreshSeconds;
    _currentLanguage = widget.currentLanguage;
    _themeMode = widget.themeMode;
    _menuBarSettings = widget.menuBarSettings;
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
            title: l10n.autoStartText,
            value: _isAutoStartEnabled,
            onChanged: (value) {
              setState(() => _isAutoStartEnabled = value);
              widget.onAutoStartChanged(value);
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
            title: l10n.showSystemStatsText,
            value: _isShowSystemStats,
            onChanged: (value) {
              setState(() => _isShowSystemStats = value);
              widget.onShowSystemStatsChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: l10n.showKeyboardTrackText,
            value: _isShowKeyboardTrack,
            onChanged: (value) {
              setState(() => _isShowKeyboardTrack = value);
              widget.onShowKeyboardTrackChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: l10n.showMouseTrackText,
            value: _isShowMouseTrack,
            onChanged: (value) {
              setState(() => _isShowMouseTrack = value);
              widget.onShowMouseTrackChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildRefreshIntervalSelector(l10n),
          const SizedBox(height: 16),
          _buildThemeModeSelector(l10n),
          const SizedBox(height: 16),
          _buildLanguageSelector(l10n),
          const SizedBox(height: 16),
          _buildMenuBarSettingsButton(l10n),
          const SizedBox(height: 16),
          _buildOpenSaveFolderButton(l10n),
          if (widget.onResetLevelExp != null) ...[
            const SizedBox(height: 24),
            _buildResetLevelExpButton(l10n),
          ],
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

  Widget _buildRefreshIntervalSelector(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.systemStatsRefreshText,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: _colors.accent, size: 20),
              onPressed:
                  _systemStatsRefreshSeconds >
                      AppConstants.minSystemStatsRefreshSeconds
                  ? () {
                      setState(() => _systemStatsRefreshSeconds--);
                      widget.onSystemStatsRefreshSecondsChanged(
                        _systemStatsRefreshSeconds,
                      );
                    }
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                l10n.systemStatsRefreshSeconds(_systemStatsRefreshSeconds),
                style: TextStyle(
                  color: _colors.primaryText,
                  fontSize: AppConstants.fontSizeDialogContent,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: _colors.accent, size: 20),
              onPressed:
                  _systemStatsRefreshSeconds <
                      AppConstants.maxSystemStatsRefreshSeconds
                  ? () {
                      setState(() => _systemStatsRefreshSeconds++);
                      widget.onSystemStatsRefreshSecondsChanged(
                        _systemStatsRefreshSeconds,
                      );
                    }
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
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
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
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
          children: [Text(l10n.lightMode), Text(l10n.darkMode)],
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
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
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

  Widget _buildMenuBarSettingsButton(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.menuBarSettingsTitle,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
        TextButton(
          onPressed: _showMenuBarSettingsDialog,
          style: TextButton.styleFrom(
            foregroundColor: _colors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings, size: 16, color: _colors.accent),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: _colors.accent),
            ],
          ),
        ),
      ],
    );
  }

  void _showMenuBarSettingsDialog() {
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => MenuBarSettingsDialog(
        settings: _menuBarSettings,
        themeColors: _colors,
        menuBarInfoService: widget.menuBarInfoService,
        onSettingsChanged: (newSettings) {
          setState(() => _menuBarSettings = newSettings);
          widget.onMenuBarSettingsChanged(newSettings);
        },
      ),
    );
  }

  Widget _buildOpenSaveFolderButton(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.openSaveFolderText,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
        TextButton(
          onPressed: _openSaveFolder,
          style: TextButton.styleFrom(
            foregroundColor: _colors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 16, color: _colors.accent),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: _colors.accent),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openSaveFolder() async {
    try {
      String path;
      if (kDebugMode) {
        // In debug mode, open current working directory
        path = Directory.current.path;
      } else {
        // In release mode, open Application Support directory
        final directory = await getApplicationSupportDirectory();
        path = directory.path;
      }

      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      debugPrint('Error opening save folder: $e');
    }
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

  Widget _buildResetLevelExpButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showResetLevelExpConfirmation,
        style: OutlinedButton.styleFrom(
          foregroundColor: _colors.error,
          side: BorderSide(color: _colors.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(l10n.resetLevelExpText),
      ),
    );
  }

  void _showResetLevelExpConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => AlertDialog(
        backgroundColor: _colors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          side: BorderSide(color: _colors.border, width: 2),
        ),
        title: Text(
          l10n.resetLevelExpConfirmTitle,
          style: TextStyle(color: _colors.error),
        ),
        content: Text(
          l10n.resetLevelExpConfirmContent,
          style: TextStyle(color: _colors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancelButtonText,
              style: TextStyle(color: _colors.inactive),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              widget.onResetLevelExp?.call();
            },
            child: Text(
              l10n.resetButtonText,
              style: TextStyle(color: _colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
