import 'dart:async';
import 'package:flutter/foundation.dart';

import '../constants.dart';

/// Represents the current state of a Pomodoro session
class PomodoroState {
  final bool isActive;
  final bool isRelaxing;
  final int secondsRemaining;
  final int currentLoop;
  final int totalLoops;
  final int workDurationMinutes;
  final int relaxDurationMinutes;

  const PomodoroState({
    this.isActive = false,
    this.isRelaxing = false,
    this.secondsRemaining = 0,
    this.currentLoop = 1,
    this.totalLoops = 1,
    this.workDurationMinutes = AppConstants.defaultPomodoroDuration,
    this.relaxDurationMinutes = AppConstants.defaultRelaxDuration,
  });

  PomodoroState copyWith({
    bool? isActive,
    bool? isRelaxing,
    int? secondsRemaining,
    int? currentLoop,
    int? totalLoops,
    int? workDurationMinutes,
    int? relaxDurationMinutes,
  }) {
    return PomodoroState(
      isActive: isActive ?? this.isActive,
      isRelaxing: isRelaxing ?? this.isRelaxing,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      currentLoop: currentLoop ?? this.currentLoop,
      totalLoops: totalLoops ?? this.totalLoops,
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      relaxDurationMinutes: relaxDurationMinutes ?? this.relaxDurationMinutes,
    );
  }

  /// Formatted time string (MM:SS)
  String get formattedTime {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Progress value between 0.0 and 1.0
  double get progress {
    final totalSeconds =
        (isRelaxing ? relaxDurationMinutes : workDurationMinutes) * 60;
    if (totalSeconds == 0) return 0.0;
    return secondsRemaining / totalSeconds;
  }
}

/// Service that manages Pomodoro timer logic
class PomodoroService extends ChangeNotifier {
  Timer? _timer;
  PomodoroState _state = const PomodoroState();

  /// Callback when a work session completes (for exp gain)
  final void Function(int workMinutes)? onWorkSessionComplete;

  /// Callback when all loops complete
  final VoidCallback? onAllLoopsComplete;

  PomodoroService({this.onWorkSessionComplete, this.onAllLoopsComplete});

  PomodoroState get state => _state;

  bool get isActive => _state.isActive;
  bool get isRelaxing => _state.isRelaxing;
  int get secondsRemaining => _state.secondsRemaining;
  int get currentLoop => _state.currentLoop;
  int get totalLoops => _state.totalLoops;

  /// Start a new Pomodoro session
  void start({
    required int workMinutes,
    required int relaxMinutes,
    required int loops,
  }) {
    if (_state.isActive) return;

    _state = PomodoroState(
      isActive: true,
      isRelaxing: false,
      secondsRemaining: workMinutes * 60,
      currentLoop: 1,
      totalLoops: loops,
      workDurationMinutes: workMinutes,
      relaxDurationMinutes: relaxMinutes,
    );
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer timer) {
    if (_state.secondsRemaining > 0) {
      _state = _state.copyWith(secondsRemaining: _state.secondsRemaining - 1);
      notifyListeners();
    } else {
      _handlePhaseComplete();
    }
  }

  void _handlePhaseComplete() {
    if (_state.isRelaxing) {
      // Finished relaxing, start next work loop
      final nextLoop = _state.currentLoop + 1;
      if (nextLoop > _state.totalLoops) {
        // Should not happen, but safety check
        cancel();
      } else {
        _state = _state.copyWith(
          isRelaxing: false,
          currentLoop: nextLoop,
          secondsRemaining: _state.workDurationMinutes * 60,
        );
        notifyListeners();
      }
    } else {
      // Finished working
      onWorkSessionComplete?.call(_state.workDurationMinutes);

      if (_state.currentLoop >= _state.totalLoops) {
        // All loops complete
        onAllLoopsComplete?.call();
        cancel();
      } else {
        // Start relax phase
        _state = _state.copyWith(
          isRelaxing: true,
          secondsRemaining: _state.relaxDurationMinutes * 60,
        );
        notifyListeners();
      }
    }
  }

  /// Cancel the current Pomodoro session
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _state = const PomodoroState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
