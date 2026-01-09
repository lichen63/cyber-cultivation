import 'package:flutter/material.dart';
import '../constants.dart';

class SettingsDialog extends StatefulWidget {
  final bool isAlwaysOnTop;
  final bool isAntiSleepEnabled;
  final ValueChanged<bool> onAlwaysOnTopChanged;
  final ValueChanged<bool> onAntiSleepChanged;

  const SettingsDialog({
    super.key,
    required this.isAlwaysOnTop,
    required this.isAntiSleepEnabled,
    required this.onAlwaysOnTopChanged,
    required this.onAntiSleepChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _isAlwaysOnTop;
  late bool _isAntiSleepEnabled;

  @override
  void initState() {
    super.initState();
    _isAlwaysOnTop = widget.isAlwaysOnTop;
    _isAntiSleepEnabled = widget.isAntiSleepEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppConstants.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: const BorderSide(color: AppConstants.whiteColor, width: 2),
      ),
      title: const Center(
        child: Text(
          'Settings',
          style: TextStyle(color: AppConstants.cyanAccentColor),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchTile(
            title: AppConstants.forceForegroundText,
            value: _isAlwaysOnTop,
            onChanged: (value) {
              setState(() => _isAlwaysOnTop = value);
              widget.onAlwaysOnTopChanged(value);
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: AppConstants.antiSleepText,
            value: _isAntiSleepEnabled,
            onChanged: (value) {
              setState(() => _isAntiSleepEnabled = value);
              widget.onAntiSleepChanged(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: AppConstants.cyanAccentColor),
          ),
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
          style: const TextStyle(
            color: AppConstants.whiteColor,
            fontSize: 16,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppConstants.cyanAccentColor,
          activeTrackColor: AppConstants.cyanAccentColor.withOpacity(0.5),
          inactiveThumbColor: AppConstants.greyColor,
          inactiveTrackColor: AppConstants.greyColor.withOpacity(0.5),
        ),
      ],
    );
  }
}
