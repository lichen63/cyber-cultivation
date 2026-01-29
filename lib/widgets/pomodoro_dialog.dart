import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cyber_cultivation/l10n/app_localizations.dart';
import '../constants.dart';

class PomodoroDialog extends StatefulWidget {
  final int initialDuration;
  final int initialRelax;
  final int initialLoops;
  final AppThemeColors themeColors;
  final Function(int, int, int) onStart;
  final Function(int, int, int)? onSaveAsDefault;

  const PomodoroDialog({
    super.key,
    required this.initialDuration,
    required this.initialRelax,
    required this.initialLoops,
    required this.themeColors,
    required this.onStart,
    this.onSaveAsDefault,
  });

  @override
  State<PomodoroDialog> createState() => _PomodoroDialogState();
}

class _PomodoroDialogState extends State<PomodoroDialog> {
  late TextEditingController _durationController;
  late TextEditingController _relaxController;
  late TextEditingController _loopsController;

  String? _durationError;
  String? _relaxError;
  String? _loopsError;

  AppThemeColors get _colors => widget.themeColors;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.initialDuration.toString(),
    );
    _relaxController = TextEditingController(
      text: widget.initialRelax.toString(),
    );
    _loopsController = TextEditingController(
      text: widget.initialLoops.toString(),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _relaxController.dispose();
    _loopsController.dispose();
    super.dispose();
  }

  /// Validates input values and returns parsed values if valid, null otherwise
  (int?, int?, int?) _validateInputs() {
    final l10n = AppLocalizations.of(context)!;
    final duration = int.tryParse(_durationController.text);
    final relax = int.tryParse(_relaxController.text);
    final loops = int.tryParse(_loopsController.text);

    setState(() {
      _durationError = (duration == null || duration <= 0)
          ? l10n.invalidInputErrorText
          : null;
      _relaxError = (relax == null || relax <= 0)
          ? l10n.invalidInputErrorText
          : null;
      _loopsError = (loops == null || loops <= 0)
          ? l10n.invalidInputErrorText
          : null;
    });

    if (_durationError == null && _relaxError == null && _loopsError == null) {
      return (duration, relax, loops);
    }
    return (null, null, null);
  }

  void _validateAndStart() {
    final (duration, relax, loops) = _validateInputs();
    if (duration != null && relax != null && loops != null) {
      widget.onStart(duration, relax, loops);
    }
  }

  void _saveAsDefault() {
    final (duration, relax, loops) = _validateInputs();
    if (duration != null && relax != null && loops != null) {
      widget.onSaveAsDefault?.call(duration, relax, loops);
    }
  }

  int _calculateExpectedExp() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    final loops = int.tryParse(_loopsController.text) ?? 0;
    return (duration * loops * AppConstants.expGainPerMinute).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      backgroundColor: _colors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: _colors.border, width: 2),
      ),
      title: Center(
        child: Text(
          l10n.pomodoroDialogTitle,
          style: TextStyle(color: _colors.accent),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingInput(
              l10n.pomodoroDurationLabel,
              _durationController,
              _durationError,
            ),
            const SizedBox(height: 10),
            _buildSettingInput(
              l10n.pomodoroRelaxLabel,
              _relaxController,
              _relaxError,
            ),
            const SizedBox(height: 10),
            _buildSettingInput(
              l10n.pomodoroLoopsLabel,
              _loopsController,
              _loopsError,
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _durationController,
              builder: (context, durationValue, child) {
                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _loopsController,
                  builder: (context, loopsValue, child) {
                    return Text(
                      '${l10n.pomodoroExpectedExpLabel}${_calculateExpectedExp()}',
                      style: TextStyle(
                        color: _colors.accentSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppConstants.fontSizeDialogContent,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.hovered)) {
                return _colors.inactive.withValues(alpha: 0.2);
              }
              if (states.contains(WidgetState.pressed)) {
                return _colors.inactive.withValues(alpha: 0.4);
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.all<Color>(_colors.inactive),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButtonText),
        ),
        if (widget.onSaveAsDefault != null)
          TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.hovered)) {
                  return _colors.accentSecondary.withValues(alpha: 0.2);
                }
                if (states.contains(WidgetState.pressed)) {
                  return _colors.accentSecondary.withValues(alpha: 0.4);
                }
                return null;
              }),
              foregroundColor: WidgetStateProperty.all<Color>(
                _colors.accentSecondary,
              ),
            ),
            onPressed: _saveAsDefault,
            child: Text(l10n.pomodoroSaveAsDefaultButtonText),
          ),
        TextButton(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.hovered)) {
                return _colors.accent.withValues(alpha: 0.2);
              }
              if (states.contains(WidgetState.pressed)) {
                return _colors.accent.withValues(alpha: 0.4);
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.all<Color>(_colors.accent),
          ),
          onPressed: () {
            _validateAndStart();
          },
          child: Text(l10n.pomodoroStartButtonText),
        ),
      ],
    );
  }

  Widget _buildSettingInput(
    String label,
    TextEditingController controller,
    String? errorText,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(label, style: TextStyle(color: _colors.primaryText)),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 140,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _colors.primaryText,
                ),
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  if (currentValue > 1) {
                    controller.text = (currentValue - 1).toString();
                  }
                },
              ),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                      final currentValue = int.tryParse(controller.text) ?? 0;
                      controller.text = (currentValue + 1).toString();
                    },
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () {
                      final currentValue = int.tryParse(controller.text) ?? 0;
                      if (currentValue > 1) {
                        controller.text = (currentValue - 1).toString();
                      }
                    },
                  },
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _colors.primaryText),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _colors.secondaryText),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _colors.accent),
                      ),
                      errorText: errorText,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _colors.primaryText,
                ),
                onPressed: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  controller.text = (currentValue + 1).toString();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
