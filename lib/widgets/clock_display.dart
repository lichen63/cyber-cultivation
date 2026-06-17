import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

/// A self-updating clock that shows the current date and time, refreshing once
/// per second (see [AppConstants.clockUpdateInterval]). It is purely a display
/// widget and owns its own timer, which is cancelled in [dispose].
class ClockDisplay extends StatefulWidget {
  final double scale;
  final AppThemeColors themeColors;

  const ClockDisplay({super.key, required this.themeColors, this.scale = 1.0});

  @override
  State<ClockDisplay> createState() => _ClockDisplayState();
}

class _ClockDisplayState extends State<ClockDisplay> {
  final DateFormat _formatter = DateFormat(AppConstants.clockDateTimeFormat);
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(AppConstants.clockUpdateInterval, _onTick);
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scale down only if the formatted string cannot fit the available width
    // (e.g. on very small windows), keeping the clock responsive.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.clockPaddingHorizontal * widget.scale,
          vertical: AppConstants.clockPaddingVertical * widget.scale,
        ),
        decoration: BoxDecoration(
          color: widget.themeColors.overlay,
          borderRadius: BorderRadius.circular(
            AppConstants.smallBorderRadius * widget.scale,
          ),
          border: Border.all(
            color: widget.themeColors.border,
            width: AppConstants.thinBorderWidth * widget.scale,
          ),
        ),
        child: Text(
          _formatter.format(_now),
          maxLines: 1,
          style: TextStyle(
            color: widget.themeColors.primaryText,
            fontSize: AppConstants.fontSizeClock * widget.scale,
            fontWeight: FontWeight.bold,
            // Fixed-width digits so the clock does not jitter as numbers change.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
