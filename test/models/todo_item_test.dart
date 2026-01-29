import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/todo_item.dart';

void main() {
  group('TodoStatus', () {
    test('has correct values', () {
      expect(TodoStatus.values.length, 3);
      expect(TodoStatus.todo.name, 'todo');
      expect(TodoStatus.doing.name, 'doing');
      expect(TodoStatus.done.name, 'done');
    });
  });

  group('TodoItem', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);

    group('constructor', () {
      test('creates instance with required values', () {
        final todo = TodoItem(
          id: '123',
          title: 'Test Todo',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        expect(todo.id, '123');
        expect(todo.title, 'Test Todo');
        expect(todo.status, TodoStatus.todo);
        expect(todo.createdAt, testDate);
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final todo = TodoItem(
          id: 'test-id',
          title: 'My Todo',
          status: TodoStatus.doing,
          createdAt: testDate,
        );

        final json = todo.toJson();

        expect(json['id'], 'test-id');
        expect(json['title'], 'My Todo');
        expect(json['status'], 'doing');
        expect(json['createdAt'], testDate.toIso8601String());
      });

      test('converts all status types correctly', () {
        for (final status in TodoStatus.values) {
          final todo = TodoItem(
            id: '1',
            title: 'Test',
            status: status,
            createdAt: testDate,
          );

          final json = todo.toJson();
          expect(json['status'], status.name);
        }
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON', () {
        final json = {
          'id': 'json-id',
          'title': 'JSON Todo',
          'status': 'done',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.id, 'json-id');
        expect(todo.title, 'JSON Todo');
        expect(todo.status, TodoStatus.done);
        expect(todo.createdAt, DateTime(2024, 1, 15, 10, 30, 0));
      });

      test('handles missing status with default', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.status, TodoStatus.todo);
      });

      test('handles null status with default', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'status': null,
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.status, TodoStatus.todo);
      });

      test('handles invalid status with default', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'status': 'invalid_status',
          'createdAt': '2024-01-15T10:30:00.000',
        };

        final todo = TodoItem.fromJson(json);

        expect(todo.status, TodoStatus.todo);
      });

      test('handles missing createdAt with current time', () {
        final before = DateTime.now();
        final json = {
          'id': '1',
          'title': 'Test',
          'status': 'todo',
        };

        final todo = TodoItem.fromJson(json);
        final after = DateTime.now();

        expect(todo.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(todo.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('copyWith', () {
      test('copies with new title', () {
        final original = TodoItem(
          id: '1',
          title: 'Original',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        final copied = original.copyWith(title: 'Updated');

        expect(copied.id, '1');
        expect(copied.title, 'Updated');
        expect(copied.status, TodoStatus.todo);
        expect(copied.createdAt, testDate);
      });

      test('copies with new status', () {
        final original = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        final copied = original.copyWith(status: TodoStatus.done);

        expect(copied.id, '1');
        expect(copied.title, 'Test');
        expect(copied.status, TodoStatus.done);
        expect(copied.createdAt, testDate);
      });

      test('copies with no changes', () {
        final original = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.doing,
          createdAt: testDate,
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.title, original.title);
        expect(copied.status, original.status);
        expect(copied.createdAt, original.createdAt);
      });

      test('copies with both title and status', () {
        final original = TodoItem(
          id: '1',
          title: 'Original',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        final copied = original.copyWith(
          title: 'New Title',
          status: TodoStatus.done,
        );

        expect(copied.title, 'New Title');
        expect(copied.status, TodoStatus.done);
      });
    });

    group('cycleStatus', () {
      test('todo cycles to doing', () {
        final todo = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        final cycled = todo.cycleStatus();

        expect(cycled.status, TodoStatus.doing);
        expect(cycled.id, todo.id);
        expect(cycled.title, todo.title);
      });

      test('doing cycles to done', () {
        final todo = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.doing,
          createdAt: testDate,
        );

        final cycled = todo.cycleStatus();

        expect(cycled.status, TodoStatus.done);
      });

      test('done cycles back to todo', () {
        final todo = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.done,
          createdAt: testDate,
        );

        final cycled = todo.cycleStatus();

        expect(cycled.status, TodoStatus.todo);
      });

      test('full cycle returns to original status', () {
        final original = TodoItem(
          id: '1',
          title: 'Test',
          status: TodoStatus.todo,
          createdAt: testDate,
        );

        final cycled = original.cycleStatus().cycleStatus().cycleStatus();

        expect(cycled.status, TodoStatus.todo);
      });
    });

    group('roundtrip', () {
      test('toJson and fromJson roundtrip preserves data', () {
        final original = TodoItem(
          id: 'roundtrip-id',
          title: 'Roundtrip Todo',
          status: TodoStatus.doing,
          createdAt: testDate,
        );

        final json = original.toJson();
        final restored = TodoItem.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.status, original.status);
        expect(restored.createdAt, original.createdAt);
      });
    });
  });
}
