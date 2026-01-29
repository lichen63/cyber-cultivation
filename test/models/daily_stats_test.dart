import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/daily_stats.dart';

void main() {
  group('DailyStats', () {
    group('constructor', () {
      test('creates instance with default values', () {
        final stats = DailyStats();

        expect(stats.keyboardCount, 0);
        expect(stats.mouseClickCount, 0);
        expect(stats.mouseMoveDistance, 0);
      });

      test('creates instance with custom values', () {
        final stats = DailyStats(
          keyboardCount: 100,
          mouseClickCount: 50,
          mouseMoveDistance: 1000,
        );

        expect(stats.keyboardCount, 100);
        expect(stats.mouseClickCount, 50);
        expect(stats.mouseMoveDistance, 1000);
      });
    });

    group('toJson', () {
      test('converts to JSON correctly', () {
        final stats = DailyStats(
          keyboardCount: 150,
          mouseClickCount: 75,
          mouseMoveDistance: 2500,
        );

        final json = stats.toJson();

        expect(json['keyboardCount'], 150);
        expect(json['mouseClickCount'], 75);
        expect(json['mouseMoveDistance'], 2500);
      });

      test('handles zero values', () {
        final stats = DailyStats();
        final json = stats.toJson();

        expect(json['keyboardCount'], 0);
        expect(json['mouseClickCount'], 0);
        expect(json['mouseMoveDistance'], 0);
      });
    });

    group('fromJson', () {
      test('creates instance from valid JSON', () {
        final json = {
          'keyboardCount': 200,
          'mouseClickCount': 100,
          'mouseMoveDistance': 5000,
        };

        final stats = DailyStats.fromJson(json);

        expect(stats.keyboardCount, 200);
        expect(stats.mouseClickCount, 100);
        expect(stats.mouseMoveDistance, 5000);
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{};

        final stats = DailyStats.fromJson(json);

        expect(stats.keyboardCount, 0);
        expect(stats.mouseClickCount, 0);
        expect(stats.mouseMoveDistance, 0);
      });

      test('handles null values with defaults', () {
        final json = {
          'keyboardCount': null,
          'mouseClickCount': null,
          'mouseMoveDistance': null,
        };

        final stats = DailyStats.fromJson(json);

        expect(stats.keyboardCount, 0);
        expect(stats.mouseClickCount, 0);
        expect(stats.mouseMoveDistance, 0);
      });

      test('handles double mouseMoveDistance', () {
        final json = {
          'keyboardCount': 10,
          'mouseClickCount': 5,
          'mouseMoveDistance': 1234.56,
        };

        final stats = DailyStats.fromJson(json);

        expect(stats.mouseMoveDistance, 1234);
      });
    });

    group('roundtrip', () {
      test('toJson and fromJson roundtrip preserves data', () {
        final original = DailyStats(
          keyboardCount: 999,
          mouseClickCount: 888,
          mouseMoveDistance: 7777,
        );

        final json = original.toJson();
        final restored = DailyStats.fromJson(json);

        expect(restored.keyboardCount, original.keyboardCount);
        expect(restored.mouseClickCount, original.mouseClickCount);
        expect(restored.mouseMoveDistance, original.mouseMoveDistance);
      });
    });

    group('mutability', () {
      test('values can be modified', () {
        final stats = DailyStats();

        stats.keyboardCount = 10;
        stats.mouseClickCount = 20;
        stats.mouseMoveDistance = 30;

        expect(stats.keyboardCount, 10);
        expect(stats.mouseClickCount, 20);
        expect(stats.mouseMoveDistance, 30);
      });
    });

    group('edge cases', () {
      test('handles large values', () {
        final stats = DailyStats(
          keyboardCount: 999999999,
          mouseClickCount: 999999999,
          mouseMoveDistance: 999999999,
        );

        final json = stats.toJson();
        final restored = DailyStats.fromJson(json);

        expect(restored.keyboardCount, 999999999);
        expect(restored.mouseClickCount, 999999999);
        expect(restored.mouseMoveDistance, 999999999);
      });
    });
  });
}
