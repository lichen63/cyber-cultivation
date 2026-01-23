import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/menu_bar_settings.dart';

void main() {
  group('MenuBarInfoType', () {
    test('contains battery type', () {
      expect(MenuBarInfoType.values.contains(MenuBarInfoType.battery), isTrue);
    });

    test('has all expected types', () {
      expect(MenuBarInfoType.values.length, 13);
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.trayIcon));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.focus));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.todo));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.levelExp));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.cpu));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.gpu));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.ram));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.disk));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.network));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.keyboard));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.mouse));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.systemTime));
      expect(MenuBarInfoType.values, contains(MenuBarInfoType.battery));
    });
  });

  group('MenuBarSettings', () {
    test('creates with default values', () {
      const settings = MenuBarSettings();

      expect(settings.showTrayIcon, isTrue);
      expect(settings.enabledInfoTypes, isEmpty);
    });

    test('toggleType adds battery type', () {
      const settings = MenuBarSettings();
      final updated = settings.toggleType(MenuBarInfoType.battery);

      expect(updated.isEnabled(MenuBarInfoType.battery), isTrue);
    });

    test('toggleType removes battery type', () {
      final settings = MenuBarSettings(
        enabledInfoTypes: {MenuBarInfoType.battery},
      );
      final updated = settings.toggleType(MenuBarInfoType.battery);

      expect(updated.isEnabled(MenuBarInfoType.battery), isFalse);
    });

    test('toJson and fromJson round trip with battery', () {
      final settings = MenuBarSettings(
        enabledInfoTypes: {MenuBarInfoType.battery, MenuBarInfoType.cpu},
      );

      final json = settings.toJson();
      final restored = MenuBarSettings.fromJson(json);

      expect(restored.isEnabled(MenuBarInfoType.battery), isTrue);
      expect(restored.isEnabled(MenuBarInfoType.cpu), isTrue);
    });
  });
}
