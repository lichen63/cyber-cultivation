import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

class PomodoroDialog extends StatefulWidget {
  final int initialDuration;
  final int initialRelax;
  final int initialLoops;
  final Function(int, int, int) onStart;

  const PomodoroDialog({
    super.key,
    required this.initialDuration,
    required this.initialRelax,
    required this.initialLoops,
    required this.onStart,
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

  @override
  void initState() {
    super.initState();
    _durationController =
        TextEditingController(text: widget.initialDuration.toString());
    _relaxController =
        TextEditingController(text: widget.initialRelax.toString());
    _loopsController =
        TextEditingController(text: widget.initialLoops.toString());
  }

  @override
  void dispose() {
    _durationController.dispose();
    _relaxController.dispose();
    _loopsController.dispose();
    super.dispose();
  }

  void _validateAndStart() {
    final duration = int.tryParse(_durationController.text);
    final relax = int.tryParse(_relaxController.text);
    final loops = int.tryParse(_loopsController.text);

    setState(() {
      _durationError = (duration == null || duration <= 0) ? AppConstants.invalidInputErrorText : null;
      _relaxError = (relax == null || relax <= 0) ? AppConstants.invalidInputErrorText : null;
      _loopsError = (loops == null || loops <= 0) ? AppConstants.invalidInputErrorText : null;
    });

    if (_durationError == null && _relaxError == null && _loopsError == null) {
      widget.onStart(duration!, relax!, loops!);
    }
  }

  int _calculateExpectedExp() {
    final duration = int.tryParse(_durationController.text) ?? 0;
    final loops = int.tryParse(_loopsController.text) ?? 0;
    return (duration * loops * AppConstants.expGainPerMinute).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      backgroundColor: AppConstants.dialogBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: const BorderSide(color: AppConstants.whiteColor, width: 2),
      ),
      title: const Center(
        child: Text(
          AppConstants.pomodoroDialogTitle,
          style: TextStyle(color: AppConstants.cyanAccentColor),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingInput(
              AppConstants.pomodoroDurationLabel,
              _durationController,
              _durationError,
            ),
            const SizedBox(height: 10),
            _buildSettingInput(
              AppConstants.pomodoroRelaxLabel,
              _relaxController,
              _relaxError,
            ),
            const SizedBox(height: 10),
            _buildSettingInput(
              AppConstants.pomodoroLoopsLabel,
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
                      '${AppConstants.pomodoroExpectedExpLabel}${_calculateExpectedExp()}',
                      style: const TextStyle(
                        color: AppConstants.purpleAccentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return AppConstants.greyColor.withOpacity(0.2);
                }
                if (states.contains(MaterialState.pressed)) {
                  return AppConstants.greyColor.withOpacity(0.4);
                }
                return null;
              },
            ),
            foregroundColor:
                MaterialStateProperty.all<Color>(AppConstants.greyColor),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppConstants.cancelButtonText),
        ),
        TextButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return AppConstants.cyanAccentColor.withOpacity(0.2);
                }
                if (states.contains(MaterialState.pressed)) {
                  return AppConstants.cyanAccentColor.withOpacity(0.4);
                }
                return null;
              },
            ),
            foregroundColor:
                MaterialStateProperty.all<Color>(AppConstants.cyanAccentColor),
          ),
          onPressed: () {
            _validateAndStart();
          },
          child: const Text(
            AppConstants.pomodoroStartButtonText,
          ),
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
          child: Text(label, style: const TextStyle(color: AppConstants.whiteColor)),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 140,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppConstants.whiteColor),
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
                    style: const TextStyle(color: AppConstants.whiteColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppConstants.white54Color),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppConstants.cyanAccentColor),
                      ),
                      errorText: errorText,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.add_circle_outline, color: AppConstants.whiteColor),
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
