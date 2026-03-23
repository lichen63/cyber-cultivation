import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/services/key_shield_service.dart';

void main() {
  group('RunningApp', () {
    test('creates from map', () {
      final app = RunningApp.fromMap({
        'bundleId': 'com.valve.dota2',
        'name': 'Dota 2',
      });
      expect(app.bundleId, 'com.valve.dota2');
      expect(app.name, 'Dota 2');
    });

    test('creates from map with null values', () {
      final app = RunningApp.fromMap({});
      expect(app.bundleId, '');
      expect(app.name, '');
    });
  });

  group('KeyShieldStatus', () {
    test('creates from map', () {
      final status = KeyShieldStatus.fromMap({
        'isEnabled': true,
        'isActivelyBlocking': true,
        'frontmostBundleId': 'com.valve.dota2',
        'frontmostAppName': 'Dota 2',
      });
      expect(status.isEnabled, true);
      expect(status.isActivelyBlocking, true);
      expect(status.frontmostBundleId, 'com.valve.dota2');
      expect(status.frontmostAppName, 'Dota 2');
    });

    test('creates from empty map with defaults', () {
      final status = KeyShieldStatus.fromMap({});
      expect(status.isEnabled, false);
      expect(status.isActivelyBlocking, false);
      expect(status.frontmostBundleId, isNull);
      expect(status.frontmostAppName, isNull);
    });

    test('default constructor has correct defaults', () {
      const status = KeyShieldStatus();
      expect(status.isEnabled, false);
      expect(status.isActivelyBlocking, false);
      expect(status.frontmostBundleId, isNull);
      expect(status.frontmostAppName, isNull);
    });
  });
}
