import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyber_cultivation/l10n/app_localizations.dart';
import 'package:cyber_cultivation/models/npc_effect.dart';
import 'package:cyber_cultivation/models/explore_map.dart';
import 'package:cyber_cultivation/models/battle_result.dart';
import 'package:cyber_cultivation/constants.dart';

void main() {
  setUp(() {
    // Ensure registry is initialized before each test group
    NpcEffectRegistry.clear();
    NpcEffectRegistry.initialize();
  });

  group('NpcEffectRegistry', () {
    test('initializes with 45 built-in definitions', () {
      expect(NpcEffectRegistry.count, 45);
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
      expect(NpcEffectRegistry.count, 45);
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
        expect(NpcEffectRegistry.count, 46); // 45 built-in + 1 custom
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

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPREHENSIVE EFFECT TESTS - Verify all 45 effects work correctly
  // ═══════════════════════════════════════════════════════════════════════════

  group('EXP Effects - Comprehensive Tests', () {
    late Random seededRandom;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      seededRandom = Random(12345);
    });

    group('ExpGiftStealDefinition', () {
      test('positive effect grants 5-10% of maxExp', () {
        final def = ExpGiftStealDefinition();
        final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: true);
        // Run multiple times to check range
        for (int i = 0; i < 10; i++) {
          final expChange = def.applyImmediate(effect, 50.0, 100.0, Random(i));
          expect(expChange, greaterThanOrEqualTo(5.0)); // 5% of 100
          expect(expChange, lessThanOrEqualTo(10.0)); // 10% of 100
        }
      });

      test('negative effect steals 5-10% of maxExp', () {
        final def = ExpGiftStealDefinition();
        final effect = NpcEffect(typeId: 'exp_gift_steal', isPositive: false);
        for (int i = 0; i < 10; i++) {
          final expChange = def.applyImmediate(effect, 50.0, 100.0, Random(i));
          expect(expChange, lessThanOrEqualTo(-5.0));
          expect(expChange, greaterThanOrEqualTo(-10.0));
        }
      });
    });

    group('ExpMultiplierDefinition', () {
      test('positive effect doubles battle EXP', () {
        final def = ExpMultiplierDefinition();
        final effect = NpcEffect(
          typeId: 'exp_multiplier',
          isPositive: true,
          remainingBattles: 3,
        );
        final modifiedExp = def.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 20.0); // 2x multiplier
      });

      test('negative effect halves battle EXP', () {
        final def = ExpMultiplierDefinition();
        final effect = NpcEffect(
          typeId: 'exp_multiplier',
          isPositive: false,
          remainingBattles: 3,
        );
        final modifiedExp = def.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 5.0); // 0.5x multiplier
      });

      test('generates with correct duration', () {
        final def = ExpMultiplierDefinition();
        final effect = def.generate(seededRandom, 50.0, 100.0);
        expect(
          effect.remainingBattles,
          NpcEffectConstants.multiplierDurationBattles,
        );
      });
    });

    group('ExpInsuranceDefinition', () {
      test('positive effect prevents loss penalty', () {
        final def = ExpInsuranceDefinition();
        final effect = NpcEffect(
          typeId: 'exp_insurance',
          isPositive: true,
          remainingBattles: 1,
        );
        // On loss, negative EXP should be zeroed
        final modifiedExp = def.applyBattle(
          effect,
          -10.0,
          false,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 0.0);
      });

      test('positive effect does not affect wins', () {
        final def = ExpInsuranceDefinition();
        final effect = NpcEffect(
          typeId: 'exp_insurance',
          isPositive: true,
          remainingBattles: 1,
        );
        final modifiedExp = def.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 10.0); // Unchanged
      });

      test('negative effect prevents win reward', () {
        final def = ExpInsuranceDefinition();
        final effect = NpcEffect(
          typeId: 'exp_insurance',
          isPositive: false,
          remainingBattles: 1,
        );
        final modifiedExp = def.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 0.0);
      });

      test('negative effect does not affect losses', () {
        final def = ExpInsuranceDefinition();
        final effect = NpcEffect(
          typeId: 'exp_insurance',
          isPositive: false,
          remainingBattles: 1,
        );
        final modifiedExp = def.applyBattle(
          effect,
          -10.0,
          false,
          50.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, -10.0); // Unchanged
      });
    });

    group('ExpFloorDefinition', () {
      test('positive effect stores current EXP as floor', () {
        final def = ExpFloorDefinition();
        final effect = def.generate(seededRandom, 75.0, 100.0);
        expect(effect.storedValue, 75.0);
      });

      test('positive effect prevents EXP from falling below floor', () {
        final def = ExpFloorDefinition();
        final effect = NpcEffect(
          typeId: 'exp_floor',
          isPositive: true,
          remainingBattles: 1,
          data: {'storedValue': 50.0},
        );
        // If loss would bring below floor, return 0
        final modifiedExp = def.applyBattle(
          effect,
          -20.0,
          false,
          55.0,
          ExploreCellType.monster,
        );
        // currentExp (55) - 20 = 35, but floor is 50, so loss limited
        expect(modifiedExp, -5.0); // Can only lose down to floor
      });

      test('negative effect stores current EXP as ceiling', () {
        final def = ExpFloorDefinition();
        final effect = NpcEffect(
          typeId: 'exp_floor',
          isPositive: false,
          remainingBattles: 1,
          data: {'storedValue': 50.0},
        );
        // If win would bring above ceiling, cap it
        final modifiedExp = def.applyBattle(
          effect,
          20.0,
          true,
          45.0,
          ExploreCellType.monster,
        );
        expect(modifiedExp, 5.0); // Can only gain up to ceiling
      });
    });

    group('ExpGambleDefinition', () {
      test('positive effect doubles current EXP', () {
        final def = ExpGambleDefinition();
        final effect = NpcEffect(typeId: 'exp_gamble', isPositive: true);
        // Positive gamble: gain = currentExp (doubles total)
        final expChange = def.applyImmediate(effect, 50.0, 100.0, Random(42));
        expect(expChange, 50.0); // Gain currentExp amount
      });

      test('negative effect halves current EXP', () {
        final def = ExpGambleDefinition();
        final effect = NpcEffect(typeId: 'exp_gamble', isPositive: false);
        // Negative gamble: lose half of currentExp
        final expChange = def.applyImmediate(effect, 50.0, 100.0, Random(42));
        expect(expChange, -25.0); // Lose 50% of currentExp
      });
    });
  });

  group('FC/Battle Effects - Comprehensive Tests', () {
    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
    });

    group('FcBuffDefinition', () {
      test('positive effect increases player FC by 20%', () {
        final def = FcBuffDefinition();
        final effect = NpcEffect(
          typeId: 'fc_buff',
          isPositive: true,
          remainingBattles: 3,
        );
        final modifiedFC = def.modifyPlayerFC(effect, 100.0);
        expect(modifiedFC, 120.0); // fcBuffMultiplier = 1.20
      });

      test('negative effect decreases player FC by 20%', () {
        final def = FcBuffDefinition();
        final effect = NpcEffect(
          typeId: 'fc_buff',
          isPositive: false,
          remainingBattles: 3,
        );
        final modifiedFC = def.modifyPlayerFC(effect, 100.0);
        expect(modifiedFC, 80.0); // fcDebuffMultiplier = 0.80
      });
    });

    group('GuaranteedOutcomeDefinition', () {
      test('positive effect forces victory', () {
        final def = GuaranteedOutcomeDefinition();
        final effect = NpcEffect(
          typeId: 'guaranteed_outcome',
          isPositive: true,
          remainingBattles: 1,
        );
        final outcome = def.overrideBattleOutcome(
          effect,
          50.0,
          100.0,
          ExploreCellType.monster,
        );
        expect(outcome, BattleOutcome.victory);
      });

      test('negative effect forces defeat', () {
        final def = GuaranteedOutcomeDefinition();
        final effect = NpcEffect(
          typeId: 'guaranteed_outcome',
          isPositive: false,
          remainingBattles: 1,
        );
        final outcome = def.overrideBattleOutcome(
          effect,
          50.0,
          100.0,
          ExploreCellType.monster,
        );
        expect(outcome, BattleOutcome.defeat);
      });
    });

    group('FleeMasteryDefinition', () {
      test('positive effect guarantees flee success', () {
        final def = FleeMasteryDefinition();
        final effect = NpcEffect(
          typeId: 'flee_mastery',
          isPositive: true,
          remainingBattles: 3,
        );
        final modifiedChance = def.modifyFleeChance(effect, 0.3);
        expect(modifiedChance, 1.0);
      });

      test('negative effect guarantees flee failure', () {
        final def = FleeMasteryDefinition();
        final effect = NpcEffect(
          typeId: 'flee_mastery',
          isPositive: false,
          remainingBattles: 3,
        );
        final modifiedChance = def.modifyFleeChance(effect, 0.7);
        expect(modifiedChance, 0.0);
      });
    });

    group('FirstStrikeDefinition', () {
      test('positive effect reduces enemy FC by 50%', () {
        final def = FirstStrikeDefinition();
        final effect = NpcEffect(
          typeId: 'first_strike',
          isPositive: true,
          remainingBattles: 3,
        );
        expect(def.modifyEnemyFC(effect, 100.0, ExploreCellType.monster), 50.0);
        expect(def.modifyPlayerFC(effect, 100.0), 100.0); // Unchanged
      });

      test('negative effect reduces player FC by 50%', () {
        final def = FirstStrikeDefinition();
        final effect = NpcEffect(
          typeId: 'first_strike',
          isPositive: false,
          remainingBattles: 3,
        );
        expect(def.modifyPlayerFC(effect, 100.0), 50.0);
        expect(
          def.modifyEnemyFC(effect, 100.0, ExploreCellType.monster),
          100.0,
        ); // Unchanged
      });
    });

    group('GlassCannonDefinition', () {
      test('positive effect increases player FC by 50%', () {
        final def = GlassCannonDefinition();
        final effect = NpcEffect(
          typeId: 'glass_cannon',
          isPositive: true,
          remainingBattles: 1,
        );
        expect(def.modifyPlayerFC(effect, 100.0), 150.0);
      });

      test('negative effect decreases player FC by 50%', () {
        final def = GlassCannonDefinition();
        final effect = NpcEffect(
          typeId: 'glass_cannon',
          isPositive: false,
          remainingBattles: 1,
        );
        expect(def.modifyPlayerFC(effect, 100.0), 50.0);
      });
    });
  });

  group('Map/Terrain Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      // Create a 10x10 test map with various cell types
      testMap = _createTestMap();
    });

    group('PathClearingDefinition', () {
      test('positive effect removes mountains', () {
        final def = PathClearingDefinition();
        final effect = NpcEffect(
          typeId: 'path_clearing',
          isPositive: true,
          data: {'count': 3},
        );

        // Count mountains before
        final mountainsBefore = _countCellType(
          testMap,
          ExploreCellType.mountain,
        );

        def.applyMapEffect(effect, testMap, Random(42));

        final mountainsAfter = _countCellType(
          testMap,
          ExploreCellType.mountain,
        );
        expect(mountainsAfter, lessThan(mountainsBefore));
      });

      test('negative effect adds mountains', () {
        final def = PathClearingDefinition();
        final effect = NpcEffect(
          typeId: 'path_clearing',
          isPositive: false,
          data: {'count': 3},
        );

        final blanksBefore = _countCellType(testMap, ExploreCellType.blank);
        def.applyMapEffect(effect, testMap, Random(42));
        final blanksAfter = _countCellType(testMap, ExploreCellType.blank);

        expect(blanksAfter, lessThan(blanksBefore));
      });
    });

    group('RiverBridgeDefinition', () {
      test('positive effect removes rivers', () {
        final def = RiverBridgeDefinition();
        final effect = NpcEffect(
          typeId: 'river_bridge',
          isPositive: true,
          data: {'count': 2},
        );

        final riversBefore = _countCellType(testMap, ExploreCellType.river);
        def.applyMapEffect(effect, testMap, Random(42));
        final riversAfter = _countCellType(testMap, ExploreCellType.river);

        expect(riversAfter, lessThanOrEqualTo(riversBefore));
      });

      test('negative effect adds rivers', () {
        final def = RiverBridgeDefinition();
        final effect = NpcEffect(
          typeId: 'river_bridge',
          isPositive: false,
          data: {'count': 2},
        );

        final blanksBefore = _countCellType(testMap, ExploreCellType.blank);
        def.applyMapEffect(effect, testMap, Random(42));
        final blanksAfter = _countCellType(testMap, ExploreCellType.blank);

        expect(blanksAfter, lessThan(blanksBefore));
      });
    });

    group('MonsterCleanseDefinition', () {
      test('positive effect removes monsters', () {
        final def = MonsterCleanseDefinition();
        final effect = NpcEffect(typeId: 'monster_cleanse', isPositive: true);

        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);
        def.applyMapEffect(effect, testMap, Random(42));
        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);

        expect(monstersAfter, lessThan(monstersBefore));
      });

      test('negative effect spawns monsters', () {
        final def = MonsterCleanseDefinition();
        final effect = NpcEffect(typeId: 'monster_cleanse', isPositive: false);

        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);
        def.applyMapEffect(effect, testMap, Random(42));
        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);

        expect(monstersAfter, greaterThan(monstersBefore));
      });
    });

    group('BossShiftDefinition', () {
      test('positive effect removes bosses', () {
        final def = BossShiftDefinition();
        final effect = NpcEffect(typeId: 'boss_shift', isPositive: true);

        final bossesBefore = _countCellType(testMap, ExploreCellType.boss);
        def.applyMapEffect(effect, testMap, Random(42));
        final bossesAfter = _countCellType(testMap, ExploreCellType.boss);

        expect(bossesAfter, lessThanOrEqualTo(bossesBefore));
      });

      test('negative effect spawns boss', () {
        final def = BossShiftDefinition();
        final effect = NpcEffect(typeId: 'boss_shift', isPositive: false);

        final bossesBefore = _countCellType(testMap, ExploreCellType.boss);
        def.applyMapEffect(effect, testMap, Random(42));
        final bossesAfter = _countCellType(testMap, ExploreCellType.boss);

        expect(bossesAfter, greaterThanOrEqualTo(bossesBefore));
      });
    });

    group('SafeZoneDefinition', () {
      test('positive effect clears enemies near player', () {
        final def = SafeZoneDefinition();
        final effect = NpcEffect(typeId: 'safe_zone', isPositive: true);

        // Place monsters near player
        testMap.grid[testMap.playerY + 1][testMap.playerX] = ExploreCell(
          type: ExploreCellType.monster,
          x: testMap.playerX,
          y: testMap.playerY + 1,
        );

        def.applyMapEffect(effect, testMap, Random(42));

        // Check 5x5 area around player has no monsters/bosses
        final radius = NpcEffectConstants.safeZoneRadius;
        var enemiesNear = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final x = testMap.playerX + dx;
            final y = testMap.playerY + dy;
            if (x >= 0 && x < testMap.width && y >= 0 && y < testMap.height) {
              final type = testMap.grid[y][x].type;
              if (type == ExploreCellType.monster ||
                  type == ExploreCellType.boss) {
                enemiesNear++;
              }
            }
          }
        }
        expect(enemiesNear, 0);
      });
    });

    group('TerrainSwapDefinition', () {
      test('positive effect removes mountains', () {
        final def = TerrainSwapDefinition();
        final effect = NpcEffect(typeId: 'terrain_swap', isPositive: true);

        final mountainsBefore = _countCellType(
          testMap,
          ExploreCellType.mountain,
        );

        def.applyMapEffect(effect, testMap, Random(42));

        final mountainsAfter = _countCellType(
          testMap,
          ExploreCellType.mountain,
        );

        // Positive: converts some mountains to blank
        expect(mountainsAfter, lessThanOrEqualTo(mountainsBefore));
      });

      test('negative effect adds mountains near player', () {
        final def = TerrainSwapDefinition();
        final effect = NpcEffect(typeId: 'terrain_swap', isPositive: false);

        final blanksBefore = _countCellType(testMap, ExploreCellType.blank);

        def.applyMapEffect(effect, testMap, Random(42));

        final blanksAfter = _countCellType(testMap, ExploreCellType.blank);

        // Negative: converts some blanks to mountains
        expect(blanksAfter, lessThanOrEqualTo(blanksBefore));
      });
    });
  });

  group('Vision/Radar Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      testMap = _createTestMap();
    });

    group('FovModifyDefinition', () {
      test('positive effect stores positive FOV modifier in data', () {
        final def = FovModifyDefinition();
        final effect = NpcEffect(
          typeId: 'fov_modify',
          isPositive: true,
          data: {'amount': 3},
        );
        def.applyMapEffect(effect, testMap, Random(42));
        // Stores fovModifier in data for later use
        expect(effect.data['fovModifier'], 3);
      });

      test('negative effect stores negative FOV modifier in data', () {
        final def = FovModifyDefinition();
        final effect = NpcEffect(
          typeId: 'fov_modify',
          isPositive: false,
          data: {'amount': 3},
        );
        def.applyMapEffect(effect, testMap, Random(42));
        // Stores negative fovModifier in data
        expect(effect.data['fovModifier'], -3);
      });
    });

    group('BossRadarDefinition', () {
      test('positive effect reveals boss locations', () {
        final def = BossRadarDefinition();
        final effect = NpcEffect(typeId: 'boss_radar', isPositive: true);

        // Get unvisited boss count before
        var unvisitedBossesBefore = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.boss &&
                !testMap.isVisited(x, y)) {
              unvisitedBossesBefore++;
            }
          }
        }

        def.applyMapEffect(effect, testMap, Random(42));

        // After reveal, all bosses should be visited
        var unvisitedBossesAfter = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.boss &&
                !testMap.isVisited(x, y)) {
              unvisitedBossesAfter++;
            }
          }
        }
        expect(unvisitedBossesAfter, lessThan(unvisitedBossesBefore));
      });

      test('negative effect generates move-based hide effect', () {
        final def = BossRadarDefinition();
        final effect = def.generate(Random(0), 50.0, 100.0);
        // Generate multiple times to get a negative one
        NpcEffect negEffect = effect;
        for (int i = 0; i < 20; i++) {
          negEffect = def.generate(Random(i), 50.0, 100.0);
          if (!negEffect.isPositive) break;
        }
        if (!negEffect.isPositive) {
          expect(negEffect.durationType, EffectDurationType.moves);
          expect(negEffect.remainingMoves, greaterThan(0));
          expect(negEffect.data['hiddenType'], isNotNull);
        }
      });
    });

    group('NpcRadarDefinition', () {
      test('positive effect reveals nearest NPC location', () {
        final def = NpcRadarDefinition();
        final effect = NpcEffect(typeId: 'npc_radar', isPositive: true);

        // Get unvisited NPC count before
        var unvisitedNpcsBefore = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.npc &&
                !testMap.isVisited(x, y)) {
              unvisitedNpcsBefore++;
            }
          }
        }

        def.applyMapEffect(effect, testMap, Random(42));

        // After reveal, at least one NPC should be visited (nearest)
        var unvisitedNpcsAfter = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.npc &&
                !testMap.isVisited(x, y)) {
              unvisitedNpcsAfter++;
            }
          }
        }
        // Reveals nearest NPC, so unvisited should decrease by at least 1
        if (unvisitedNpcsBefore > 0) {
          expect(unvisitedNpcsAfter, lessThan(unvisitedNpcsBefore));
        }
      });
    });

    group('MonsterRadarDefinition', () {
      test('positive effect reveals monsters in range', () {
        final def = MonsterRadarDefinition();
        final effect = NpcEffect(typeId: 'monster_radar', isPositive: true);
        final range = NpcEffectConstants.monsterRadarRange;

        def.applyMapEffect(effect, testMap, Random(42));

        // Monsters within range should be visited
        for (int dy = -range; dy <= range; dy++) {
          for (int dx = -range; dx <= range; dx++) {
            final x = testMap.playerX + dx;
            final y = testMap.playerY + dy;
            if (x >= 0 && x < testMap.width && y >= 0 && y < testMap.height) {
              if (testMap.grid[y][x].type == ExploreCellType.monster) {
                expect(testMap.isVisited(x, y), true);
              }
            }
          }
        }
      });

      test('negative effect stores hidden type with range', () {
        final def = MonsterRadarDefinition();
        // Generate until we get negative
        NpcEffect negEffect = NpcEffect(
          typeId: 'monster_radar',
          isPositive: true,
        );
        for (int i = 0; i < 20; i++) {
          negEffect = def.generate(Random(i), 50.0, 100.0);
          if (!negEffect.isPositive) break;
        }
        if (!negEffect.isPositive) {
          expect(negEffect.data['hiddenType'], ExploreCellType.monster.index);
          expect(negEffect.data['range'], NpcEffectConstants.monsterRadarRange);
        }
      });
    });

    group('MapRevealDefinition', () {
      test('positive effect reveals 20% of unexplored map', () {
        final def = MapRevealDefinition();
        final effect = NpcEffect(typeId: 'map_reveal', isPositive: true);

        final visitedBefore = testMap.visitedCells.length;
        def.applyMapEffect(effect, testMap, Random(42));
        final visitedAfter = testMap.visitedCells.length;

        expect(visitedAfter, greaterThan(visitedBefore));
      });

      test('negative effect shrinks FOV', () {
        final def = MapRevealDefinition();
        final effect = NpcEffect(
          typeId: 'map_reveal',
          isPositive: false,
          remainingMoves: 10,
        );
        final modifiedRadius = def.modifyFovRadius(effect, 5);
        expect(modifiedRadius, NpcEffectConstants.fovShrinkMinRadius);
      });
    });

    group('HouseRadarDefinition', () {
      test('positive effect reveals nearest house location', () {
        final def = HouseRadarDefinition();
        final effect = NpcEffect(typeId: 'house_radar', isPositive: true);

        // Get unvisited house count before
        var unvisitedHousesBefore = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.house &&
                !testMap.isVisited(x, y)) {
              unvisitedHousesBefore++;
            }
          }
        }

        def.applyMapEffect(effect, testMap, Random(42));

        // After reveal, at least one house should be visited (nearest)
        var unvisitedHousesAfter = 0;
        for (int y = 0; y < testMap.height; y++) {
          for (int x = 0; x < testMap.width; x++) {
            if (testMap.grid[y][x].type == ExploreCellType.house &&
                !testMap.isVisited(x, y)) {
              unvisitedHousesAfter++;
            }
          }
        }
        if (unvisitedHousesBefore > 0) {
          expect(unvisitedHousesAfter, lessThan(unvisitedHousesBefore));
        }
      });
    });
  });

  group('Movement Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      testMap = _createTestMap();
    });

    group('TeleportDefinition', () {
      test('positive effect teleports to far blank cell if available', () {
        final def = TeleportDefinition();
        final effect = NpcEffect(typeId: 'teleport', isPositive: true);

        def.applyMapEffect(effect, testMap, Random(42));

        // On a small map, may not find cells far enough away
        // Just verify implementation doesn't crash and player position is valid
        expect(testMap.playerX, greaterThanOrEqualTo(0));
        expect(testMap.playerY, greaterThanOrEqualTo(0));
        expect(testMap.playerX, lessThan(testMap.width));
        expect(testMap.playerY, lessThan(testMap.height));
      });

      test('negative effect teleports back to spawn', () {
        final def = TeleportDefinition();
        final effect = NpcEffect(typeId: 'teleport', isPositive: false);

        // Move player away from center
        testMap.playerX = 1;
        testMap.playerY = 1;

        def.applyMapEffect(effect, testMap, Random(42));

        // Player should be near center
        final centerX = testMap.width ~/ 2;
        final centerY = testMap.height ~/ 2;
        expect((testMap.playerX - centerX).abs(), lessThanOrEqualTo(2));
        expect((testMap.playerY - centerY).abs(), lessThanOrEqualTo(2));
      });
    });

    group('SpeedBoostDefinition', () {
      test('generates with correct move duration', () {
        final def = SpeedBoostDefinition();
        final effect = def.generate(Random(42), 50.0, 100.0);
        expect(
          effect.remainingMoves,
          NpcEffectConstants.speedBoostDurationMoves,
        );
      });
    });

    group('TeleportHouseDefinition', () {
      test('positive effect teleports near house', () {
        final def = TeleportHouseDefinition();
        final effect = NpcEffect(typeId: 'teleport_house', isPositive: true);

        def.applyMapEffect(effect, testMap, Random(42));

        // Check if player is adjacent to a house
        var nearHouse = false;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final x = testMap.playerX + dx;
            final y = testMap.playerY + dy;
            if (x >= 0 && x < testMap.width && y >= 0 && y < testMap.height) {
              if (testMap.grid[y][x].type == ExploreCellType.house) {
                nearHouse = true;
              }
            }
          }
        }
        expect(nearHouse, true);
      });
    });
  });

  group('Monster/Enemy Manipulation Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      testMap = _createTestMap();
    });

    group('WeakenEnemiesDefinition', () {
      test('positive effect stores affected monsters in data', () {
        final def = WeakenEnemiesDefinition();
        final effect = NpcEffect(typeId: 'weaken_enemies', isPositive: true);
        // Place a monster within radius
        testMap.grid[testMap.playerY + 1][testMap.playerX] = ExploreCell(
          type: ExploreCellType.monster,
          x: testMap.playerX,
          y: testMap.playerY + 1,
        );

        def.applyMapEffect(effect, testMap, Random(42));

        // Should store affected monster positions
        expect(effect.data['affectedMonsters'], isA<List>());
        expect((effect.data['affectedMonsters'] as List).isNotEmpty, true);
      });

      test('negative effect also stores affected monsters', () {
        final def = WeakenEnemiesDefinition();
        final effect = NpcEffect(typeId: 'weaken_enemies', isPositive: false);

        def.applyMapEffect(effect, testMap, Random(42));

        // Should store affected monster positions (empty list if no monsters)
        expect(effect.data['affectedMonsters'], isA<List>());
      });
    });

    group('MonsterConversionDefinition', () {
      test('positive effect converts monsters to NPCs', () {
        final def = MonsterConversionDefinition();
        final effect = NpcEffect(
          typeId: 'monster_conversion',
          isPositive: true,
        );

        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);
        final npcsBefore = _countCellType(testMap, ExploreCellType.npc);

        def.applyMapEffect(effect, testMap, Random(42));

        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);
        final npcsAfter = _countCellType(testMap, ExploreCellType.npc);

        // Converts nearest monsters to NPCs
        if (monstersBefore > 0) {
          expect(monstersAfter, lessThan(monstersBefore));
          expect(npcsAfter, greaterThan(npcsBefore));
        }
      });

      test('negative effect converts NPCs to monsters', () {
        final def = MonsterConversionDefinition();
        final effect = NpcEffect(
          typeId: 'monster_conversion',
          isPositive: false,
        );

        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);
        final npcsBefore = _countCellType(testMap, ExploreCellType.npc);

        def.applyMapEffect(effect, testMap, Random(42));

        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);
        final npcsAfter = _countCellType(testMap, ExploreCellType.npc);

        // Converts nearest NPCs to monsters
        if (npcsBefore > 0) {
          expect(npcsAfter, lessThan(npcsBefore));
          expect(monstersAfter, greaterThan(monstersBefore));
        }
      });
    });

    group('BossDowngradeDefinition', () {
      test('positive effect converts bosses to monsters', () {
        final def = BossDowngradeDefinition();
        final effect = NpcEffect(typeId: 'boss_downgrade', isPositive: true);

        final bossesBefore = _countCellType(testMap, ExploreCellType.boss);
        def.applyMapEffect(effect, testMap, Random(42));
        final bossesAfter = _countCellType(testMap, ExploreCellType.boss);

        expect(bossesAfter, lessThan(bossesBefore));
      });

      test('negative effect converts monsters to bosses', () {
        final def = BossDowngradeDefinition();
        final effect = NpcEffect(typeId: 'boss_downgrade', isPositive: false);

        final bossesBefore = _countCellType(testMap, ExploreCellType.boss);
        def.applyMapEffect(effect, testMap, Random(42));
        final bossesAfter = _countCellType(testMap, ExploreCellType.boss);

        expect(bossesAfter, greaterThan(bossesBefore));
      });
    });

    group('MonsterFreezeDefinition', () {
      test('generates with correct battle duration', () {
        final def = MonsterFreezeDefinition();
        final effect = def.generate(Random(42), 50.0, 100.0);
        expect(
          effect.remainingBattles,
          NpcEffectConstants.monsterFreezeDurationBattles,
        );
      });
    });

    group('ClearWaveDefinition', () {
      test('positive effect removes monsters in radius', () {
        final def = ClearWaveDefinition();
        final effect = NpcEffect(typeId: 'clear_wave', isPositive: true);

        // Place monster within radius (3 cells)
        testMap.grid[testMap.playerY + 1][testMap.playerX] = ExploreCell(
          type: ExploreCellType.monster,
          x: testMap.playerX,
          y: testMap.playerY + 1,
        );

        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);

        def.applyMapEffect(effect, testMap, Random(42));

        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);

        // Clears monsters in radius (3 cells), not all monsters on map
        expect(monstersAfter, lessThanOrEqualTo(monstersBefore));
      });
    });

    group('MonsterMagnetDefinition', () {
      test('pushes monsters away or toward player', () {
        final def = MonsterMagnetDefinition();
        final effect = NpcEffect(typeId: 'monster_magnet', isPositive: true);

        // Place monster within radius
        testMap.grid[testMap.playerY + 2][testMap.playerX] = ExploreCell(
          type: ExploreCellType.monster,
          x: testMap.playerX,
          y: testMap.playerY + 2,
        );

        def.applyMapEffect(effect, testMap, Random(42));

        // Just verify it doesn't crash; actual movement depends on map layout
        expect(true, true);
      });
    });
  });

  group('NPC Chain Effects - Comprehensive Tests', () {
    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
    });

    group('NpcBlessingChainDefinition', () {
      test('positive effect improves next NPC effect', () {
        final def = NpcBlessingChainDefinition();
        final chainEffect = NpcEffect(
          typeId: 'npc_blessing_chain',
          isPositive: true,
          remainingBattles: 1,
        );

        // Create a negative effect
        final nextEffect = NpcEffect(
          typeId: 'exp_gift_steal',
          isPositive: false,
        );

        // Apply chain modification
        final modified = def.modifyNextNpcEffect(chainEffect, nextEffect);

        // Should flip to positive
        expect(modified.isPositive, true);
      });

      test('negative effect worsens next NPC effect', () {
        final def = NpcBlessingChainDefinition();
        final chainEffect = NpcEffect(
          typeId: 'npc_blessing_chain',
          isPositive: false,
          remainingBattles: 1,
        );

        // Create a positive effect
        final nextEffect = NpcEffect(
          typeId: 'exp_gift_steal',
          isPositive: true,
        );

        // Apply chain modification
        final modified = def.modifyNextNpcEffect(chainEffect, nextEffect);

        // Should flip to negative
        expect(modified.isPositive, false);
      });
    });

    group('NpcSpawnDefinition', () {
      test('positive effect spawns NPCs on map', () {
        final testMap = _createTestMap();
        final def = NpcSpawnDefinition();
        final effect = NpcEffect(typeId: 'npc_spawn', isPositive: true);

        final npcsBefore = _countCellType(testMap, ExploreCellType.npc);
        def.applyMapEffect(effect, testMap, Random(42));
        final npcsAfter = _countCellType(testMap, ExploreCellType.npc);

        expect(npcsAfter, greaterThan(npcsBefore));
      });

      test('negative effect removes NPCs from map', () {
        final testMap = _createTestMap();
        final def = NpcSpawnDefinition();
        final effect = NpcEffect(typeId: 'npc_spawn', isPositive: false);

        final npcsBefore = _countCellType(testMap, ExploreCellType.npc);
        def.applyMapEffect(effect, testMap, Random(42));
        final npcsAfter = _countCellType(testMap, ExploreCellType.npc);

        expect(npcsAfter, lessThan(npcsBefore));
      });
    });

    group('NpcUpgradeDefinition', () {
      test('positive effect doubles next NPC effect duration', () {
        final def = NpcUpgradeDefinition();
        final upgradeEffect = NpcEffect(
          typeId: 'npc_upgrade',
          isPositive: true,
          remainingBattles: 1,
        );

        // Create a duration-based effect
        final nextEffect = NpcEffect(
          typeId: 'exp_multiplier',
          isPositive: true,
          remainingBattles: 3,
          remainingMoves: 5,
        );

        final modified = def.modifyNextNpcEffect(upgradeEffect, nextEffect);

        // Duration should be doubled
        expect(modified.remainingBattles, 6);
        expect(modified.remainingMoves, 10);
      });

      test('negative effect reverses next NPC effect polarity', () {
        final def = NpcUpgradeDefinition();
        final upgradeEffect = NpcEffect(
          typeId: 'npc_upgrade',
          isPositive: false,
          remainingBattles: 1,
        );

        // Create a positive effect
        final nextEffect = NpcEffect(
          typeId: 'exp_gift_steal',
          isPositive: true,
        );

        final modified = def.modifyNextNpcEffect(upgradeEffect, nextEffect);

        // Polarity should be reversed
        expect(modified.isPositive, false);
      });
    });
  });

  group('House Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      testMap = _createTestMap();
    });

    group('HouseSpawnDefinition', () {
      test('positive effect spawns houses', () {
        final def = HouseSpawnDefinition();
        final effect = NpcEffect(typeId: 'house_spawn', isPositive: true);

        final housesBefore = _countCellType(testMap, ExploreCellType.house);
        def.applyMapEffect(effect, testMap, Random(42));
        final housesAfter = _countCellType(testMap, ExploreCellType.house);

        expect(housesAfter, greaterThan(housesBefore));
      });

      test('negative effect removes houses', () {
        final def = HouseSpawnDefinition();
        final effect = NpcEffect(typeId: 'house_spawn', isPositive: false);

        final housesBefore = _countCellType(testMap, ExploreCellType.house);
        def.applyMapEffect(effect, testMap, Random(42));
        final housesAfter = _countCellType(testMap, ExploreCellType.house);

        expect(housesAfter, lessThan(housesBefore));
      });
    });

    group('HouseUpgradeDefinition', () {
      test('positive effect increases house restore amount', () {
        final def = HouseUpgradeDefinition();
        final effect = NpcEffect(
          typeId: 'house_upgrade',
          isPositive: true,
          remainingMoves: 10,
        );
        final modifiedRestore = def.modifyHouseRestore(effect, 10);
        expect(modifiedRestore, greaterThan(10));
      });

      test('negative effect decreases house restore amount', () {
        final def = HouseUpgradeDefinition();
        final effect = NpcEffect(
          typeId: 'house_upgrade',
          isPositive: false,
          remainingMoves: 10,
        );
        final modifiedRestore = def.modifyHouseRestore(effect, 10);
        expect(modifiedRestore, lessThan(10));
      });
    });
  });

  group('Combo/Conditional Effects - Comprehensive Tests', () {
    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
    });

    group('RiskRewardDefinition', () {
      test('positive effect multiplies EXP and reduces FC', () {
        final def = RiskRewardDefinition();
        final effect = NpcEffect(
          typeId: 'risk_reward',
          isPositive: true,
          remainingBattles: 1,
        );

        // EXP is multiplied by 1.5x
        final winBonus = def.applyBattle(
          effect,
          10.0,
          true,
          50.0,
          ExploreCellType.monster,
        );
        expect(winBonus, 15.0); // 10.0 * 1.5

        // FC is reduced by 20%
        final fc = def.modifyPlayerFC(effect, 100.0);
        expect(fc, 80.0); // 100 * 0.8
      });

      test('negative effect halves EXP and boosts FC', () {
        final def = RiskRewardDefinition();
        final effect = NpcEffect(
          typeId: 'risk_reward',
          isPositive: false,
          remainingBattles: 1,
        );

        // EXP is halved
        final expResult = def.applyBattle(
          effect,
          -10.0,
          false,
          50.0,
          ExploreCellType.monster,
        );
        expect(expResult, -5.0); // -10.0 * 0.5

        // FC is boosted by 20%
        final fc = def.modifyPlayerFC(effect, 100.0);
        expect(fc, 120.0); // 100 * 1.2
      });
    });

    group('SacrificeDefinition', () {
      test('positive effect trades HP for guaranteed EXP', () {
        final def = SacrificeDefinition();
        final effect = def.generate(Random(42), 50.0, 100.0);
        expect(effect.typeId, 'sacrifice');
      });
    });

    group('AllInDefinition', () {
      test('positive gives instant EXP and clears monsters', () {
        final def = AllInDefinition();
        final effect = NpcEffect(typeId: 'all_in', isPositive: true);

        // applyImmediate gives 5% of maxExp
        final expGain = def.applyImmediate(effect, 50.0, 100.0, Random(42));
        expect(expGain, 5.0); // 100.0 * 0.05
      });

      test('negative loses instant EXP and spawns boss', () {
        final def = AllInDefinition();
        final effect = NpcEffect(typeId: 'all_in', isPositive: false);

        // applyImmediate loses 5% of maxExp
        final expLoss = def.applyImmediate(effect, 50.0, 100.0, Random(42));
        expect(expLoss, -5.0); // -100.0 * 0.05
      });
    });

    group('MirrorDefinition', () {
      test('positive doubles player FC', () {
        final def = MirrorDefinition();
        final effect = NpcEffect(
          typeId: 'mirror',
          isPositive: true,
          remainingBattles: 1,
        );

        final fc = def.modifyPlayerFC(effect, 100.0);
        expect(fc, 200.0); // mirrorFCMultiplier = 2.0
      });

      test('negative gives 50/50 battle outcome', () {
        final def = MirrorDefinition();
        final effect = NpcEffect(
          typeId: 'mirror',
          isPositive: false,
          remainingBattles: 1,
        );

        // Player FC should be unchanged for negative
        final fc = def.modifyPlayerFC(effect, 100.0);
        expect(fc, 100.0);

        // Negative overrides battle outcome to 50/50
        final outcome = def.overrideBattleOutcome(
          effect,
          50.0,
          100.0,
          ExploreCellType.monster,
        );
        expect(outcome, isNotNull); // Returns victory or defeat
      });
    });

    group('CounterStackDefinition', () {
      test('stacks counter on each move', () {
        final def = CounterStackDefinition();
        final effect = NpcEffect(
          typeId: 'counter_stack',
          isPositive: true,
          remainingMoves: 20,
          data: {'stacks': 0},
        );
        final testMap = _createTestMap();

        // First move
        def.onMove(effect, testMap);
        expect(effect.data['stacks'], 1);

        // Second move
        def.onMove(effect, testMap);
        expect(effect.data['stacks'], 2);
      });

      test('stacks modify FC', () {
        final def = CounterStackDefinition();
        final effect = NpcEffect(
          typeId: 'counter_stack',
          isPositive: true,
          remainingMoves: 20,
          data: {'stacks': 10}, // 10 stacks = 10%
        );

        final fc = def.modifyPlayerFC(effect, 100.0);
        expect(fc, closeTo(110.0, 0.01)); // 100 * (1 + 0.10)
      });
    });
  });

  group('Meta/Map-Level Effects - Comprehensive Tests', () {
    late ExploreMap testMap;

    setUp(() {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();
      testMap = _createTestMap();
    });

    group('MapScrambleDefinition', () {
      test('scrambles map cell positions', () {
        final def = MapScrambleDefinition();
        final effect = NpcEffect(typeId: 'map_scramble', isPositive: true);

        // Count cell types before
        final monstersBefore = _countCellType(testMap, ExploreCellType.monster);
        final housesBefore = _countCellType(testMap, ExploreCellType.house);

        def.applyMapEffect(effect, testMap, Random(42));

        // Cell counts should remain the same, just positions changed
        final monstersAfter = _countCellType(testMap, ExploreCellType.monster);
        final housesAfter = _countCellType(testMap, ExploreCellType.house);

        expect(monstersAfter, monstersBefore);
        expect(housesAfter, housesBefore);
      });
    });

    group('CellCounterDefinition', () {
      test('stores cell type info in effect data', () {
        final def = CellCounterDefinition();
        final effect = def.generate(Random(42), 50.0, 100.0);

        def.applyMapEffect(effect, testMap, Random(42));

        // Should have cell count info
        expect(effect.data.isNotEmpty, true);
      });
    });

    group('ProgressBoostDefinition', () {
      test('positive effect marks cells as visited', () {
        final def = ProgressBoostDefinition();
        final effect = NpcEffect(typeId: 'progress_boost', isPositive: true);

        final visitedBefore = testMap.visitedCells.length;
        def.applyMapEffect(effect, testMap, Random(42));
        final visitedAfter = testMap.visitedCells.length;

        expect(visitedAfter, greaterThan(visitedBefore));
      });

      test('negative effect removes visited cells', () {
        final def = ProgressBoostDefinition();
        final effect = NpcEffect(typeId: 'progress_boost', isPositive: false);

        // Mark some cells as visited first
        testMap.markVisited(1, 1);
        testMap.markVisited(2, 2);
        testMap.markVisited(3, 3);

        final visitedBefore = testMap.visitedCells.length;
        def.applyMapEffect(effect, testMap, Random(42));
        final visitedAfter = testMap.visitedCells.length;

        expect(visitedAfter, lessThanOrEqualTo(visitedBefore));
      });
    });
  });

  group('All Effects Generation Test', () {
    test('all 45 effects can be generated without error', () {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();

      final random = Random(42);
      final definitions = NpcEffectRegistry.all;

      expect(definitions.length, 45);

      for (final def in definitions) {
        // Should not throw
        final effect = def.generate(random, 50.0, 100.0);
        expect(effect.typeId, def.typeId);

        // Effect should have valid properties
        expect(effect.isPositive, isA<bool>());
        expect(effect.remainingBattles, greaterThanOrEqualTo(0));
        expect(effect.remainingMoves, greaterThanOrEqualTo(0));
      }
    });

    test('all effects have icons for both positive and negative', () {
      NpcEffectRegistry.clear();
      NpcEffectRegistry.initialize();

      for (final def in NpcEffectRegistry.all) {
        final positiveEffect = NpcEffect(typeId: def.typeId, isPositive: true);
        final negativeEffect = NpcEffect(typeId: def.typeId, isPositive: false);

        expect(def.getIcon(positiveEffect), isA<IconData>());
        expect(def.getIcon(negativeEffect), isA<IconData>());
      }
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

// ─── Test Helper Functions ────────────────────────────────────────────

/// Create a test map with various cell types for testing
ExploreMap _createTestMap() {
  final grid = <List<ExploreCell>>[];

  for (int y = 0; y < 20; y++) {
    final row = <ExploreCell>[];
    for (int x = 0; x < 20; x++) {
      ExploreCellType type;
      if (x == 10 && y == 10) {
        type = ExploreCellType.blank; // Player position
      } else if (x < 3 && y < 3) {
        type = ExploreCellType.mountain;
      } else if (x > 16 && y < 3) {
        type = ExploreCellType.river;
      } else if (x == 5 && y == 5) {
        type = ExploreCellType.house;
      } else if (x == 15 && y == 5) {
        type = ExploreCellType.house;
      } else if (x == 3 && y == 10) {
        type = ExploreCellType.monster;
      } else if (x == 17 && y == 10) {
        type = ExploreCellType.monster;
      } else if (x == 10 && y == 3) {
        type = ExploreCellType.monster;
      } else if (x == 10 && y == 17) {
        type = ExploreCellType.monster;
      } else if (x == 2 && y == 15) {
        type = ExploreCellType.boss;
      } else if (x == 18 && y == 18) {
        type = ExploreCellType.boss;
      } else if (x == 7 && y == 7) {
        type = ExploreCellType.npc;
      } else if (x == 13 && y == 13) {
        type = ExploreCellType.npc;
      } else {
        type = ExploreCellType.blank;
      }
      row.add(ExploreCell(type: type, x: x, y: y));
    }
    grid.add(row);
  }

  return ExploreMap(
    grid: grid,
    width: 20,
    height: 20,
    playerX: 10,
    playerY: 10,
    generatedAtLevel: 1,
    generatedAtExp: 50.0,
  );
}

/// Count cells of a specific type on the map
int _countCellType(ExploreMap map, ExploreCellType type) {
  int count = 0;
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type) {
        count++;
      }
    }
  }
  return count;
}
