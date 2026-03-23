import 'package:flutter/material.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';

import '../constants.dart';
import '../services/key_shield_service.dart';

/// Dialog for selecting running apps to add to Key Shield protected list
class KeyShieldAppPicker extends StatefulWidget {
  final AppThemeColors themeColors;
  final KeyShieldService keyShieldService;
  final Set<String> existingBundleIds;
  final ValueChanged<List<RunningApp>> onAppsSelected;

  const KeyShieldAppPicker({
    super.key,
    required this.themeColors,
    required this.keyShieldService,
    required this.existingBundleIds,
    required this.onAppsSelected,
  });

  @override
  State<KeyShieldAppPicker> createState() => _KeyShieldAppPickerState();
}

class _KeyShieldAppPickerState extends State<KeyShieldAppPicker> {
  List<RunningApp> _runningApps = [];
  final Set<String> _selectedBundleIds = {};
  String _filterText = '';
  bool _isLoading = true;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _loadRunningApps();
  }

  Future<void> _loadRunningApps() async {
    final apps = await widget.keyShieldService.getRunningApps();
    if (mounted) {
      setState(() {
        _runningApps = apps;
        _isLoading = false;
      });
    }
  }

  List<RunningApp> get _filteredApps {
    if (_filterText.isEmpty) return _runningApps;
    final lower = _filterText.toLowerCase();
    return _runningApps.where((app) {
      return app.name.toLowerCase().contains(lower) ||
          app.bundleId.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          KeyShieldConstants.dialogBorderRadius,
        ),
        side: BorderSide(color: _colors.border, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: KeyShieldConstants.appPickerMaxWidth,
          maxHeight: KeyShieldConstants.appPickerMaxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KeyShieldConstants.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 12),
              _buildSearchField(l10n),
              const SizedBox(height: 12),
              Flexible(child: _buildAppList(l10n)),
              const SizedBox(height: 12),
              _buildActions(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.keyShieldSelectRunningApp,
          style: TextStyle(
            color: _colors.accent,
            fontSize: AppConstants.fontSizeDialogTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: _colors.inactive, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return TextField(
      style: TextStyle(
        color: _colors.primaryText,
        fontSize: AppConstants.fontSizeDialogContent,
      ),
      decoration: InputDecoration(
        hintText: l10n.keyShieldFilterApps,
        hintStyle: TextStyle(
          color: _colors.secondaryText,
          fontSize: AppConstants.fontSizeDialogContent,
        ),
        prefixIcon: Icon(Icons.search, size: 18, color: _colors.inactive),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            KeyShieldConstants.itemBorderRadius,
          ),
          borderSide: BorderSide(color: _colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            KeyShieldConstants.itemBorderRadius,
          ),
          borderSide: BorderSide(color: _colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            KeyShieldConstants.itemBorderRadius,
          ),
          borderSide: BorderSide(color: _colors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      onChanged: (value) => setState(() => _filterText = value),
    );
  }

  Widget _buildAppList(AppLocalizations l10n) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _colors.accent));
    }

    final apps = _filteredApps;
    if (apps.isEmpty) {
      return Center(
        child: Text(
          l10n.keyShieldNoRunningApps,
          style: TextStyle(color: _colors.secondaryText),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: apps.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final app = apps[index];
        final isAlreadyAdded = widget.existingBundleIds.contains(app.bundleId);
        final isSelected = _selectedBundleIds.contains(app.bundleId);

        return GestureDetector(
          onTap: isAlreadyAdded
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedBundleIds.remove(app.bundleId);
                    } else {
                      _selectedBundleIds.add(app.bundleId);
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _colors.accent.withValues(alpha: 0.1)
                  : _colors.overlayLight,
              border: Border.all(
                color: isSelected ? _colors.accent : _colors.border,
              ),
              borderRadius: BorderRadius.circular(
                KeyShieldConstants.itemBorderRadius,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAlreadyAdded
                      ? Icons.check_circle
                      : isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: isAlreadyAdded
                      ? _colors.inactive
                      : isSelected
                      ? _colors.accent
                      : _colors.inactive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: TextStyle(
                          color: isAlreadyAdded
                              ? _colors.inactive
                              : _colors.primaryText,
                          fontSize: AppConstants.fontSizeDialogContent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        app.bundleId,
                        style: TextStyle(
                          color: _colors.secondaryText,
                          fontSize: AppConstants.fontSizeDialogHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAlreadyAdded)
                  Text(
                    l10n.keyShieldAlreadyAdded,
                    style: TextStyle(
                      color: _colors.inactive,
                      fontSize: AppConstants.fontSizeDialogHint,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _selectedBundleIds.isEmpty
              ? null
              : () {
                  final selectedApps = _runningApps
                      .where((app) => _selectedBundleIds.contains(app.bundleId))
                      .toList();
                  widget.onAppsSelected(selectedApps);
                  Navigator.of(context).pop();
                },
          child: Text(
            l10n.keyShieldAddSelected,
            style: TextStyle(
              color: _selectedBundleIds.isEmpty
                  ? _colors.inactive
                  : _colors.accent,
              fontSize: AppConstants.fontSizeDialogContent,
            ),
          ),
        ),
      ],
    );
  }
}
