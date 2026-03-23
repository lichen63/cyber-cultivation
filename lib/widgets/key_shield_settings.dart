import 'package:flutter/material.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';

import '../constants.dart';
import '../models/key_shield_config.dart';
import '../services/key_shield_service.dart';
import 'key_shield_app_picker.dart';

/// Full Key Shield configuration dialog
class KeyShieldSettingsDialog extends StatefulWidget {
  final KeyShieldConfig config;
  final AppThemeColors themeColors;
  final ValueChanged<KeyShieldConfig> onConfigChanged;

  const KeyShieldSettingsDialog({
    super.key,
    required this.config,
    required this.themeColors,
    required this.onConfigChanged,
  });

  @override
  State<KeyShieldSettingsDialog> createState() =>
      _KeyShieldSettingsDialogState();
}

class _KeyShieldSettingsDialogState extends State<KeyShieldSettingsDialog> {
  late KeyShieldConfig _config;
  final KeyShieldService _keyShieldService = KeyShieldService();
  bool _isAddingCombo = false;
  String _newComboModifier = 'command';
  String _newComboKey = 'w';

  static const List<String> _availableModifiers = [
    'command',
    'option',
    'control',
  ];

  static const List<String> _availableKeys = [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'tab',
    'space',
    'enter',
    'esc',
    'backspace',
    'delete',
    'left',
    'right',
    'up',
    'down',
    'f1',
    'f2',
    'f3',
    'f4',
    'f5',
    'f6',
    'f7',
    'f8',
    'f9',
    'f10',
    'f11',
    'f12',
  ];

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _updateConfig(KeyShieldConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged(newConfig);
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
          maxWidth: KeyShieldConstants.dialogMaxWidth,
          maxHeight: KeyShieldConstants.dialogMaxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KeyShieldConstants.dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: KeyShieldConstants.sectionSpacing),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlobalDefaultsSection(l10n),
                      const SizedBox(height: KeyShieldConstants.sectionSpacing),
                      _buildAllowedCombosSection(l10n),
                      const SizedBox(height: KeyShieldConstants.sectionSpacing),
                      _buildFeedbackSection(l10n),
                      const SizedBox(height: KeyShieldConstants.sectionSpacing),
                      _buildProtectedAppsSection(l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.keyShieldTitle,
          style: TextStyle(
            color: _colors.accent,
            fontSize: AppConstants.fontSizeDialogTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Switch(
          value: _config.isEnabled,
          onChanged: (value) {
            _updateConfig(_config.copyWith(isEnabled: value));
          },
          activeThumbColor: _colors.accent,
          activeTrackColor: _colors.accent.withValues(alpha: 0.5),
          inactiveThumbColor: _colors.inactive,
          inactiveTrackColor: _colors.inactive.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: _colors.inactive, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // MARK: - Global Defaults

  Widget _buildGlobalDefaultsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keyShieldBlockedModifiers,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: KeyShieldConstants.chipSpacing,
          children: _availableModifiers.map((modifier) {
            final isSelected = _config.globalBlockedModifiers.contains(
              modifier,
            );
            return _buildModifierChip(
              modifier: modifier,
              isSelected: isSelected,
              onTap: () {
                final modifiers = List<String>.from(
                  _config.globalBlockedModifiers,
                );
                if (isSelected) {
                  modifiers.remove(modifier);
                } else {
                  modifiers.add(modifier);
                }
                _updateConfig(
                  _config.copyWith(globalBlockedModifiers: modifiers),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModifierChip({
    required String modifier,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final symbol = KeyShieldConstants.modifierSymbols[modifier] ?? '';
    final name = _getModifierDisplayName(modifier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KeyShieldConstants.chipPaddingH,
          vertical: KeyShieldConstants.chipPaddingV,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? _colors.accent.withValues(alpha: 0.2)
              : _colors.overlayLight,
          border: Border.all(
            color: isSelected ? _colors.accent : _colors.border,
          ),
          borderRadius: BorderRadius.circular(
            KeyShieldConstants.chipBorderRadius,
          ),
        ),
        child: Text(
          '$symbol $name',
          style: TextStyle(
            color: isSelected ? _colors.accent : _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
      ),
    );
  }

  String _getModifierDisplayName(String modifier) {
    final l10n = AppLocalizations.of(context)!;
    switch (modifier) {
      case 'command':
        return l10n.keyShieldModifierCommand;
      case 'option':
        return l10n.keyShieldModifierOption;
      case 'control':
        return l10n.keyShieldModifierControl;
      default:
        return modifier;
    }
  }

  // MARK: - Allowed Combos

  Widget _buildAllowedCombosSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keyShieldAllowedCombos,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.keyShieldAllowedCombosHint,
          style: TextStyle(
            color: _colors.secondaryText,
            fontSize: AppConstants.fontSizeDialogHint,
          ),
        ),
        const SizedBox(height: 8),
        ..._config.globalAllowedCombos.map((combo) => _buildComboRow(combo)),
        if (_isAddingCombo) _buildComboInput(),
        TextButton.icon(
          onPressed: () => setState(() => _isAddingCombo = true),
          icon: Icon(Icons.add, size: 14, color: _colors.accent),
          label: Text(
            l10n.keyShieldAddCombo,
            style: TextStyle(
              color: _colors.accent,
              fontSize: AppConstants.fontSizeDialogContent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComboRow(KeyCombo combo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            combo.toString(),
            style: TextStyle(
              color: _colors.primaryText,
              fontSize: AppConstants.fontSizeDialogContent,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              final combos = List<KeyCombo>.from(_config.globalAllowedCombos);
              combos.remove(combo);
              _updateConfig(_config.copyWith(globalAllowedCombos: combos));
            },
            icon: Icon(Icons.close, size: 14, color: _colors.inactive),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildComboInput() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _newComboModifier,
              isExpanded: true,
              dropdownColor: _colors.dialogBackground,
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
              underline: Container(height: 1, color: _colors.border),
              items: _availableModifiers.map((m) {
                final symbol = KeyShieldConstants.modifierSymbols[m] ?? '';
                return DropdownMenuItem(
                  value: m,
                  child: Text('$symbol ${_getModifierDisplayName(m)}'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _newComboModifier = v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '+',
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
            ),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: _newComboKey,
              isExpanded: true,
              dropdownColor: _colors.dialogBackground,
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
              ),
              underline: Container(height: 1, color: _colors.border),
              menuMaxHeight: 300,
              items: _availableKeys.map((k) {
                return DropdownMenuItem(value: k, child: Text(k.toUpperCase()));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _newComboKey = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final newCombo = KeyCombo(
                modifier: _newComboModifier,
                key: _newComboKey,
              );
              if (!_config.globalAllowedCombos.contains(newCombo)) {
                final combos = List<KeyCombo>.from(_config.globalAllowedCombos)
                  ..add(newCombo);
                _updateConfig(_config.copyWith(globalAllowedCombos: combos));
              }
              setState(() => _isAddingCombo = false);
            },
            icon: Icon(Icons.check, size: 16, color: _colors.accent),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: l10n.keyShieldAddCombo,
          ),
          IconButton(
            onPressed: () => setState(() => _isAddingCombo = false),
            icon: Icon(Icons.close, size: 16, color: _colors.inactive),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // MARK: - Feedback

  Widget _buildFeedbackSection(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.keyShieldFeedback,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
        DropdownButton<String>(
          value: _config.feedbackMode,
          dropdownColor: _colors.dialogBackground,
          style: TextStyle(
            color: _colors.primaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
          underline: Container(height: 1, color: _colors.border),
          items: [
            DropdownMenuItem(
              value: KeyShieldConstants.feedbackNone,
              child: Text(l10n.keyShieldFeedbackNone),
            ),
            DropdownMenuItem(
              value: KeyShieldConstants.feedbackVisual,
              child: Text(l10n.keyShieldFeedbackVisual),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _updateConfig(_config.copyWith(feedbackMode: v));
            }
          },
        ),
      ],
    );
  }

  // MARK: - Protected Apps

  Widget _buildProtectedAppsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.keyShieldProtectedApps,
              style: TextStyle(
                color: _colors.primaryText,
                fontSize: AppConstants.fontSizeDialogContent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _showRunningAppPicker,
                  icon: Icon(Icons.apps, size: 14, color: _colors.accent),
                  label: Text(
                    l10n.keyShieldFromRunningApps,
                    style: TextStyle(
                      color: _colors.accent,
                      fontSize: AppConstants.fontSizeDialogHint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_config.appRules.isEmpty)
          _buildEmptyAppsState(l10n)
        else
          ..._config.appRules.values.map((rule) => _buildAppRuleItem(rule)),
      ],
    );
  }

  Widget _buildEmptyAppsState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.keyShieldNoApps,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _colors.secondaryText,
            fontSize: AppConstants.fontSizeDialogContent,
          ),
        ),
      ),
    );
  }

  Widget _buildAppRuleItem(AppKeyShieldRule rule) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(KeyShieldConstants.itemPadding),
      decoration: BoxDecoration(
        color: _colors.overlayLight,
        border: Border.all(color: _colors.border),
        borderRadius: BorderRadius.circular(
          KeyShieldConstants.itemBorderRadius,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.appName,
                  style: TextStyle(
                    color: _colors.primaryText,
                    fontSize: AppConstants.fontSizeDialogContent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rule.bundleId,
                  style: TextStyle(
                    color: _colors.secondaryText,
                    fontSize: AppConstants.fontSizeDialogHint,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${l10n.keyShieldAutoActivate}: ',
                      style: TextStyle(
                        color: _colors.secondaryText,
                        fontSize: AppConstants.fontSizeDialogHint,
                      ),
                    ),
                    Icon(
                      rule.autoActivate
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 12,
                      color: rule.autoActivate
                          ? _colors.accent
                          : _colors.inactive,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rule.hasCustomRules
                            ? _colors.accent.withValues(alpha: 0.1)
                            : _colors.overlayLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: rule.hasCustomRules
                              ? _colors.accent
                              : _colors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        rule.hasCustomRules
                            ? l10n.keyShieldCustomRules
                            : l10n.keyShieldGlobalRules,
                        style: TextStyle(
                          color: rule.hasCustomRules
                              ? _colors.accent
                              : _colors.secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: _colors.inactive),
            color: _colors.dialogBackground,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'customize',
                child: Text(
                  l10n.keyShieldCustomize,
                  style: TextStyle(
                    color: _colors.primaryText,
                    fontSize: AppConstants.fontSizeDialogContent,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  l10n.keyShieldRemove,
                  style: TextStyle(
                    color: _colors.error,
                    fontSize: AppConstants.fontSizeDialogContent,
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'customize') {
                _showPerAppSettings(rule);
              } else if (value == 'remove') {
                final rules = Map<String, AppKeyShieldRule>.from(
                  _config.appRules,
                );
                rules.remove(rule.bundleId);
                _updateConfig(_config.copyWith(appRules: rules));
              }
            },
          ),
        ],
      ),
    );
  }

  // MARK: - Dialogs

  void _showRunningAppPicker() {
    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (context) => KeyShieldAppPicker(
        themeColors: _colors,
        keyShieldService: _keyShieldService,
        existingBundleIds: _config.appRules.keys.toSet(),
        onAppsSelected: (apps) {
          final rules = Map<String, AppKeyShieldRule>.from(_config.appRules);
          for (final app in apps) {
            rules[app.bundleId] = AppKeyShieldRule(
              bundleId: app.bundleId,
              appName: app.name,
            );
          }
          _updateConfig(_config.copyWith(appRules: rules));
        },
      ),
    );
  }

  void _showPerAppSettings(AppKeyShieldRule rule) {
    final l10n = AppLocalizations.of(context)!;
    var editedRule = rule;

    showDialog(
      context: context,
      barrierColor: _colors.overlay,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final useGlobal = !editedRule.hasCustomRules;
          return AlertDialog(
            backgroundColor: _colors.dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                KeyShieldConstants.dialogBorderRadius,
              ),
              side: BorderSide(color: _colors.border, width: 2),
            ),
            title: Text(
              '${l10n.keyShieldPerAppSettings}: ${rule.appName}',
              style: TextStyle(
                color: _colors.accent,
                fontSize: AppConstants.fontSizeDialogTitle,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.keyShieldAutoActivate,
                      style: TextStyle(
                        color: _colors.primaryText,
                        fontSize: AppConstants.fontSizeDialogContent,
                      ),
                    ),
                    Switch(
                      value: editedRule.autoActivate,
                      onChanged: (v) {
                        setDialogState(() {
                          editedRule = editedRule.copyWith(autoActivate: v);
                        });
                      },
                      activeThumbColor: _colors.accent,
                      activeTrackColor: _colors.accent.withValues(alpha: 0.5),
                      inactiveThumbColor: _colors.inactive,
                      inactiveTrackColor: _colors.inactive.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.keyShieldUseGlobalDefaults,
                      style: TextStyle(
                        color: _colors.primaryText,
                        fontSize: AppConstants.fontSizeDialogContent,
                      ),
                    ),
                    Switch(
                      value: useGlobal,
                      onChanged: (v) {
                        setDialogState(() {
                          if (v) {
                            editedRule = editedRule.copyWith(
                              clearBlockedModifiers: true,
                              clearAllowedCombos: true,
                            );
                          } else {
                            editedRule = editedRule.copyWith(
                              blockedModifiers: List<String>.from(
                                _config.globalBlockedModifiers,
                              ),
                              allowedCombos: List<KeyCombo>.from(
                                _config.globalAllowedCombos,
                              ),
                            );
                          }
                        });
                      },
                      activeThumbColor: _colors.accent,
                      activeTrackColor: _colors.accent.withValues(alpha: 0.5),
                      inactiveThumbColor: _colors.inactive,
                      inactiveTrackColor: _colors.inactive.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ],
                ),
                if (!useGlobal) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.keyShieldBlockedModifiers,
                      style: TextStyle(
                        color: _colors.primaryText,
                        fontSize: AppConstants.fontSizeDialogContent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: KeyShieldConstants.chipSpacing,
                    children: _availableModifiers.map((modifier) {
                      final mods = editedRule.blockedModifiers ?? [];
                      final isSelected = mods.contains(modifier);
                      return _buildModifierChip(
                        modifier: modifier,
                        isSelected: isSelected,
                        onTap: () {
                          setDialogState(() {
                            final newMods = List<String>.from(mods);
                            if (isSelected) {
                              newMods.remove(modifier);
                            } else {
                              newMods.add(modifier);
                            }
                            editedRule = editedRule.copyWith(
                              blockedModifiers: newMods,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: _colors.inactive),
                ),
              ),
              TextButton(
                onPressed: () {
                  final rules = Map<String, AppKeyShieldRule>.from(
                    _config.appRules,
                  );
                  rules[rule.bundleId] = editedRule;
                  _updateConfig(_config.copyWith(appRules: rules));
                  Navigator.of(dialogContext).pop();
                },
                child: Text('OK', style: TextStyle(color: _colors.accent)),
              ),
            ],
          );
        },
      ),
    );
  }
}
