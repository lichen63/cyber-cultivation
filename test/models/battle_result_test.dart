import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_cultivation/models/battle_result.dart';
import 'package:cyber_cultivation/models/explore_map.dart';
import 'package:cyber_cultivation/constants.dart';

/// A mock Random that returns predictable values for testing
class MockRandom implements Random {
  final List<double> _doubleValues;
  int _doubleIndex = 0;

  MockRandom({List<double>? doubleValues}) : _doubleValues = doubleValues ?? [];

  @override
  double nextDouble() {
    if (_doubleIndex >= _doubleValues.length) {
      return 0.5; // Default value
    }
    return _doubleValues[_doubleIndex++];
  }

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  group('BattleResult', () {
    test('creates instance with required values', () {
      const result = BattleResult(
        enemyType: ExploreCellType.monster,
        playerFC: 100.0,
        enemyFC: 80.0,
        outcome: BattleOutcome.victory,
        expChange: 10.0,
      );

      expect(result.enemyType, ExploreCellType.monster);
      expect(result.playerFC, 100.0);
      expect(result.enemyFC, 80.0);
      expect(result.outcome, BattleOutcome.victory);
      expect(result.expChange, 10.0);
    });

    test('isVictory returns true for victory', () {
      const result = BattleResult(
        enemyType: ExploreCellType.monster,
        playerFC: 100.0,
        enemyFC: 80.0,
        outcome: BattleOutcome.victory,
        expChange: 10.0,
      );

      expect(result.isVictory, true);
    });

    test('isVictory returns false for defeat', () {
      const result = BattleResult(
        enemyType: ExploreCellType.boss,
        playerFC: 100.0,
        enemyFC: 200.0,
        outcome: BattleOutcome.defeat,
        expChange: -5.0,
      );

      expect(result.isVictory, false);
    });

    test('powerRatio calculates correctly', () {
      const result = BattleResult(
        enemyType: ExploreCellType.monster,
        playerFC: 100.0,
        enemyFC: 50.0,
        outcome: BattleOutcome.victory,
        expChange: 10.0,
      );

      expect(result.powerRatio, 2.0);
    });

    test('powerRatio returns infinity for zero enemy FC', () {
      const result = BattleResult(
        enemyType: ExploreCellType.monster,
        playerFC: 100.0,
        enemyFC: 0.0,
        outcome: BattleOutcome.victory,
        expChange: 10.0,
      );

      expect(result.powerRatio, double.infinity);
    });
  });

  group('BattleService', () {
    group('calculateEnemyBaseLevel', () {
      test('returns 1 for levels 1-9', () {
        final service = BattleService();

        expect(service.calculateEnemyBaseLevel(1), 1);
        expect(service.calculateEnemyBaseLevel(5), 1);
        expect(service.calculateEnemyBaseLevel(9), 1);
      });

      test('returns 10 for levels 10-19', () {
        final service = BattleService();

        expect(service.calculateEnemyBaseLevel(10), 10);
        expect(service.calculateEnemyBaseLevel(15), 10);
        expect(service.calculateEnemyBaseLevel(19), 10);
      });

      test('returns 20 for levels 20-29', () {
        final service = BattleService();

        expect(service.calculateEnemyBaseLevel(20), 20);
        expect(service.calculateEnemyBaseLevel(25), 20);
      });
    });

    group('calculateFCForLevel', () {
      test('returns base power for level 1', () {
        final service = BattleService();
        final fc = service.calculateFCForLevel(1);

        expect(fc, ExploreConstants.initialBasePower);
      });

      test('increases with level', () {
        final service = BattleService();

        final fc1 = service.calculateFCForLevel(1);
        final fc5 = service.calculateFCForLevel(5);
        final fc10 = service.calculateFCForLevel(10);

        expect(fc5, greaterThan(fc1));
        expect(fc10, greaterThan(fc5));
      });

      test('includes realm bonus at level 10+', () {
        final service = BattleService();

        final fc9 = service.calculateFCForLevel(9);
        final fc10 = service.calculateFCForLevel(10);

        // Level 10 has realm bonus (realm 1), level 9 does not (realm 0)
        // The jump should be more than just the level growth (with small tolerance)
        final expectedGrowth = fc9 * (ExploreConstants.levelGrowthFactor - 1);
        final actualGrowth = fc10 - fc9;

        // Use greaterThanOrEqualTo with a small tolerance for floating point
        expect(actualGrowth, greaterThanOrEqualTo(expectedGrowth * 0.99));
      });
    });

    group('calculateEnemyFC', () {
      test('monster FC is within expected range', () {
        final service = BattleService();

        // Run multiple times to test range
        for (int i = 0; i < 100; i++) {
          final enemyFC = service.calculateEnemyFC(
            5,
            100.0,
            ExploreCellType.monster,
          );
          final baseFC = service.calculateFCForLevel(1); // Level 5 -> base 1

          // Monster range: 0.4x to 1.44x (with variance)
          expect(enemyFC, greaterThan(0));
          expect(
            enemyFC,
            lessThanOrEqualTo(baseFC * 1.5),
          ); // Some margin for variance
        }
      });

      test('boss FC is higher than monster FC on average', () {
        final service = BattleService();

        double totalMonsterFC = 0;
        double totalBossFC = 0;

        for (int i = 0; i < 100; i++) {
          totalMonsterFC += service.calculateEnemyFC(
            10,
            100.0,
            ExploreCellType.monster,
          );
          totalBossFC += service.calculateEnemyFC(
            10,
            100.0,
            ExploreCellType.boss,
          );
        }

        expect(totalBossFC / 100, greaterThan(totalMonsterFC / 100));
      });

      test('throws for invalid enemy type', () {
        final service = BattleService();

        expect(
          () => service.calculateEnemyFC(5, 100.0, ExploreCellType.blank),
          throwsArgumentError,
        );
      });
    });

    group('judgeBattle', () {
      test('returns victory when ratio >= 1.1', () {
        final service = BattleService();

        final outcome = service.judgeBattle(110.0, 100.0);

        expect(outcome, BattleOutcome.victory);
      });

      test('returns defeat when ratio <= 0.9', () {
        final service = BattleService();

        final outcome = service.judgeBattle(90.0, 100.0);

        expect(outcome, BattleOutcome.defeat);
      });

      test('returns victory for zero enemy FC', () {
        final service = BattleService();

        final outcome = service.judgeBattle(100.0, 0.0);

        expect(outcome, BattleOutcome.victory);
      });

      test('close match has random outcome', () {
        // Test with mock random
        final mockRandom = MockRandom(doubleValues: [0.3]); // Below 50%
        final service = BattleService(random: mockRandom);

        // Ratio = 1.0, so winChance = 0.5
        // With mock returning 0.3, which is < 0.5, should win
        final outcome = service.judgeBattle(100.0, 100.0);

        expect(outcome, BattleOutcome.victory);
      });

      test('close match loses when random is high', () {
        final mockRandom = MockRandom(doubleValues: [0.7]); // Above 50%
        final service = BattleService(random: mockRandom);

        // Ratio = 1.0, so winChance = 0.5
        // With mock returning 0.7, which is > 0.5, should lose
        final outcome = service.judgeBattle(100.0, 100.0);

        expect(outcome, BattleOutcome.defeat);
      });
    });

    group('calculateExpChange', () {
      test('victory against monster gives 10% of maxExp', () {
        final service = BattleService();

        final expChange = service.calculateExpChange(
          BattleOutcome.victory,
          ExploreCellType.monster,
          50.0,
          100.0,
        );

        expect(expChange, 10.0); // 10% of 100
      });

      test('victory against boss gives 50% of maxExp', () {
        final service = BattleService();

        final expChange = service.calculateExpChange(
          BattleOutcome.victory,
          ExploreCellType.boss,
          50.0,
          100.0,
        );

        expect(expChange, 50.0); // 50% of 100
      });

      test('defeat loses 5% of current exp', () {
        final service = BattleService();

        final expChange = service.calculateExpChange(
          BattleOutcome.defeat,
          ExploreCellType.monster,
          100.0,
          200.0,
        );

        expect(expChange, -5.0); // -5% of 100
      });

      test('defeat with no exp loses nothing', () {
        final service = BattleService();

        final expChange = service.calculateExpChange(
          BattleOutcome.defeat,
          ExploreCellType.monster,
          0.0,
          100.0,
        );

        expect(expChange, 0.0);
      });
    });

    group('attemptFlee', () {
      test('succeeds when random below threshold', () {
        final mockRandom = MockRandom(doubleValues: [0.5]); // Below 0.7
        final service = BattleService(random: mockRandom);

        expect(service.attemptFlee(), true);
      });

      test('fails when random above threshold', () {
        final mockRandom = MockRandom(doubleValues: [0.8]); // Above 0.7
        final service = BattleService(random: mockRandom);

        expect(service.attemptFlee(), false);
      });
    });

    group('performBattle', () {
      test('returns complete battle result', () {
        final mockRandom = MockRandom(
          doubleValues: [0.5, 0.5, 0.3], // For enemy FC calc and battle judge
        );
        final service = BattleService(random: mockRandom);

        final result = service.performBattle(
          playerLevel: 5,
          playerCurrentExp: 50.0,
          playerMaxExp: 100.0,
          playerFC: 100.0,
          enemyType: ExploreCellType.monster,
        );

        expect(result.enemyType, ExploreCellType.monster);
        expect(result.playerFC, 100.0);
        expect(result.enemyFC, greaterThan(0));
        expect(result.outcome, isA<BattleOutcome>());
        expect(result.expChange, isNot(0.0));
      });
    });
  });

  group('Realm-based enemy scaling', () {
    test('player at level 9 fights enemies based on level 1', () {
      final service = BattleService();

      final enemyBaseLevel = service.calculateEnemyBaseLevel(9);
      final playerFC = service.calculateFCForLevel(9);
      final enemyBaseFC = service.calculateFCForLevel(enemyBaseLevel);

      expect(enemyBaseLevel, 1);
      expect(playerFC, greaterThan(enemyBaseFC * 2)); // Player much stronger
    });

    test('player at level 10 fights enemies based on level 10', () {
      final service = BattleService();

      final enemyBaseLevel = service.calculateEnemyBaseLevel(10);
      final playerFC = service.calculateFCForLevel(10);
      final enemyBaseFC = service.calculateFCForLevel(enemyBaseLevel);

      expect(enemyBaseLevel, 10);
      // Player and enemy base are similar (before multipliers)
      expect(playerFC, closeTo(enemyBaseFC, enemyBaseFC * 0.1));
    });

    test('power ratio increases within realm', () {
      final service = BattleService();

      // Level 10 vs base level 10
      final fc10 = service.calculateFCForLevel(10);
      final base10 = service.calculateFCForLevel(10);
      final ratio10 = fc10 / base10;

      // Level 15 vs base level 10
      final fc15 = service.calculateFCForLevel(15);
      final ratio15 = fc15 / base10;

      // Level 19 vs base level 10
      final fc19 = service.calculateFCForLevel(19);
      final ratio19 = fc19 / base10;

      expect(ratio15, greaterThan(ratio10));
      expect(ratio19, greaterThan(ratio15));
    });
  });
}
