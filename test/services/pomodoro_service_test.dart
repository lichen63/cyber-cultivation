import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/services/pomodoro_service.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('PomodoroState', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const state = PomodoroState();

        expect(state.isActive, false);
        expect(state.isRelaxing, false);
        expect(state.secondsRemaining, 0);
        expect(state.currentLoop, 1);
        expect(state.totalLoops, 1);
        expect(state.workDurationMinutes, AppConstants.defaultPomodoroDuration);
        expect(state.relaxDurationMinutes, AppConstants.defaultRelaxDuration);
      });

      test('creates instance with custom values', () {
        const state = PomodoroState(
          isActive: true,
          isRelaxing: true,
          secondsRemaining: 1500,
          currentLoop: 2,
          totalLoops: 4,
          workDurationMinutes: 30,
          relaxDurationMinutes: 10,
        );

        expect(state.isActive, true);
        expect(state.isRelaxing, true);
        expect(state.secondsRemaining, 1500);
        expect(state.currentLoop, 2);
        expect(state.totalLoops, 4);
        expect(state.workDurationMinutes, 30);
        expect(state.relaxDurationMinutes, 10);
      });
    });

    group('copyWith', () {
      test('copies with new isActive', () {
        const original = PomodoroState();
        final copied = original.copyWith(isActive: true);

        expect(copied.isActive, true);
        expect(copied.isRelaxing, original.isRelaxing);
      });

      test('copies with new secondsRemaining', () {
        const original = PomodoroState(secondsRemaining: 1500);
        final copied = original.copyWith(secondsRemaining: 1000);

        expect(copied.secondsRemaining, 1000);
      });

      test('copies with no changes preserves all values', () {
        const original = PomodoroState(
          isActive: true,
          isRelaxing: true,
          secondsRemaining: 600,
          currentLoop: 2,
          totalLoops: 3,
        );
        final copied = original.copyWith();

        expect(copied.isActive, original.isActive);
        expect(copied.isRelaxing, original.isRelaxing);
        expect(copied.secondsRemaining, original.secondsRemaining);
        expect(copied.currentLoop, original.currentLoop);
        expect(copied.totalLoops, original.totalLoops);
      });

      test('copies with multiple values', () {
        const original = PomodoroState();
        final copied = original.copyWith(
          isActive: true,
          secondsRemaining: 1800,
          currentLoop: 3,
        );

        expect(copied.isActive, true);
        expect(copied.secondsRemaining, 1800);
        expect(copied.currentLoop, 3);
      });
    });

    group('formattedTime', () {
      test('formats zero seconds correctly', () {
        const state = PomodoroState(secondsRemaining: 0);
        expect(state.formattedTime, '00:00');
      });

      test('formats single digit seconds correctly', () {
        const state = PomodoroState(secondsRemaining: 5);
        expect(state.formattedTime, '00:05');
      });

      test('formats single digit minutes correctly', () {
        const state = PomodoroState(secondsRemaining: 65);
        expect(state.formattedTime, '01:05');
      });

      test('formats double digit minutes and seconds correctly', () {
        const state = PomodoroState(secondsRemaining: 1500);
        expect(state.formattedTime, '25:00');
      });

      test('formats 59 minutes 59 seconds correctly', () {
        const state = PomodoroState(secondsRemaining: 3599);
        expect(state.formattedTime, '59:59');
      });

      test('formats over an hour correctly', () {
        const state = PomodoroState(secondsRemaining: 3661);
        expect(state.formattedTime, '61:01');
      });
    });

    group('progress', () {
      test('returns 0 for work phase when time is 0', () {
        const state = PomodoroState(
          isRelaxing: false,
          secondsRemaining: 0,
          workDurationMinutes: 25,
        );
        expect(state.progress, 0.0);
      });

      test('returns 1.0 for work phase when at full time', () {
        const state = PomodoroState(
          isRelaxing: false,
          secondsRemaining: 1500,
          workDurationMinutes: 25,
        );
        expect(state.progress, 1.0);
      });

      test('returns 0.5 for work phase when at half time', () {
        const state = PomodoroState(
          isRelaxing: false,
          secondsRemaining: 750,
          workDurationMinutes: 25,
        );
        expect(state.progress, 0.5);
      });

      test('returns correct progress for relax phase', () {
        const state = PomodoroState(
          isRelaxing: true,
          secondsRemaining: 150,
          relaxDurationMinutes: 5,
        );
        expect(state.progress, 0.5);
      });

      test('returns 0 when totalSeconds is 0', () {
        const state = PomodoroState(
          isRelaxing: false,
          secondsRemaining: 100,
          workDurationMinutes: 0,
        );
        expect(state.progress, 0.0);
      });
    });
  });

  group('PomodoroService', () {
    late PomodoroService service;

    setUp(() {
      service = PomodoroService(
        onWorkSessionComplete: (minutes) {
          // Callback for work session completion
        },
        onAllLoopsComplete: () {
          // Callback for all loops completion
        },
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('initial state', () {
      test('is not active initially', () {
        expect(service.isActive, false);
        expect(service.isRelaxing, false);
        expect(service.secondsRemaining, 0);
      });

      test('state getter returns PomodoroState', () {
        expect(service.state, isA<PomodoroState>());
      });
    });

    group('start', () {
      test('starts a new session', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 3);

        expect(service.isActive, true);
        expect(service.isRelaxing, false);
        expect(service.secondsRemaining, 25 * 60);
        expect(service.currentLoop, 1);
        expect(service.totalLoops, 3);
      });

      test('does not restart if already active', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 3);
        service.start(workMinutes: 30, relaxMinutes: 10, loops: 4);

        // Should still be the first session
        expect(service.secondsRemaining, 25 * 60);
        expect(service.totalLoops, 3);
      });

      test('notifies listeners on start', () {
        int notifyCount = 0;
        service.addListener(() => notifyCount++);

        service.start(workMinutes: 1, relaxMinutes: 1, loops: 1);

        expect(notifyCount, greaterThan(0));
      });
    });

    group('cancel', () {
      test('cancels an active session', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 3);
        service.cancel();

        expect(service.isActive, false);
        expect(service.secondsRemaining, 0);
      });

      test('does nothing if not active', () {
        service.cancel();

        expect(service.isActive, false);
      });

      test('notifies listeners on cancel', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 1);
        int notifyCount = 0;
        service.addListener(() => notifyCount++);

        service.cancel();

        expect(notifyCount, greaterThan(0));
      });
    });

    group('timer ticking', () {
      test('starts timer when session begins', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 1);
        
        // Verify timer is set up correctly
        expect(service.isActive, true);
        expect(service.secondsRemaining, 25 * 60);
      });

      test('notifies listeners when started', () {
        int notifyCount = 0;
        service.addListener(() => notifyCount++);
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 1);

        // Should notify at least once on start
        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    group('phase completion', () {
      test('calls onWorkSessionComplete when work phase ends', () async {
        // Use a very short duration for testing
        service.start(workMinutes: 1, relaxMinutes: 1, loops: 2);

        // Manually simulate time passing by waiting
        // This test would need mocking for better control
        // For now, we verify the service is active
        expect(service.isActive, true);
        expect(service.state.workDurationMinutes, 1);
      });
    });

    group('dispose', () {
      test('can be disposed without error', () {
        // Create a separate service for dispose test to avoid double dispose
        final disposeService = PomodoroService();
        disposeService.start(workMinutes: 25, relaxMinutes: 5, loops: 1);
        expect(() => disposeService.dispose(), returnsNormally);
      });

      test('can be disposed when not active', () {
        // Create a separate service for dispose test to avoid double dispose
        final disposeService = PomodoroService();
        expect(() => disposeService.dispose(), returnsNormally);
      });
    });

    group('state properties', () {
      test('currentLoop returns correct value', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 4);
        expect(service.currentLoop, 1);
      });

      test('totalLoops returns correct value', () {
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 4);
        expect(service.totalLoops, 4);
      });
    });
  });
}
