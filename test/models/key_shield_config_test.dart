import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/key_shield_config.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('KeyCombo', () {
    test('creates instance with required fields', () {
      const combo = KeyCombo(modifier: 'command', key: 'tab');
      expect(combo.modifier, 'command');
      expect(combo.key, 'tab');
    });

    test('serializes to JSON', () {
      const combo = KeyCombo(modifier: 'command', key: 'w');
      final json = combo.toJson();
      expect(json['modifier'], 'command');
      expect(json['key'], 'w');
    });

    test('deserializes from JSON', () {
      final combo = KeyCombo.fromJson({'modifier': 'option', 'key': 'space'});
      expect(combo.modifier, 'option');
      expect(combo.key, 'space');
    });

    test('deserializes from null fields with defaults', () {
      final combo = KeyCombo.fromJson({});
      expect(combo.modifier, 'command');
      expect(combo.key, 'tab');
    });

    test('equality works correctly', () {
      const combo1 = KeyCombo(modifier: 'command', key: 'tab');
      const combo2 = KeyCombo(modifier: 'command', key: 'tab');
      const combo3 = KeyCombo(modifier: 'option', key: 'tab');
      expect(combo1, equals(combo2));
      expect(combo1, isNot(equals(combo3)));
    });

    test('hashCode is consistent with equality', () {
      const combo1 = KeyCombo(modifier: 'command', key: 'tab');
      const combo2 = KeyCombo(modifier: 'command', key: 'tab');
      expect(combo1.hashCode, equals(combo2.hashCode));
    });

    test('toString returns readable format', () {
      const combo = KeyCombo(modifier: 'command', key: 'tab');
      expect(combo.toString(), '⌘+tab');
    });
  });

  group('AppKeyShieldRule', () {
    test('creates instance with defaults', () {
      const rule = AppKeyShieldRule(
        bundleId: 'com.test.app',
        appName: 'Test App',
      );
      expect(rule.bundleId, 'com.test.app');
      expect(rule.appName, 'Test App');
      expect(rule.autoActivate, true);
      expect(rule.blockedModifiers, isNull);
      expect(rule.allowedCombos, isNull);
      expect(rule.hasCustomRules, false);
    });

    test('hasCustomRules returns true when overrides set', () {
      const rule = AppKeyShieldRule(
        bundleId: 'com.test.app',
        appName: 'Test App',
        blockedModifiers: ['command'],
      );
      expect(rule.hasCustomRules, true);
    });

    test('serializes to JSON', () {
      const rule = AppKeyShieldRule(
        bundleId: 'com.test.app',
        appName: 'Test App',
        autoActivate: false,
        blockedModifiers: ['command', 'option'],
        allowedCombos: [KeyCombo(modifier: 'command', key: 'tab')],
      );
      final json = rule.toJson();
      expect(json['bundleId'], 'com.test.app');
      expect(json['appName'], 'Test App');
      expect(json['autoActivate'], false);
      expect(json['blockedModifiers'], ['command', 'option']);
      expect(json['allowedCombos'], isNotEmpty);
    });

    test('deserializes from JSON', () {
      final rule = AppKeyShieldRule.fromJson({
        'bundleId': 'com.valve.dota2',
        'appName': 'Dota 2',
        'autoActivate': true,
        'blockedModifiers': ['command'],
      });
      expect(rule.bundleId, 'com.valve.dota2');
      expect(rule.appName, 'Dota 2');
      expect(rule.autoActivate, true);
      expect(rule.blockedModifiers, ['command']);
      expect(rule.allowedCombos, isNull);
    });

    test('deserializes from empty JSON with defaults', () {
      final rule = AppKeyShieldRule.fromJson({});
      expect(rule.bundleId, '');
      expect(rule.appName, '');
      expect(rule.autoActivate, true);
    });

    test('copyWith creates modified copy', () {
      const original = AppKeyShieldRule(
        bundleId: 'com.test.app',
        appName: 'Test App',
        autoActivate: true,
      );
      final modified = original.copyWith(autoActivate: false);
      expect(modified.autoActivate, false);
      expect(modified.bundleId, 'com.test.app');
    });

    test('copyWith can clear overrides', () {
      const rule = AppKeyShieldRule(
        bundleId: 'com.test.app',
        appName: 'Test App',
        blockedModifiers: ['command'],
        allowedCombos: [KeyCombo(modifier: 'command', key: 'tab')],
      );
      final cleared = rule.copyWith(
        clearBlockedModifiers: true,
        clearAllowedCombos: true,
      );
      expect(cleared.blockedModifiers, isNull);
      expect(cleared.allowedCombos, isNull);
      expect(cleared.hasCustomRules, false);
    });
  });

  group('KeyShieldConfig', () {
    test('default constructor creates disabled config', () {
      const config = KeyShieldConfig();
      expect(config.isEnabled, false);
      expect(config.globalBlockedModifiers, isEmpty);
      expect(config.globalAllowedCombos, isEmpty);
      expect(config.appRules, isEmpty);
      expect(config.feedbackMode, KeyShieldConstants.feedbackNone);
    });

    test('serializes to JSON', () {
      const config = KeyShieldConfig(
        isEnabled: true,
        globalBlockedModifiers: ['command'],
        globalAllowedCombos: [KeyCombo(modifier: 'command', key: 'tab')],
        feedbackMode: KeyShieldConstants.feedbackSound,
      );
      final json = config.toJson();
      expect(json['isEnabled'], true);
      expect(json['globalBlockedModifiers'], ['command']);
      expect(json['globalAllowedCombos'], isNotEmpty);
      expect(json['feedbackMode'], 'sound');
    });

    test('deserializes from JSON', () {
      final config = KeyShieldConfig.fromJson({
        'isEnabled': true,
        'globalBlockedModifiers': ['command', 'option'],
        'globalAllowedCombos': [
          {'modifier': 'command', 'key': 'tab'},
          {'modifier': 'command', 'key': 'space'},
        ],
        'appRules': {
          'com.valve.dota2': {
            'bundleId': 'com.valve.dota2',
            'appName': 'Dota 2',
            'autoActivate': true,
          },
        },
        'feedbackMode': 'visual',
      });
      expect(config.isEnabled, true);
      expect(config.globalBlockedModifiers, ['command', 'option']);
      expect(config.globalAllowedCombos.length, 2);
      expect(config.appRules.length, 1);
      expect(config.appRules['com.valve.dota2']?.appName, 'Dota 2');
      expect(config.feedbackMode, 'visual');
    });

    test('deserializes from null JSON with defaults (backwards compat)', () {
      final config = KeyShieldConfig.fromJson(null);
      expect(config.isEnabled, false);
      expect(config.globalBlockedModifiers, isEmpty);
      expect(config.globalAllowedCombos, isEmpty);
      expect(config.appRules, isEmpty);
      expect(config.feedbackMode, KeyShieldConstants.feedbackNone);
    });

    test('deserializes from empty JSON with defaults', () {
      final config = KeyShieldConfig.fromJson({});
      expect(config.isEnabled, false);
      expect(config.globalBlockedModifiers, isEmpty);
    });

    test('effectiveBlockedModifiers returns per-app overrides when set', () {
      const config = KeyShieldConfig(
        globalBlockedModifiers: ['command', 'option'],
        appRules: {
          'com.valve.dota2': AppKeyShieldRule(
            bundleId: 'com.valve.dota2',
            appName: 'Dota 2',
            blockedModifiers: ['command'],
          ),
        },
      );
      expect(config.effectiveBlockedModifiers('com.valve.dota2'), ['command']);
    });

    test('effectiveBlockedModifiers falls back to global when no override', () {
      const config = KeyShieldConfig(
        globalBlockedModifiers: ['command', 'option'],
        appRules: {
          'com.valve.dota2': AppKeyShieldRule(
            bundleId: 'com.valve.dota2',
            appName: 'Dota 2',
          ),
        },
      );
      expect(config.effectiveBlockedModifiers('com.valve.dota2'), [
        'command',
        'option',
      ]);
    });

    test('effectiveAllowedCombos returns per-app overrides when set', () {
      const globalCombos = [KeyCombo(modifier: 'command', key: 'tab')];
      const appCombos = [KeyCombo(modifier: 'command', key: 'space')];
      const config = KeyShieldConfig(
        globalAllowedCombos: globalCombos,
        appRules: {
          'com.test.app': AppKeyShieldRule(
            bundleId: 'com.test.app',
            appName: 'Test',
            allowedCombos: appCombos,
          ),
        },
      );
      expect(config.effectiveAllowedCombos('com.test.app'), appCombos);
    });

    test('effectiveAllowedCombos falls back to global for unknown app', () {
      const globalCombos = [KeyCombo(modifier: 'command', key: 'tab')];
      const config = KeyShieldConfig(globalAllowedCombos: globalCombos);
      expect(config.effectiveAllowedCombos('com.unknown.app'), globalCombos);
    });

    test('copyWith creates modified copy', () {
      const config = KeyShieldConfig(isEnabled: false);
      final modified = config.copyWith(isEnabled: true);
      expect(modified.isEnabled, true);
      expect(modified.globalBlockedModifiers, isEmpty);
    });

    test('round-trip serialization preserves data', () {
      const original = KeyShieldConfig(
        isEnabled: true,
        globalBlockedModifiers: ['command', 'control'],
        globalAllowedCombos: [
          KeyCombo(modifier: 'command', key: 'tab'),
          KeyCombo(modifier: 'command', key: 'space'),
        ],
        appRules: {
          'com.valve.dota2': AppKeyShieldRule(
            bundleId: 'com.valve.dota2',
            appName: 'Dota 2',
            autoActivate: true,
            blockedModifiers: ['command'],
          ),
        },
        feedbackMode: 'sound',
      );
      final json = original.toJson();
      final restored = KeyShieldConfig.fromJson(json);

      expect(restored.isEnabled, original.isEnabled);
      expect(restored.globalBlockedModifiers, original.globalBlockedModifiers);
      expect(
        restored.globalAllowedCombos.length,
        original.globalAllowedCombos.length,
      );
      expect(restored.appRules.length, original.appRules.length);
      expect(restored.feedbackMode, original.feedbackMode);
      expect(restored.appRules['com.valve.dota2']?.appName, 'Dota 2');
      expect(restored.appRules['com.valve.dota2']?.blockedModifiers, [
        'command',
      ]);
    });
  });
}
