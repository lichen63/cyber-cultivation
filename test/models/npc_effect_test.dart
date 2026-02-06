import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_cultivation/l10n/app_localizations.dart';
import 'package:cyber_cultivation/models/npc_effect.dart';
import 'package:cyber_cultivation/models/explore_map.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  setUp(() {
    // Ensure registry is initialized before each test group
    NpcEffectRegistry.clear();
    NpcEffectRegistry.initialize();
  });

  group('NpcEffectRegistry', () {
    test('initializes with 5 built-in definitions', () {
      expect(NpcEffectRegistry.count, 5);
    });

    test('can look up each definition by typeId', () {
      expect(NpcEffectRegistry.get('exp_gift_steal'), isNotNull);
      expect(NpcEffectRegistry.get('exp_multiplier'), isNotNull);
      expect(NpcEffectRegistry.get('exp_insurance'), isNotNull);
      expect(NpcEffectRegistry.get('exp_floor'), isNotNull);
      expect(NpcEffectRegistry.get('exp_gamble'), isNotNull);
    });

    test('returns null for unknown typeId', () {
      expect(NpcEffectRegistry.get('unknown_effect'), isNull);
    });

    test('all definitions have unique typeIds', () {
      final typeIds = NpcEffectRegistry.all.map((d) => d.typeId).toSet();
      expect(typeIds.length, NpcEffectRegistry.count);
    });

    test('clear removes all definitions', () {
      NpcEffectRegistry.clear();
      expect(NpcEffectRegistry.count, 0);
      // Re-initialize for subsequent tests
      NpcEffectRegistry.initialize();
    });

    test('initialize is idempotent', () {
      NpcEffectRegistry.initialize();
      NpcEffectRegistry.initialize();
      expect(NpcEffectRegistry.count, 5);
    });

    test('custom definition can be registered', () {
      final initialCount = NpcEffectRegistry.count;
      NpcEffectRegistry.register(_TestEffectDefinition());
      expect(NpcEffectRegistry.count, initialCount + 1);
      expect(NpcEffectRegistry.get('test_effect'), isNotNull);
    });
  });

  group('NpcEffectDefinition properties', () {
    test('gift/steal and gamble are immediate', () {
      expect(NpcEffectRegistry.get('exp_gift_steal')!.isImmediate, true);
      expect(NpcEffectRegistry.get('exp_gamble')!.isImmediate, true);
    });

    test('multiplier, insurance, floor are duration-based', () {
      expect(NpcEffectRegistry.get('exp_multiplier')!.isImmediate, false);
      expect(NpcEffectRegistry.get('exp_insurance')!.isImmediate, false);
      expect(NpcEffectRegistry.get('exp_floor')!.isImmediate, false);
    });

    test('built-in definitions use correct durationType', () {
      expect(
        NpcEffectRegistry.get('exp_gift_steal')!.durationType,
        EffectDurationType.instant,
      );
      expect(
        NpcEffectRegistry.get('exp_gamble')!.durationType,
        EffectDurationType.instant,
      );
      expect(
        NpcEffectRegistry.get('exp_multiplier')!.durationType,
        EffectDurationType.battles,
      );
      expect(
        NpcEffectRegistry.get('exp_insurance')!.durationType,
        EffectDurationType.battles,
      );
      expect(
        NpcEffectRegistry.get('exp_floor')!.durationType,
        EffectDurationType.battles,
      );
    });

    test('default hooks are no-ops', () {
      final def = NpcEffectRegistry.get('exp_gift_steal')!;
      final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);

      // FC hooks
      expect(def.modifyPlayerFC(effect, 100.0), 100.0);
      expect(def.modifyEnemyFC(effect, 80.0, ExploreCellType.monster), 80.0);
      // Battle outcome
      expect(
        def.overrideBattleOutcome(effect, 100.0, 80.0, ExploreCellType.monster),
        isNull,
      );
      // Flee
      expect(def.modifyFleeChance(effect, 0.5), 0.5);
      // FOV
      expect(def.modifyFovRadius(effect, 3), 3);
      // House
      expect(def.modifyHouseRestore(effect, 10), 10);
      // AP cost
      expect(def.modifyAPCost(effect, 5, 'move'), 5);
      // NPC chain
      final other = NpcEffect(typeId: 'exp_gamble', isPositive: false);
      expect(def.modifyNextNpcEffect(effect, other), same(other));
    });
  });

  group('NpcEffect', () {
    test('creates instance with required values', () {
      final effect = NpcEffect(
        typeId: 'exp_multiplier',
        isPositive: true,
        remainingBattles: 3,
      );
      expect(effect.typeId, 'exp_multiplier');
      expect(effect.isPositive, true);
      expect(effect.remainingBattles, 3);
      expect(effect.storedValue, 0.0);
      expect(effect.data, isEmpty);
      expect(effect.durationType, EffectDurationType.battles);
    });

    test('durationType is inferred from registry', () {
      final instant = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);
      expect(instant.durationType, EffectDurationType.instant);

      final battles = NpcEffect(typeId: 'exp_multiplier', isPositive: true);
      expect(battles.durationType, EffectDurationType.battles);

      NpcEffectRegistry.register(_MoveDurationTestDefinition());
      final moves = NpcEffect(typeId: 'test_move_effect', isPositive: true);
      expect(moves.durationType, EffectDurationType.moves);
    });

    test('durationType defaults to instant for unknown typeId', () {
      final unknown = NpcEffect(typeId: 'nonexistent_effect', isPositive: true);
      expect(unknown.durationType, EffectDurationType.instant);
    });

    test('creates instance with data map', () {
      final effect = NpcEffect(
        typeId: 'exp_floor',
        isPositive: true,
        remainingBattles: 3,
        data: {'storedValue': 150.5},
      );
      expect(effect.storedValue, 150.5);
      expect(effect.data['storedValue'], 150.5);
    });

    test(
      'isExpired returns true when duration-based effect has 0 remaining',
      () {
        final effect = NpcEffect(
          typeId: 'exp_multiplier',
          isPositive: true,
          remainingBattles: 0,
        );
        expect(effect.isExpired, true);
      },
    );

    test('isExpired returns false when duration-based effect has charges', () {
      final effect = NpcEffect(
        typeId: 'exp_multiplier',
        isPositive: true,
        remainingBattles: 2,
      );
      expect(effect.isExpired, false);
    });

    test('isDurationBased is true for multiplier/insurance/floor', () {
      expect(
        NpcEffect(typeId: 'exp_multiplier', isPositive: true).isDurationBased,
        true,
      );
      expect(
        NpcEffect(typeId: 'exp_insurance', isPositive: true).isDurationBased,
        true,
      );
      expect(
        NpcEffect(typeId: 'exp_floor', isPositive: true).isDurationBased,
        true,
      );
    });

    test('isDurationBased is false for gift_steal/gamble', () {
      expect(
        NpcEffect(typeId: 'exp_gift_steal', isPositive: true).isDurationBased,
        false,
      );
      expect(
        NpcEffect(typeId: 'exp_gamble', isPositive: true).isDurationBased,
        false,
      );
    });

    test('consumeBattle decrements remaining battles', () {
      final effect = NpcEffect(
        typeId: 'exp_insurance',
        isPositive: true,
        remainingBattles: 1,
      );
      effect.consumeBattle();
      expect(effect.remainingBattles, 0);
      expect(effect.isExpired, true);
    });

    test('consumeBattle does not go below 0', () {
      final effect = NpcEffect(
        typeId: 'exp_floor',
        isPositive: true,
        remainingBattles: 0,
      );
      effect.consumeBattle();
      expect(effect.remainingBattles, 0);
    });

    test('remainingMoves defaults to 0', () {
      final effect = NpcEffect(typeId: 'exp_multiplier', isPositive: true);
      expect(effect.remainingMoves, 0);
    });

    test('consumeMove is a no-op for battle-duration effects', () {
      final effect = NpcEffect(
        typeId: 'exp_multiplier',
        isPositive: true,
        remainingBattles: 3,
        remainingMoves: 0,
      );
      effect.consumeMove();
      expect(effect.remainingBattles, 3);
      expect(effect.remainingMoves, 0);
    });

    test('consumeBattle is a no-op for move-duration effects', () {
      // Register a move-duration test definition
      NpcEffectRegistry.register(_MoveDurationTestDefinition());
      final effect = NpcEffect(
        typeId: 'test_move_effect',
        isPositive: true,
        remainingMoves: 5,
        remainingBattles: 0,
      );
      effect.consumeBattle();
      expect(effect.remainingMoves, 5);
      expect(effect.remainingBattles, 0);
    });

    test('consumeMove decrements for move-duration effects', () {
      NpcEffectRegistry.register(_MoveDurationTestDefinition());
      final effect = NpcEffect(
        typeId: 'test_move_effect',
        isPositive: true,
        remainingMoves: 3,
      );
      effect.consumeMove();
      expect(effect.remainingMoves, 2);
    });

    test('move-duration effect expires when moves reach 0', () {
      NpcEffectRegistry.register(_MoveDurationTestDefinition());
      final effect = NpcEffect(
        typeId: 'test_move_effect',
        isPositive: true,
        remainingMoves: 1,
      );
      expect(effect.isExpired, false);
      effect.consumeMove();
      expect(effect.remainingMoves, 0);
      expect(effect.isExpired, true);
    });

    test('instant effects are not considered expired', () {
      final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);
      expect(effect.isExpired, false);
    });

    group('serialization', () {
      test('toJson uses new format with typeId and data', () {
        final effect = NpcEffect(
          typeId: 'exp_floor',
          isPositive: false,
          remainingBattles: 2,
          data: {'storedValue': 150.5},
        );
        final json = effect.toJson();
        expect(json['typeId'], 'exp_floor');
        expect(json['isPositive'], false);
        expect(json['remainingBattles'], 2);
        expect(json['remainingMoves'], 0);
        expect(json['data']['storedValue'], 150.5);
        // Ensure old 'type' key is not present
        expect(json.containsKey('type'), false);
      });

      test('toJson and fromJson roundtrip', () {
        final effect = NpcEffect(
          typeId: 'exp_floor',
          isPositive: false,
          remainingBattles: 2,
          remainingMoves: 5,
          data: {'storedValue': 150.5},
        );
        final json = effect.toJson();
        final restored = NpcEffect.fromJson(json);

        expect(restored.typeId, 'exp_floor');
        expect(restored.isPositive, false);
        expect(restored.remainingBattles, 2);
        expect(restored.remainingMoves, 5);
        expect(restored.storedValue, 150.5);
      });

      test('fromJson handles missing optional fields', () {
        final json = {'typeId': 'exp_gamble', 'isPositive': true};
        final effect = NpcEffect.fromJson(json);
        expect(effect.remainingBattles, 0);
        expect(effect.storedValue, 0.0);
        expect(effect.data, isEmpty);
      });

      test('fromJson migrates legacy int-based type', () {
        // Legacy format with int 'type' key
        final legacyJson = {
          'type': 0, // expGiftSteal
          'isPositive': true,
          'remainingBattles': 0,
          'storedValue': 0.0,
        };
        final effect = NpcEffect.fromJson(legacyJson);
        expect(effect.typeId, 'exp_gift_steal');
        expect(effect.isPositive, true);
      });

      test('fromJson migrates all legacy type indices', () {
        final legacyMap = {
          0: 'exp_gift_steal',
          1: 'exp_multiplier',
          2: 'exp_insurance',
          3: 'exp_floor',
          4: 'exp_gamble',
        };
        for (final entry in legacyMap.entries) {
          final json = {'type': entry.key, 'isPositive': true};
          final effect = NpcEffect.fromJson(json);
          expect(
            effect.typeId,
            entry.value,
            reason: 'Legacy index ${entry.key} should map to ${entry.value}',
          );
        }
      });

      test('fromJson migrates legacy storedValue to data map', () {
        final legacyJson = {
          'type': 3, // expFloor
          'isPositive': true,
          'remainingBattles': 3,
          'storedValue': 200.0,
        };
        final effect = NpcEffect.fromJson(legacyJson);
        expect(effect.typeId, 'exp_floor');
        expect(effect.storedValue, 200.0);
        expect(effect.data['storedValue'], 200.0);
      });

      test('fromJson ignores zero storedValue in legacy migration', () {
        final legacyJson = {'type': 0, 'isPositive': true, 'storedValue': 0.0};
        final effect = NpcEffect.fromJson(legacyJson);
        expect(effect.data, isEmpty);
      });
    });
  });

  group('NpcEffectService', () {
    late NpcEffectService service;

    setUp(() {
      service = NpcEffectService(random: Random(42));
    });

    test('generateEffect returns valid effect', () {
      final effect = service.generateEffect(currentExp: 50.0, maxExp: 100.0);
      expect(NpcEffectRegistry.get(effect.typeId), isNotNull);
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
        if (effect.typeId == 'exp_multiplier') {
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
        final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);
        final change = service.calculateImmediateExpChange(effect, 50.0, 100.0);
        expect(change, greaterThan(0));
        expect(change, lessThanOrEqualTo(10.0)); // max 10% of 100
        expect(change, greaterThanOrEqualTo(5.0)); // min 5% of 100
      });

      test('negative steal returns negative change', () {
        final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: false);
        final change = service.calculateImmediateExpChange(effect, 50.0, 100.0);
        expect(change, lessThan(0));
        expect(change, greaterThanOrEqualTo(-10.0));
        expect(change, lessThanOrEqualTo(-5.0));
      });

      test('positive gamble doubles exp', () {
        final effect = NpcEffect(typeId: 'exp_gamble', isPositive: true);
        final change = service.calculateImmediateExpChange(effect, 50.0, 100.0);
        expect(change, 50.0); // gain = current exp
      });

      test('negative gamble halves exp', () {
        final effect = NpcEffect(typeId: 'exp_gamble', isPositive: false);
        final change = service.calculateImmediateExpChange(effect, 50.0, 100.0);
        expect(change, -25.0); // lose half
      });

      test('duration-based effects return 0 immediate change', () {
        for (final typeId in ['exp_multiplier', 'exp_insurance', 'exp_floor']) {
          final effect = NpcEffect(typeId: typeId, isPositive: true);
          final change = service.calculateImmediateExpChange(
            effect,
            50.0,
            100.0,
          );
          expect(change, 0.0, reason: '$typeId should have 0 immediate change');
        }
      });

      test('unknown effect type returns 0', () {
        final effect = NpcEffect(typeId: 'nonexistent', isPositive: true);
        final change = service.calculateImmediateExpChange(effect, 50.0, 100.0);
        expect(change, 0.0);
      });
    });

    group('applyBattleEffects', () {
      test('positive multiplier doubles EXP reward', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 3,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 20.0);
      });

      test('negative multiplier halves EXP', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: false,
            remainingBattles: 3,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 5.0);
      });

      test('positive insurance negates loss penalty', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_insurance',
            isPositive: true,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: -5.0,
          isVictory: false,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 0.0);
      });

      test('negative insurance negates win reward', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_insurance',
            isPositive: false,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 0.0);
      });

      test('positive insurance does not affect wins', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_insurance',
            isPositive: true,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 10.0);
      });

      test('negative insurance does not affect losses', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_insurance',
            isPositive: false,
            remainingBattles: 1,
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: -5.0,
          isVictory: false,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, -5.0);
      });

      test('positive floor prevents EXP from dropping below stored value', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_floor',
            isPositive: true,
            remainingBattles: 3,
            data: {'storedValue': 50.0},
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: -10.0,
          isVictory: false,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 0.0); // Can't drop below 50
      });

      test('negative floor prevents EXP from going above stored value', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_floor',
            isPositive: false,
            remainingBattles: 3,
            data: {'storedValue': 50.0},
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 0.0); // Can't go above 50
      });

      test('positive floor allows gain above stored value', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_floor',
            isPositive: true,
            remainingBattles: 3,
            data: {'storedValue': 50.0},
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 10.0); // Can go above 50
      });

      test('expired effects are not applied', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 0, // Expired
          ),
        ];
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 10.0); // No modification
      });

      test('multiple effects are applied in sequence', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 3,
          ),
          NpcEffect(
            typeId: 'exp_floor',
            isPositive: false,
            remainingBattles: 3,
            data: {'storedValue': 55.0},
          ),
        ];
        // Base 10.0 → multiplied by 2 → 20.0
        // Floor ceiling at 55.0, current 50.0 → 20.0 would make 70 > 55,
        // so clamped to 55 - 50 = 5.0
        final result = service.applyBattleEffects(
          baseExpChange: 10.0,
          isVictory: true,
          currentExp: 50.0,
          cellType: ExploreCellType.monster,
          activeEffects: effects,
        );
        expect(result, 5.0);
      });
    });

    group('consumeBattleCharges', () {
      test('decrements all duration-based effects', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 3,
          ),
          NpcEffect(
            typeId: 'exp_insurance',
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
            typeId: 'exp_floor',
            isPositive: true,
            remainingBattles: 1,
            data: {'storedValue': 50.0},
          ),
        ];
        service.consumeBattleCharges(effects);
        expect(effects.isEmpty, true);
      });

      test('does not decrement instant effects', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_gift_steal',
            isPositive: true,
            remainingBattles: 0,
          ),
        ];
        service.consumeBattleCharges(effects);
        expect(effects[0].remainingBattles, 0);
        // Instant effects are not expired so they stay
        expect(effects.length, 1);
      });
    });

    group('consumeMoveCharges', () {
      test('decrements move-duration effects and removes expired', () {
        NpcEffectRegistry.register(_MoveDurationTestDefinition());
        final effects = [
          NpcEffect(
            typeId: 'test_move_effect',
            isPositive: true,
            remainingMoves: 1,
          ),
        ];
        final map = ExploreMap(
          grid: [],
          width: 5,
          height: 5,
          playerX: 2,
          playerY: 2,
          generatedAtLevel: 1,
          generatedAtExp: 0.0,
        );
        service.consumeMoveCharges(effects, map);
        expect(effects.isEmpty, true); // 1→0 = expired
      });

      test('does not decrement battle-duration effects', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 3,
          ),
        ];
        final map = ExploreMap(
          grid: [],
          width: 5,
          height: 5,
          playerX: 2,
          playerY: 2,
          generatedAtLevel: 1,
          generatedAtExp: 0.0,
        );
        service.consumeMoveCharges(effects, map);
        expect(effects[0].remainingBattles, 3);
        expect(effects.length, 1);
      });
    });

    group('FC modifier orchestration', () {
      test('applyPlayerFCModifiers returns base when no effects', () {
        final result = service.applyPlayerFCModifiers(100.0, []);
        expect(result, 100.0);
      });

      test('applyPlayerFCModifiers skips expired effects', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 0,
          ),
        ];
        final result = service.applyPlayerFCModifiers(100.0, effects);
        expect(result, 100.0);
      });

      test('applyEnemyFCModifiers returns base when no effects', () {
        final result = service.applyEnemyFCModifiers(
          80.0,
          ExploreCellType.monster,
          [],
        );
        expect(result, 80.0);
      });
    });

    group('battle outcome override', () {
      test('getOutcomeOverride returns null when no active overrides', () {
        final result = service.getOutcomeOverride(
          100.0,
          80.0,
          ExploreCellType.monster,
          [],
        );
        expect(result, isNull);
      });

      test('getOutcomeOverride skips expired effects', () {
        final effects = [
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 0,
          ),
        ];
        final result = service.getOutcomeOverride(
          100.0,
          80.0,
          ExploreCellType.monster,
          effects,
        );
        expect(result, isNull);
      });
    });

    group('flee modifier orchestration', () {
      test('applyFleeModifiers returns base when no effects', () {
        final result = service.applyFleeModifiers(0.5, []);
        expect(result, 0.5);
      });

      test('applyFleeModifiers clamps result to 0-1', () {
        // Even with no effects modifying, verify clamping works
        final result = service.applyFleeModifiers(0.7, []);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      });
    });

    group('FOV modifier orchestration', () {
      test('applyFovModifiers returns base when no effects', () {
        final result = service.applyFovModifiers(3, []);
        expect(result, 3);
      });

      test('applyFovModifiers guarantees minimum of 1', () {
        final result = service.applyFovModifiers(1, []);
        expect(result, greaterThanOrEqualTo(1));
      });
    });

    group('house restore modifier orchestration', () {
      test('applyHouseRestoreModifiers returns base when no effects', () {
        final result = service.applyHouseRestoreModifiers(10, []);
        expect(result, 10);
      });
    });

    group('map effects orchestration', () {
      test('applyMapEffects does not throw for unknown typeId', () {
        final effect = NpcEffect(typeId: 'nonexistent', isPositive: true);
        final map = ExploreMap(
          grid: [],
          width: 5,
          height: 5,
          playerX: 2,
          playerY: 2,
          generatedAtLevel: 1,
          generatedAtExp: 0.0,
        );
        // Should not throw
        service.applyMapEffects(effect, map);
      });
    });

    group('NPC chain generation', () {
      test('generateEffect passes activeEffects for chain modification', () {
        final activeEffects = <NpcEffect>[
          NpcEffect(
            typeId: 'exp_multiplier',
            isPositive: true,
            remainingBattles: 3,
          ),
        ];
        // Should not throw — chain modifiers are no-ops for built-in effects
        final effect = service.generateEffect(
          currentExp: 50.0,
          maxExp: 100.0,
          activeEffects: activeEffects,
        );
        expect(NpcEffectRegistry.get(effect.typeId), isNotNull);
      });
    });
  });

  group('Concrete definitions', () {
    test('ExpGiftStealDefinition generates correct effect', () {
      final def = ExpGiftStealDefinition();
      final effect = def.generate(Random(42), 50.0, 100.0);
      expect(effect.typeId, 'exp_gift_steal');
      expect(effect.remainingBattles, 0);
    });

    test('ExpMultiplierDefinition generates correct duration', () {
      final def = ExpMultiplierDefinition();
      final effect = def.generate(Random(42), 50.0, 100.0);
      expect(effect.typeId, 'exp_multiplier');
      expect(
        effect.remainingBattles,
        NpcEffectConstants.multiplierDurationBattles,
      );
    });

    test('ExpInsuranceDefinition generates correct duration', () {
      final def = ExpInsuranceDefinition();
      final effect = def.generate(Random(42), 50.0, 100.0);
      expect(effect.typeId, 'exp_insurance');
      expect(
        effect.remainingBattles,
        NpcEffectConstants.insuranceDurationBattles,
      );
    });

    test('ExpFloorDefinition stores current EXP', () {
      final def = ExpFloorDefinition();
      final effect = def.generate(Random(42), 75.0, 100.0);
      expect(effect.typeId, 'exp_floor');
      expect(effect.storedValue, 75.0);
      expect(effect.remainingBattles, NpcEffectConstants.floorDurationBattles);
    });

    test('ExpGambleDefinition generates correct effect', () {
      final def = ExpGambleDefinition();
      final effect = def.generate(Random(42), 50.0, 100.0);
      expect(effect.typeId, 'exp_gamble');
      expect(effect.remainingBattles, 0);
    });

    test('applyBattle returns baseExpChange for immediate definitions', () {
      final giftStealDef = NpcEffectRegistry.get('exp_gift_steal')!;
      final gambleDef = NpcEffectRegistry.get('exp_gamble')!;
      final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);

      expect(
        giftStealDef.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        ),
        10.0,
      );
      expect(
        gambleDef.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        ),
        10.0,
      );
    });
  });

  // ── Tests for bug fixes (M, N, O) ───────────────────────────────────

  group('NpcEffectRegistry initialize guard (fix M)', () {
    test(
      'custom effect registered before initialize does not block built-ins',
      () {
        NpcEffectRegistry.clear();
        // Register a custom effect FIRST
        NpcEffectRegistry.register(_TestEffectDefinition());
        expect(NpcEffectRegistry.count, 1);
        expect(NpcEffectRegistry.get('test_effect'), isNotNull);

        // Now initialize — built-in effects should still register
        NpcEffectRegistry.initialize();
        expect(NpcEffectRegistry.count, 6); // 5 built-in + 1 custom
        expect(NpcEffectRegistry.get('exp_gift_steal'), isNotNull);
        expect(NpcEffectRegistry.get('exp_multiplier'), isNotNull);
      },
    );
  });

  group('FOV and house restore modifier tests (fix N)', () {
    late NpcEffectService service;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      NpcEffectRegistry.register(_FovModifyingDefinition());
      NpcEffectRegistry.register(_HouseRestoreModifyingDefinition());
      service = NpcEffectService(random: Random(42));
    });

    test('applyFovModifiers increases FOV correctly', () {
      final effects = [
        NpcEffect(
          typeId: 'fov_modifier_test',
          isPositive: true,
          remainingMoves: 5,
        ),
      ];
      final result = service.applyFovModifiers(3, effects);
      expect(result, 5); // 3 + 2 = 5
    });

    test('applyFovModifiers decreases FOV but clamps to min 1', () {
      final effects = [
        NpcEffect(
          typeId: 'fov_modifier_test',
          isPositive: false,
          remainingMoves: 5,
        ),
      ];
      final result = service.applyFovModifiers(2, effects);
      expect(result, 1); // 2 - 5 = -3, clamped to 1
    });

    test('applyHouseRestoreModifiers increases restore correctly', () {
      final effects = [
        NpcEffect(
          typeId: 'house_restore_test',
          isPositive: true,
          remainingBattles: 3,
        ),
      ];
      final result = service.applyHouseRestoreModifiers(10, effects);
      expect(result, 15); // 10 + 5 = 15
    });

    test(
      'applyHouseRestoreModifiers decreases restore but clamps to min 0',
      () {
        final effects = [
          NpcEffect(
            typeId: 'house_restore_test',
            isPositive: false,
            remainingBattles: 3,
          ),
        ];
        final result = service.applyHouseRestoreModifiers(3, effects);
        expect(result, 0); // 3 - 10 = -7, clamped to 0
      },
    );
  });

  group('Multi-hook interaction test (fix O)', () {
    late NpcEffectService service;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      NpcEffectRegistry.register(_MultiHookDefinition());
      service = NpcEffectService(random: Random(42));
    });

    test('single effect can modify both FC and EXP in same battle', () {
      final effects = [
        NpcEffect(
          typeId: 'multi_hook_test',
          isPositive: true,
          remainingBattles: 3,
        ),
      ];

      // Check FC modification
      final modifiedPlayerFC = service.applyPlayerFCModifiers(100.0, effects);
      expect(modifiedPlayerFC, 120.0); // +20%

      final modifiedEnemyFC = service.applyEnemyFCModifiers(
        80.0,
        ExploreCellType.monster,
        effects,
      );
      expect(modifiedEnemyFC, 64.0); // -20%

      // Check EXP modification
      final modifiedExp = service.applyBattleEffects(
        baseExpChange: 10.0,
        isVictory: true,
        currentExp: 50.0,
        cellType: ExploreCellType.monster,
        activeEffects: effects,
      );
      expect(modifiedExp, 15.0); // +50%
    });
  });

  group('isExpired for unknown typeIds (fix D)', () {
    test(
      'effect with unknown typeId defaults to instant and never expires',
      () {
        // Before fix, isExpired returned false for unknown types even if they
        // had duration fields. After fix, durationType defaults to instant,
        // so isExpired is still false (instant effects don't expire).
        final effect = NpcEffect(typeId: 'nonexistent_type', isPositive: true);
        expect(effect.durationType, EffectDurationType.instant);
        expect(effect.isExpired, false);
      },
    );

    test('explicitly passing durationType overrides lookup', () {
      final effect = NpcEffect(
        typeId: 'nonexistent_type',
        isPositive: true,
        durationType: EffectDurationType.battles,
        remainingBattles: 0,
      );
      expect(effect.isExpired, true); // battles duration with 0 remaining
    });
  });

  group('New service methods', () {
    late NpcEffectService service;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      service = NpcEffectService(random: Random(42));
    });

    test('applyAPCostModifiers returns base when no effects', () {
      final result = service.applyAPCostModifiers(5, 'move', []);
      expect(result, 5);
    });

    test('notifyBattleComplete does not throw for no effects', () {
      final map = ExploreMap(
        grid: [],
        width: 5,
        height: 5,
        playerX: 2,
        playerY: 2,
        generatedAtLevel: 1,
        generatedAtExp: 0.0,
      );
      // Should not throw
      service.notifyBattleComplete(true, ExploreCellType.monster, map, []);
    });
  });
}

/// Test helper: a minimal custom effect definition for testing registration
class _TestEffectDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'test_effect';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) =>
      NpcEffect(typeId: typeId, isPositive: true);

  @override
  double applyImmediate(
    NpcEffect effect,
    double currentExp,
    double maxExp,
    Random random,
  ) => 0.0;

  @override
  IconData getIcon(NpcEffect effect) => Icons.help;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) => 'Test';

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) => 'Test effect';

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Test helper: a move-duration effect definition for testing move charges
class _MoveDurationTestDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'test_move_effect';

  @override
  EffectDurationType get durationType => EffectDurationType.moves;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) =>
      NpcEffect(typeId: typeId, isPositive: true, remainingMoves: 5);

  @override
  IconData getIcon(NpcEffect effect) => Icons.directions_walk;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) => 'Move Test';

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) => 'Move test effect';

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) =>
      'Moves: ${effect.remainingMoves}';
}

/// Test helper: an effect that modifies FOV radius
class _FovModifyingDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'fov_modifier_test';

  @override
  EffectDurationType get durationType => EffectDurationType.moves;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) =>
      NpcEffect(typeId: typeId, isPositive: true, remainingMoves: 5);

  @override
  int modifyFovRadius(NpcEffect effect, int baseRadius) {
    // Positive: +2 FOV, Negative: -5 FOV
    return effect.isPositive ? baseRadius + 2 : baseRadius - 5;
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.visibility;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) => 'FOV Test';

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) => 'FOV modifier test';

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) =>
      'FOV modifier';
}

/// Test helper: an effect that modifies house restore
class _HouseRestoreModifyingDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'house_restore_test';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) =>
      NpcEffect(typeId: typeId, isPositive: true, remainingBattles: 3);

  @override
  int modifyHouseRestore(NpcEffect effect, int baseRestore) {
    // Positive: +5 AP, Negative: -10 AP
    return effect.isPositive ? baseRestore + 5 : baseRestore - 10;
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.house;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) => 'House Test';

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) => 'House restore modifier test';

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) =>
      'House modifier';
}

/// Test helper: an effect that modifies multiple hooks (FC + EXP)
class _MultiHookDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'multi_hook_test';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) =>
      NpcEffect(typeId: typeId, isPositive: true, remainingBattles: 3);

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    // +20% player FC
    return baseFC * 1.2;
  }

  @override
  double modifyEnemyFC(
    NpcEffect effect,
    double baseEnemyFC,
    ExploreCellType cellType,
  ) {
    // -20% enemy FC
    return baseEnemyFC * 0.8;
  }

  @override
  double applyBattle(
    NpcEffect effect,
    double baseExpChange,
    bool isVictory,
    double currentExp,
    ExploreCellType cellType,
  ) {
    // +50% EXP
    return baseExpChange * 1.5;
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.star;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) => 'Multi Hook';

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) => 'Multi hook test';

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) =>
      'Multi hook active';
}
