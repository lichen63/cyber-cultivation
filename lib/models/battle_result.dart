import 'dart:math';

import '../constants.dart';
import 'explore_map.dart';

/// Represents the outcome of a battle
enum BattleOutcome { victory, defeat }

/// Result of a battle encounter
class BattleResult {
  final ExploreCellType enemyType;
  final double playerFC;
  final double enemyFC;
  final BattleOutcome outcome;
  final double expChange; // Positive for win, negative for loss

  const BattleResult({
    required this.enemyType,
    required this.playerFC,
    required this.enemyFC,
    required this.outcome,
    required this.expChange,
  });

  bool get isVictory => outcome == BattleOutcome.victory;

  /// Get the power ratio (player / enemy)
  double get powerRatio => enemyFC > 0 ? playerFC / enemyFC : double.infinity;
}

/// Service for calculating battle mechanics
class BattleService {
  final Random _random;

  BattleService({Random? random}) : _random = random ?? Random();

  /// Calculate the enemy's base level based on player's realm
  /// Enemies scale to the start of the player's current realm
  int calculateEnemyBaseLevel(int playerLevel) {
    if (playerLevel < 10) return 1;
    return (playerLevel ~/ 10) * 10;
  }

  /// Calculate fighting capacity for a given level
  /// Uses the same formula as the player
  double calculateFCForLevel(int level, {double expProgress = 0.0}) {
    // Base power: exponential growth with level
    final basePower =
        ExploreConstants.initialBasePower *
        pow(ExploreConstants.levelGrowthFactor, level - 1);

    // EXP contribution
    final expBonus =
        basePower * ExploreConstants.expProgressMultiplier * expProgress;

    // Realm bonus (every 10 levels)
    final realm = (level - 1) ~/ 10;
    final realmBonus = realm > 0
        ? ExploreConstants.realmBaseBonus *
              pow(ExploreConstants.realmGrowthFactor, realm - 1)
        : 0.0;

    return basePower + expBonus + realmBonus;
  }

  /// Calculate enemy fighting capacity with randomness
  double calculateEnemyFC(
    int playerLevel,
    double playerMaxExp,
    ExploreCellType enemyType,
  ) {
    // Get the base level for enemies in this realm
    final enemyBaseLevel = calculateEnemyBaseLevel(playerLevel);

    // Calculate enemy base FC using same formula (no exp progress for enemies)
    final enemyBaseFC = calculateFCForLevel(enemyBaseLevel);

    // Get multiplier range and variance based on enemy type
    final (minRatio, maxRatio, variance) = switch (enemyType) {
      ExploreCellType.monster => (
        ExploreConstants.monsterMinFCRatio,
        ExploreConstants.monsterMaxFCRatio,
        ExploreConstants.monsterFCVariance,
      ),
      ExploreCellType.boss => (
        ExploreConstants.bossMinFCRatio,
        ExploreConstants.bossMaxFCRatio,
        ExploreConstants.bossFCVariance,
      ),
      _ => throw ArgumentError('Invalid enemy type: $enemyType'),
    };

    // Random base multiplier within range
    final baseMultiplier =
        minRatio + _random.nextDouble() * (maxRatio - minRatio);

    // Apply random variance (±variance%)
    final varianceValue = (_random.nextDouble() * 2 - 1) * variance;
    final varianceFactor = 1.0 + varianceValue;

    return enemyBaseFC * baseMultiplier * varianceFactor;
  }

  /// Judge the battle outcome based on fighting capacities
  BattleOutcome judgeBattle(double playerFC, double enemyFC) {
    if (enemyFC <= 0) return BattleOutcome.victory;

    final ratio = playerFC / enemyFC;

    // Auto-win if significantly stronger
    if (ratio >= ExploreConstants.battleAutoWinRatio) {
      return BattleOutcome.victory;
    }

    // Auto-lose if significantly weaker
    if (ratio <= ExploreConstants.battleAutoLoseRatio) {
      return BattleOutcome.defeat;
    }

    // Close match - random chance based on ratio
    // ratio = 0.9 -> winChance = 0.25
    // ratio = 1.0 -> winChance = 0.50
    // ratio = 1.1 -> winChance = 0.75
    final winChance = 0.5 + (ratio - 1.0) * 2.5;
    return _random.nextDouble() < winChance
        ? BattleOutcome.victory
        : BattleOutcome.defeat;
  }

  /// Calculate EXP reward or penalty
  double calculateExpChange(
    BattleOutcome outcome,
    ExploreCellType enemyType,
    double currentExp,
    double maxExp,
  ) {
    if (outcome == BattleOutcome.victory) {
      // Reward based on enemy type
      final rewardRatio = switch (enemyType) {
        ExploreCellType.monster => ExploreConstants.monsterExpRewardRatio,
        ExploreCellType.boss => ExploreConstants.bossExpRewardRatio,
        _ => 0.0,
      };
      return maxExp * rewardRatio;
    } else {
      // Loss: percentage of current exp (always negative)
      return -(currentExp * ExploreConstants.expLossOnDefeatRatio);
    }
  }

  /// Attempt to flee from battle
  /// Returns true if flee succeeds, false if caught
  bool attemptFlee() {
    return _random.nextDouble() < ExploreConstants.fleeBaseSuccessRate;
  }

  /// Perform a complete battle and return the result
  BattleResult performBattle({
    required int playerLevel,
    required double playerCurrentExp,
    required double playerMaxExp,
    required double playerFC,
    required ExploreCellType enemyType,
  }) {
    // Calculate enemy FC
    final enemyFC = calculateEnemyFC(playerLevel, playerMaxExp, enemyType);

    // Judge battle outcome
    final outcome = judgeBattle(playerFC, enemyFC);

    // Calculate EXP change
    final expChange = calculateExpChange(
      outcome,
      enemyType,
      playerCurrentExp,
      playerMaxExp,
    );

    return BattleResult(
      enemyType: enemyType,
      playerFC: playerFC,
      enemyFC: enemyFC,
      outcome: outcome,
      expChange: expChange,
    );
  }
}
