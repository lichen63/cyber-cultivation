import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/game_data.dart';
import 'package:cyber_cultivation/models/daily_stats.dart';
import 'package:cyber_cultivation/models/todo_item.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('GameData', () {
    group('constructor', () {
      test('creates instance with required values and defaults', () {
        final gameData = GameData(level: 1, currentExp: 0);

        expect(gameData.level, 1);
        expect(gameData.currentExp, 0);
        expect(gameData.isAlwaysOnTop, true);
        expect(gameData.isAntiSleepEnabled, false);
        expect(gameData.isAlwaysShowActionButtons, false);
        expect(gameData.isAutoStartEnabled, false);
        expect(gameData.windowWidth, isNull);
        expect(gameData.windowHeight, isNull);
        expect(gameData.userId, isNull);
        expect(gameData.language, isNull);
        expect(gameData.themeMode, AppThemeMode.dark);
        expect(gameData.dailyStats, isEmpty);
        expect(gameData.todos, isEmpty);
      });

      test('creates instance with all custom values', () {
        final dailyStats = {
          '2024-01-15': DailyStats(keyboardCount: 100),
        };
        final todos = [
          TodoItem(
            id: '1',
            title: 'Test',
            status: TodoStatus.todo,
            createdAt: DateTime.now(),
          ),
        ];

        final gameData = GameData(
          level: 5,
          currentExp: 500,
          isAlwaysOnTop: false,
          isAntiSleepEnabled: true,
          isAlwaysShowActionButtons: true,
          isAutoStartEnabled: true,
          windowWidth: 800,
          windowHeight: 600,
          userId: 'user123',
          language: 'zh',
          themeMode: AppThemeMode.light,
          dailyStats: dailyStats,
          todos: todos,
        );

        expect(gameData.level, 5);
        expect(gameData.currentExp, 500);
        expect(gameData.isAlwaysOnTop, false);
        expect(gameData.isAntiSleepEnabled, true);
        expect(gameData.isAlwaysShowActionButtons, true);
        expect(gameData.isAutoStartEnabled, true);
        expect(gameData.windowWidth, 800);
        expect(gameData.windowHeight, 600);
        expect(gameData.userId, 'user123');
        expect(gameData.language, 'zh');
        expect(gameData.themeMode, AppThemeMode.light);
        expect(gameData.dailyStats.length, 1);
        expect(gameData.todos.length, 1);
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final gameData = GameData(
          level: 10,
          currentExp: 1000,
          isAlwaysOnTop: false,
          userId: 'test-user',
          language: 'en',
          themeMode: AppThemeMode.light,
        );

        final json = gameData.toJson();

        expect(json['level'], 10);
        expect(json['currentExp'], 1000);
        expect(json['isAlwaysOnTop'], false);
        expect(json['userId'], 'test-user');
        expect(json['language'], 'en');
        expect(json['themeMode'], 'light');
      });

      test('handles infinite currentExp', () {
        final gameData = GameData(
          level: 1,
          currentExp: double.infinity,
        );

        final json = gameData.toJson();

        expect(json['currentExp'], 0);
      });

      test('converts dailyStats to JSON', () {
        final gameData = GameData(
          level: 1,
          currentExp: 0,
          dailyStats: {
            '2024-01-15': DailyStats(keyboardCount: 50, mouseClickCount: 25),
          },
        );

        final json = gameData.toJson();
        final statsJson = json['dailyStats'] as Map<String, dynamic>;

        expect(statsJson.containsKey('2024-01-15'), isTrue);
        expect(statsJson['2024-01-15']['keyboardCount'], 50);
        expect(statsJson['2024-01-15']['mouseClickCount'], 25);
      });

      test('converts todos to JSON', () {
        final testDate = DateTime(2024, 1, 15);
        final gameData = GameData(
          level: 1,
          currentExp: 0,
          todos: [
            TodoItem(
              id: 'todo1',
              title: 'Test Todo',
              status: TodoStatus.doing,
              createdAt: testDate,
            ),
          ],
        );

        final json = gameData.toJson();
        final todosJson = json['todos'] as List<dynamic>;

        expect(todosJson.length, 1);
        expect(todosJson[0]['id'], 'todo1');
        expect(todosJson[0]['title'], 'Test Todo');
        expect(todosJson[0]['status'], 'doing');
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON', () {
        final json = {
          'level': 15,
          'currentExp': 2500,
          'isAlwaysOnTop': false,
          'isAntiSleepEnabled': true,
          'isAlwaysShowActionButtons': true,
          'isAutoStartEnabled': true,
          'windowWidth': 1024.0,
          'windowHeight': 768.0,
          'userId': 'json-user',
          'language': 'zh',
          'themeMode': 'light',
          'dailyStats': <String, dynamic>{},
          'todos': <dynamic>[],
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.level, 15);
        expect(gameData.currentExp, 2500);
        expect(gameData.isAlwaysOnTop, false);
        expect(gameData.isAntiSleepEnabled, true);
        expect(gameData.isAlwaysShowActionButtons, true);
        expect(gameData.isAutoStartEnabled, true);
        expect(gameData.windowWidth, 1024);
        expect(gameData.windowHeight, 768);
        expect(gameData.userId, 'json-user');
        expect(gameData.language, 'zh');
        expect(gameData.themeMode, AppThemeMode.light);
      });

      test('handles missing boolean fields with defaults', () {
        final json = {
          'level': 1,
          'currentExp': 0,
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.isAlwaysOnTop, true);
        expect(gameData.isAntiSleepEnabled, false);
        expect(gameData.isAlwaysShowActionButtons, false);
        expect(gameData.isAutoStartEnabled, false);
      });

      test('handles invalid themeMode with default dark', () {
        final json = {
          'level': 1,
          'currentExp': 0,
          'themeMode': 'invalid',
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.themeMode, AppThemeMode.dark);
      });

      test('handles null themeMode with default dark', () {
        final json = {
          'level': 1,
          'currentExp': 0,
          'themeMode': null,
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.themeMode, AppThemeMode.dark);
      });

      test('parses dailyStats from JSON', () {
        final json = {
          'level': 1,
          'currentExp': 0,
          'dailyStats': {
            '2024-01-15': {
              'keyboardCount': 100,
              'mouseClickCount': 50,
              'mouseMoveDistance': 1000,
            },
          },
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.dailyStats.containsKey('2024-01-15'), isTrue);
        expect(gameData.dailyStats['2024-01-15']!.keyboardCount, 100);
      });

      test('parses todos from JSON', () {
        final json = {
          'level': 1,
          'currentExp': 0,
          'todos': [
            {
              'id': 'todo1',
              'title': 'Test',
              'status': 'done',
              'createdAt': '2024-01-15T10:00:00.000',
            },
          ],
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.todos.length, 1);
        expect(gameData.todos[0].id, 'todo1');
        expect(gameData.todos[0].status, TodoStatus.done);
      });

      test('handles missing dailyStats and todos', () {
        final json = {
          'level': 1,
          'currentExp': 0,
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.dailyStats, isEmpty);
        expect(gameData.todos, isEmpty);
      });

      test('handles currentExp as int', () {
        final json = {
          'level': 1,
          'currentExp': 100,
        };

        final gameData = GameData.fromJson(json);

        expect(gameData.currentExp, 100.0);
      });
    });

    group('copyWith', () {
      test('copies with new level', () {
        final original = GameData(level: 1, currentExp: 0);
        final copied = original.copyWith(level: 10);

        expect(copied.level, 10);
        expect(copied.currentExp, 0);
      });

      test('copies with new currentExp', () {
        final original = GameData(level: 1, currentExp: 100);
        final copied = original.copyWith(currentExp: 500);

        expect(copied.currentExp, 500);
        expect(copied.level, 1);
      });

      test('copies with new themeMode', () {
        final original = GameData(
          level: 1,
          currentExp: 0,
          themeMode: AppThemeMode.dark,
        );
        final copied = original.copyWith(themeMode: AppThemeMode.light);

        expect(copied.themeMode, AppThemeMode.light);
      });

      test('copies with no changes preserves all values', () {
        final original = GameData(
          level: 5,
          currentExp: 250,
          isAlwaysOnTop: false,
          language: 'en',
        );
        final copied = original.copyWith();

        expect(copied.level, original.level);
        expect(copied.currentExp, original.currentExp);
        expect(copied.isAlwaysOnTop, original.isAlwaysOnTop);
        expect(copied.language, original.language);
      });

      test('copies with multiple new values', () {
        final original = GameData(level: 1, currentExp: 0);
        final copied = original.copyWith(
          level: 10,
          currentExp: 1000,
          isAlwaysOnTop: false,
          userId: 'new-user',
        );

        expect(copied.level, 10);
        expect(copied.currentExp, 1000);
        expect(copied.isAlwaysOnTop, false);
        expect(copied.userId, 'new-user');
      });
    });

    group('roundtrip', () {
      test('toJson and fromJson roundtrip preserves data', () {
        final testDate = DateTime(2024, 1, 15, 10, 0, 0);
        final original = GameData(
          level: 20,
          currentExp: 5000,
          isAlwaysOnTop: false,
          isAntiSleepEnabled: true,
          windowWidth: 800,
          windowHeight: 600,
          userId: 'roundtrip-user',
          language: 'zh',
          themeMode: AppThemeMode.light,
          dailyStats: {
            '2024-01-15': DailyStats(
              keyboardCount: 100,
              mouseClickCount: 50,
            ),
          },
          todos: [
            TodoItem(
              id: 'todo1',
              title: 'Test Todo',
              status: TodoStatus.doing,
              createdAt: testDate,
            ),
          ],
        );

        final json = original.toJson();
        final restored = GameData.fromJson(json);

        expect(restored.level, original.level);
        expect(restored.currentExp, original.currentExp);
        expect(restored.isAlwaysOnTop, original.isAlwaysOnTop);
        expect(restored.isAntiSleepEnabled, original.isAntiSleepEnabled);
        expect(restored.windowWidth, original.windowWidth);
        expect(restored.windowHeight, original.windowHeight);
        expect(restored.userId, original.userId);
        expect(restored.language, original.language);
        expect(restored.themeMode, original.themeMode);
        expect(restored.dailyStats.length, original.dailyStats.length);
        expect(restored.todos.length, original.todos.length);
        expect(restored.todos[0].id, original.todos[0].id);
      });
    });
  });
}
