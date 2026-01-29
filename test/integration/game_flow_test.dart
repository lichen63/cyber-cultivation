import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/game_data.dart';
import 'package:cyber_cultivation/models/daily_stats.dart';
import 'package:cyber_cultivation/models/todo_item.dart';
import 'package:cyber_cultivation/constants.dart';
import 'package:cyber_cultivation/services/pomodoro_service.dart';

/// Integration tests for game data flow
/// Tests the interaction between models and how data flows through the app
void main() {
  group('GameData Integration', () {
    group('game progression flow', () {
      test('simulates level up scenario', () {
        // Start at level 1
        var gameData = GameData(level: 1, currentExp: 0);

        // Simulate gaining exp
        gameData = gameData.copyWith(currentExp: 500);
        expect(gameData.currentExp, 500);

        // Level up
        gameData = gameData.copyWith(level: 2, currentExp: 0);
        expect(gameData.level, 2);
        expect(gameData.currentExp, 0);
      });

      test('tracks daily stats across multiple days', () {
        final gameData = GameData(
          level: 1,
          currentExp: 0,
          dailyStats: {
            '2024-01-15': DailyStats(
              keyboardCount: 1000,
              mouseClickCount: 500,
              mouseMoveDistance: 10000,
            ),
            '2024-01-16': DailyStats(
              keyboardCount: 1500,
              mouseClickCount: 750,
              mouseMoveDistance: 15000,
            ),
          },
        );

        // Verify both days are tracked
        expect(gameData.dailyStats.length, 2);
        expect(gameData.dailyStats['2024-01-15']!.keyboardCount, 1000);
        expect(gameData.dailyStats['2024-01-16']!.keyboardCount, 1500);
      });

      test('manages todo workflow', () {
        final testDate = DateTime.now();

        // Create initial game data with todos
        var gameData = GameData(
          level: 1,
          currentExp: 0,
          todos: [
            TodoItem(
              id: '1',
              title: 'Complete tutorial',
              status: TodoStatus.todo,
              createdAt: testDate,
            ),
          ],
        );

        // Add a new todo
        final newTodos = List<TodoItem>.from(gameData.todos)
          ..add(TodoItem(
            id: '2',
            title: 'Reach level 10',
            status: TodoStatus.todo,
            createdAt: testDate,
          ));

        gameData = gameData.copyWith(todos: newTodos);
        expect(gameData.todos.length, 2);

        // Complete the first todo
        final updatedTodos = gameData.todos.map((todo) {
          if (todo.id == '1') {
            return todo.copyWith(status: TodoStatus.done);
          }
          return todo;
        }).toList();

        gameData = gameData.copyWith(todos: updatedTodos);
        expect(gameData.todos[0].status, TodoStatus.done);
      });
    });

    group('settings persistence flow', () {
      test('simulates settings change and save', () {
        // Initial state
        var gameData = GameData(
          level: 5,
          currentExp: 250,
          isAlwaysOnTop: true,
          themeMode: AppThemeMode.dark,
        );

        // User changes settings
        gameData = gameData.copyWith(
          isAlwaysOnTop: false,
          themeMode: AppThemeMode.light,
          windowWidth: 800,
          windowHeight: 600,
        );

        // Simulate save (convert to JSON and back)
        final json = gameData.toJson();
        final restored = GameData.fromJson(json);

        // Verify all settings were preserved
        expect(restored.level, 5);
        expect(restored.currentExp, 250);
        expect(restored.isAlwaysOnTop, false);
        expect(restored.themeMode, AppThemeMode.light);
        expect(restored.windowWidth, 800);
        expect(restored.windowHeight, 600);
      });

      test('simulates language change', () {
        var gameData = GameData(
          level: 1,
          currentExp: 0,
          language: 'en',
        );

        // Change language
        gameData = gameData.copyWith(language: 'zh');

        // Persist and restore
        final json = gameData.toJson();
        final restored = GameData.fromJson(json);

        expect(restored.language, 'zh');
      });
    });

    group('full session simulation', () {
      test('simulates a complete user session', () {
        // 1. Start with fresh save
        var gameData = GameData(level: 1, currentExp: 0);

        // 2. Set user ID
        gameData = gameData.copyWith(userId: 'user123');
        expect(gameData.userId, 'user123');

        // 3. Track some activity
        final today = DateTime.now().toIso8601String().split('T')[0];
        final dailyStats = Map<String, DailyStats>.from(gameData.dailyStats);
        dailyStats[today] = DailyStats(
          keyboardCount: 5000,
          mouseClickCount: 2500,
        );
        gameData = gameData.copyWith(dailyStats: dailyStats);

        // 4. Create a todo
        final todos = List<TodoItem>.from(gameData.todos)
          ..add(TodoItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Daily goal',
            status: TodoStatus.doing,
            createdAt: DateTime.now(),
          ));
        gameData = gameData.copyWith(todos: todos);

        // 5. Level up
        gameData = gameData.copyWith(
          level: 2,
          currentExp: 100,
        );

        // 6. Save and restore
        final json = gameData.toJson();
        final restored = GameData.fromJson(json);

        // Verify complete state
        expect(restored.userId, 'user123');
        expect(restored.level, 2);
        expect(restored.currentExp, 100);
        expect(restored.dailyStats[today], isNotNull);
        expect(restored.dailyStats[today]!.keyboardCount, 5000);
        expect(restored.todos.length, 1);
        expect(restored.todos[0].status, TodoStatus.doing);
      });
    });
  });

  group('Pomodoro Integration', () {
    group('pomodoro with exp gain', () {
      test('tracks exp gain from completed work sessions', () async {
        int totalExpGained = 0;
        final service = PomodoroService(
          onWorkSessionComplete: (minutes) {
            // Simulate exp gain: 10 exp per minute
            totalExpGained += minutes * 10;
          },
        );

        // Start a 25-minute session
        service.start(workMinutes: 25, relaxMinutes: 5, loops: 1);
        expect(service.isActive, true);
        expect(service.state.workDurationMinutes, 25);
        
        // Verify exp calculation would work (callback is set up)
        expect(totalExpGained, 0); // No session completed yet

        // Clean up
        service.dispose();
      });

      test('maintains state during pomodoro session', () {
        final service = PomodoroService();

        service.start(workMinutes: 25, relaxMinutes: 5, loops: 4);

        // Verify initial state
        expect(service.currentLoop, 1);
        expect(service.totalLoops, 4);
        expect(service.isRelaxing, false);
        expect(service.state.formattedTime, '25:00');

        service.dispose();
      });
    });
  });

  group('DailyStats Integration', () {
    test('accumulates stats throughout a day', () {
      var stats = DailyStats();

      // Simulate keyboard events
      stats.keyboardCount += 100;
      stats.keyboardCount += 50;
      expect(stats.keyboardCount, 150);

      // Simulate mouse clicks
      stats.mouseClickCount += 25;
      stats.mouseClickCount += 15;
      expect(stats.mouseClickCount, 40);

      // Simulate mouse movement
      stats.mouseMoveDistance += 500;
      stats.mouseMoveDistance += 300;
      expect(stats.mouseMoveDistance, 800);

      // Save and restore
      final json = stats.toJson();
      final restored = DailyStats.fromJson(json);

      expect(restored.keyboardCount, 150);
      expect(restored.mouseClickCount, 40);
      expect(restored.mouseMoveDistance, 800);
    });
  });

  group('Todo Integration', () {
    test('manages todo list operations', () {
      final List<TodoItem> todos = [];

      // Add todos
      todos.add(TodoItem(
        id: '1',
        title: 'Task 1',
        status: TodoStatus.todo,
        createdAt: DateTime.now(),
      ));
      todos.add(TodoItem(
        id: '2',
        title: 'Task 2',
        status: TodoStatus.todo,
        createdAt: DateTime.now(),
      ));
      expect(todos.length, 2);

      // Update status
      todos[0] = todos[0].cycleStatus();
      expect(todos[0].status, TodoStatus.doing);

      todos[0] = todos[0].cycleStatus();
      expect(todos[0].status, TodoStatus.done);

      // Remove completed
      todos.removeWhere((t) => t.status == TodoStatus.done);
      expect(todos.length, 1);
      expect(todos[0].id, '2');
    });

    test('preserves todo order through serialization', () {
      final todos = [
        TodoItem(
          id: '1',
          title: 'First',
          status: TodoStatus.todo,
          createdAt: DateTime(2024, 1, 1),
        ),
        TodoItem(
          id: '2',
          title: 'Second',
          status: TodoStatus.doing,
          createdAt: DateTime(2024, 1, 2),
        ),
        TodoItem(
          id: '3',
          title: 'Third',
          status: TodoStatus.done,
          createdAt: DateTime(2024, 1, 3),
        ),
      ];

      final gameData = GameData(
        level: 1,
        currentExp: 0,
        todos: todos,
      );

      final json = gameData.toJson();
      final restored = GameData.fromJson(json);

      expect(restored.todos.length, 3);
      expect(restored.todos[0].title, 'First');
      expect(restored.todos[1].title, 'Second');
      expect(restored.todos[2].title, 'Third');
    });
  });

  group('Theme Integration', () {
    test('theme mode affects colors correctly', () {
      // Dark theme
      final darkColors = AppThemeColors.fromMode(AppThemeMode.dark);
      expect(darkColors.brightness, Brightness.dark);
      expect(darkColors, AppThemeColors.dark);

      // Light theme
      final lightColors = AppThemeColors.fromMode(AppThemeMode.light);
      expect(lightColors.brightness, Brightness.light);
      expect(lightColors, AppThemeColors.light);
    });

    test('theme mode persists with game data', () {
      var gameData = GameData(
        level: 1,
        currentExp: 0,
        themeMode: AppThemeMode.light,
      );

      final json = gameData.toJson();
      expect(json['themeMode'], 'light');

      final restored = GameData.fromJson(json);
      expect(restored.themeMode, AppThemeMode.light);

      final colors = AppThemeColors.fromMode(restored.themeMode);
      expect(colors.brightness, Brightness.light);
    });
  });
}
