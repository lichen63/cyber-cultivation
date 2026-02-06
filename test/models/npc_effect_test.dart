import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_cultivation/models/npc_effect.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  group('NpcEffect', () {
    test('creates instance with required values', () {
      final effect = NpcEffect(
        type: NpcEffectType.expMultiplier,
        isPositive: true,
        remainingBattles: 3,
      );
      expect(effect.type, NpcEffectType.expMultiplier);
      expect(effect.isPositive, true);
      expect(effect.remainingBattles, 3);
      expect(effect.storedValue, 0.0);
    });

    test('isExpired returns true when duration-based effect has 0 remaining', () {
      final effect = NpcEffect(
        type: NpcEffectType.expMultiplier,
        isPositive: true,
        remainingBattles: 0,
      );
      expect(effect.isExpired, true);
    });

    test('isExpired returns false when duration-based effect has charges', () {
      final effect = NpcEffect(
        type: NpcEffectType.expMultiplier,
        isPositive: true,
        remainingBattles: 2,
      );
      expect(effect.isExpired, false);
    });

    test('consumeBattle decrements remaining battles', () {
      final effect = NpcEffect(
        type: NpcEffectType.expInsurance,
        isPositive: true,
        remainingBattles: 1,
      );
      effect.consumeBattle();
      expect(effect.remainingBattles, 0);
      expect(effect.isExpired, true);
    });

    test('consumeBattle does not go below 0', () {
      final effect = NpcEffect(
        type: NpcEffectType.expFloor,
        isPositive: true,
        remainingBattles: 0,
      );
      effect.consumeBattle();
      expect(effect.remainingBattles, 0);
    });

    test('instant effects are not considered expired', () {
      final effect = NpcEffect(
        type: NpcEffectType.expGiftSteal,
        isPositive: true,
      );
      // Instant effects don't have duration, so isExpired should be false
      expect(effect.isExpired, false);
    });

    group('serialization', () {
      test('toJson and fromJson roundtrip', () {
        final effect = NpcEffect(
          type: NpcEffectType.expFloor,
          isPositive: false,
          remainingBattles: 2,
          storedValue: 150.5,
        );
        final json = effect.toJson();
        final restored = NpcEffect.fromJson(json);

        expect(restored.type, NpcEffectType.expFloor);
        expect(restored.isPositive, false);
        expect(restored.remainingBattles, 2);
        expect(restored.storedValue, 150.5);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'type': NpcEffectType.expGamble.index,
          'isPositive': true,
        };
        final effect = NpcEffect.fromJson(json);
        expect(effect.remainingBattles, 0);
        expect(effect.storedValue, 0.0);
      });
    });
  });

  group('NpcEffectService', () {
    late NpcEffectService service;

    setUp(() {
      service = NpcEffectService(random: Random(42));
    });

    test('generateEffect returns valid effect', () {
      final effect = service.generateEffect(
        currentExp: 50.0,
        maxExp: 100.0,
      );
      expect(NpcEffectType.values.contains(effect.type), true);
    });

    test('generateEffect sets correct duration for multiplier', () {
      // Generate many effects and check multipliers have correct duration
      final testService = NpcEffectService(random: Random(42));
      var found = false;
      for (int i = 0; i < 100; i++) {
        final effect = testService.generateEffect(
          currentExp: 50.0,
          maxExp: 100.0,
        );
        if (effect.type == NpcEffectType.expMultiplier) {
          expect(
            effect.remainingBattles,
            NpcEffectConstants.multiplierDurationBattles,
          );
          found = true;
          break;
        }
      }
      expect(found, true, reason: 'Should find at least one multiplier effect');
    });

    group('calculateImmediateExpChange', () {
      test('positive gift returns positive change', () {
        final effect = NpcEffect(
          type: NpcEffectType.expGiftSteal,
          isPositive: true,
        );
        final change = service.calculateImmediateExpChange(
          effect,
          50.0,
          100.0,
        );
        expect(change, greaterThan(0));
        expect(change, lessThanOrEqualTo(10.0)); // max 10% of 100
        expect(change, greaterThanOrEqualTo(5.0)); // min 5% of 100
      });

      test('negative steal returns negative change', () {
        final effect = NpcEffect(
          type: NpcEffectType.expGiftSteal,
          isPositive: false,
        );
        final change = service.calculateImmediateExpChange(
          effect,
          50.0,
          100.0,
        );
        expect(change, lessThan(0));
        expect(change, greaterThanOrEqualTo(-10.0));
        expect(change, lessThanOrEqualTo(-5.0));
      });

      test('positive gamble doubles exp', () {
        final effect = NpcEffect(
          type: NpcEffectType.expGamble,
          isPositive: true,
        );
        final change = service.calculateImmediateExpChange(
          effect,
          50.0,
          100.0,
        );
        expect(change, 50.0); // gain = current exp
      });

      test('negative gamble halves exp', () {
        final effect = NpcEffect(
          type: NpcEffectType.expGamble,
          isPositive: false,
        );
        final change = service.calculateImmediateExpChange(
          effect,
          50.0,
          100.0,
        );
        expect(change, -25.0); // lose half
      });

      test('duration-based effects return 0 immediate change', () {
        for (final type in [
          NpcEffectType.expMultiplier,
          NpcEffectType.expInsurance,
          NpcEffectType.expFloor,
        ]) {
          final effect = NpcEffect(type: type, isPositive: true);
          final change = service.calculateImmediateExpChange(
            effect,
            50.0,
            100.0,
          );
          expect(change, 0.0, reason: '$type should have 0 immediate change');
        }
      });
    });

    group('applyBattleEffects', () {
      test('positive multiplier doubles EXP reward', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expMultiplier,
            isPositive: true,
            remainingBattles: 3,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 20.0);
      });

      test('negative multiplier halves EXP', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expMultiplier,
            isPositive: false,
            remainingBattles: 3,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 5.0);
      });

      test('positive insurance negates loss penalty', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expInsurance,
            isPositive: true,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: -5.0,
          isVictory: false,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 0.0);
      });

      test('negative insurance negates win reward', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expInsurance,
            isPositive: false,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 0.0);
      });

      test('positive floor prevents EXP from dropping below stored value', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expFloor,
            isPositive: true,
            remainingBattles: 3,
            storedValue: 50.0,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: -10.0,
          isVictory: false,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 0.0); // Can't drop below 50
      });

      test('negative floor prevents EXP from going above stored value', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expFloor,
            isPositive: false,
            remainingBattles: 3,
            storedValue: 50.0,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 0.0); // Can't go above 50
      });

      test('expired effects are not applied', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expMultiplier,
            isPositive: true,
            remainingBattles: 0, // Expired
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          activeEffects: effects,
        );
        expect(result, 10.0); // No modification
      });
    });

    group('consumeBattleCharges', () {
      test('decrements all duration-based effects', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expMultiplier,
            isPositive: true,
            remainingBattles: 3,
          ),
          NpcEffect(
            type: NpcEffectType.expInsurance,
            isPositive: false,
            remainingBattles: 1,
          ),
        ];
        service.consumeBattleCharges(effects);
        expect(effects[0].remainingBattles, 2);
        // Insurance should be removed (expired)
        expect(effects.length, 1);
      });

      test('removes expired effects after consuming', () {
        final effects = [
          NpcEffect(
            type: NpcEffectType.expFloor,
            isPositive: true,
            remainingBattles: 1,
            storedValue: 50.0,
          ),
        ];
        service.consumeBattleCharges(effects);
        expect(effects.isEmpty, true);
      });
    });
  });
}
