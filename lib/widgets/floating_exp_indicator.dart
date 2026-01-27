import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import '../constants.dart';

/// A manager widget that handles multiple floating exp indicators
/// with throttling queue to prevent overwhelming the UI
class FloatingExpIndicatorManager extends StatefulWidget {
  final AppThemeColors themeColors;

  const FloatingExpIndicatorManager({super.key, required this.themeColors});

  @override
  State<FloatingExpIndicatorManager> createState() =>
      FloatingExpIndicatorManagerState();
}

class FloatingExpIndicatorManagerState
    extends State<FloatingExpIndicatorManager> {
  /// Queue of pending exp amounts to show
  final Queue<double> _pendingQueue = Queue<double>();

  /// Currently visible indicators
  final Map<int, _IndicatorData> _visibleIndicators = {};

  int _nextId = 0;
  Timer? _queueTimer;
  bool _canShowNext = true;

  /// Add a new exp gain indicator (may be queued)
  void addExpGain(double amount) {
    if (!mounted) return;

    if (_canShowNext) {
      // Show immediately
      _showIndicator(amount);
      _canShowNext = false;
      // Start cooldown timer
      _queueTimer?.cancel();
      _queueTimer = Timer(AppConstants.floatingExpQueueInterval, _processQueue);
    } else {
      // Add to queue if not full
      if (_pendingQueue.length < AppConstants.floatingExpMaxQueueSize) {
        _pendingQueue.add(amount);
      }
      // Ignore if queue is full
    }
  }

  void _processQueue() {
    if (!mounted) return;

    if (_pendingQueue.isNotEmpty) {
      final amount = _pendingQueue.removeFirst();
      _showIndicator(amount);
      // Schedule next queue processing
      _queueTimer?.cancel();
      _queueTimer = Timer(AppConstants.floatingExpQueueInterval, _processQueue);
    } else {
      // Queue is empty, allow immediate showing next time
      _canShowNext = true;
    }
  }

  void _showIndicator(double amount) {
    final id = _nextId++;
    setState(() {
      _visibleIndicators[id] = _IndicatorData(id: id, amount: amount);
    });
  }

  void _removeIndicator(int id) {
    if (!mounted) return;

    setState(() {
      _visibleIndicators.remove(id);
    });
  }

  @override
  void dispose() {
    _queueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Stack with clip disabled allows indicators to overflow as they animate
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Empty container as anchor point
        const SizedBox.shrink(),
        for (final indicator in _visibleIndicators.values)
          _FloatingExpIndicator(
            key: ValueKey(indicator.id),
            indicatorId: indicator.id,
            expAmount: indicator.amount,
            themeColors: widget.themeColors,
            onComplete: _removeIndicator,
          ),
      ],
    );
  }
}

/// Individual floating exp indicator with its own animation
class _FloatingExpIndicator extends StatefulWidget {
  final int indicatorId;
  final double expAmount;
  final AppThemeColors themeColors;
  final void Function(int id) onComplete;

  const _FloatingExpIndicator({
    super.key,
    required this.indicatorId,
    required this.expAmount,
    required this.themeColors,
    required this.onComplete,
  });

  @override
  State<_FloatingExpIndicator> createState() => _FloatingExpIndicatorState();
}

class _FloatingExpIndicatorState extends State<_FloatingExpIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.floatingExpDuration,
      vsync: this,
    );

    // Move from bottom (0) to top (distance) with easing
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: AppConstants.floatingExpDistance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start fully visible, fade out towards the end
    _fadeAnimation = TweenSequence<double>([
      // Stay fully visible for most of the animation
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 70.0),
      // Fade out at the end
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted && !_isCompleted) {
        _isCompleted = true;
        widget.onComplete(widget.indicatorId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Formats exp amount for display
  String _formatExpAmount(double value) {
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T';
    } else if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    } else if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    } else if (value == value.truncateToDouble()) {
      // Whole number - show without decimal
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          // Start lower (positive Y offset) then move upward (negative Y)
          offset: Offset(
            0,
            AppConstants.floatingExpStartOffset - _positionAnimation.value,
          ),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.floatingExpPaddingHorizontal,
          vertical: AppConstants.floatingExpPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          // Use stadium shape (pill/ellipse) by setting borderRadius to half the height
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.grey.shade300,
            width: AppConstants.floatingExpBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: AppConstants.floatingExpShadowBlur,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '+${_formatExpAmount(widget.expAmount)} EXP',
          style: const TextStyle(
            color: Colors.black,
            fontSize: AppConstants.fontSizeFloatingExp,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Internal data class to track individual indicators
class _IndicatorData {
  final int id;
  final double amount;

  _IndicatorData({required this.id, required this.amount});
}
