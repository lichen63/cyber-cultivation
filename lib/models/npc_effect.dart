import 'dart:math';

import '../constants.dart';

/// Types of NPC effects that can be triggered
enum NpcEffectType {
  /// EXP gift/steal: ±5-10% maxExp immediate change
  expGiftSteal,

  /// EXP multiplier: Next N battles give 2x or 0.5x EXP
  expMultiplier,

  /// EXP insurance: Next loss no penalty / Next win no reward
  expInsurance,

  /// EXP floor: Current EXP can't drop below (or above) current value for N battles
  expFloor,

  /// EXP gamble: Double or halve current EXP immediately
  expGamble,
}

/// Represents an active NPC effect on the player
class NpcEffect {
  final NpcEffectType type;

  /// Whether this effect is positive (true) or negative (false)
  final bool isPositive;

  /// Remaining battle count for duration-based effects (0 = permanent/instant)
  int remainingBattles;

  /// Stored value for floor effects (the EXP floor/ceiling value)
  final double storedValue;

  NpcEffect({
    required this.type,
    required this.isPositive,
    this.remainingBattles = 0,
    this.storedValue = 0.0,
  });

  /// Check if this is a duration-based effect that has expired
  bool get isExpired => _isDurationBased && remainingBattles <= 0;

  /// Check if this effect is duration-based
  bool get _isDurationBased =>
      type == NpcEffectType.expMultiplier ||
      type == NpcEffectType.expInsurance ||
      type == NpcEffectType.expFloor;

  /// Consume one battle charge for duration-based effects
  void consumeBattle() {
    if (_isDurationBased && remainingBattles > 0) {
      remainingBattles--;
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'isPositive': isPositive,
    'remainingBattles': remainingBattles,
    'storedValue': storedValue,
  };

  /// Create from JSON
  factory NpcEffect.fromJson(Map<String, dynamic> json) => NpcEffect(
    type: NpcEffectType.values[json['type'] as int],
    isPositive: json['isPositive'] as bool,
    remainingBattles: json['remainingBattles'] as int? ?? 0,
    storedValue: (json['storedValue'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Service for generating and applying NPC effects
class NpcEffectService {
  final Random _random;

  NpcEffectService({Random? random}) : _random = random ?? Random();

  /// Generate a random NPC effect
  NpcEffect generateEffect({
    required double currentExp,
    required double maxExp,
  }) {
    final effectType =
        NpcEffectType.values[_random.nextInt(NpcEffectType.values.length)];
    final isPositive = _random.nextBool();

    switch (effectType) {
      case NpcEffectType.expGiftSteal:
        // Immediate effect, no remaining battles needed
        return NpcEffect(type: effectType, isPositive: isPositive);

      case NpcEffectType.expMultiplier:
        return NpcEffect(
          type: effectType,
          isPositive: isPositive,
          remainingBattles: NpcEffectConstants.multiplierDurationBattles,
        );

      case NpcEffectType.expInsurance:
        // Insurance lasts for 1 battle (next loss or next win)
        return NpcEffect(
          type: effectType,
          isPositive: isPositive,
          remainingBattles: NpcEffectConstants.insuranceDurationBattles,
        );

      case NpcEffectType.expFloor:
        return NpcEffect(
          type: effectType,
          isPositive: isPositive,
          remainingBattles: NpcEffectConstants.floorDurationBattles,
          storedValue: currentExp,
        );

      case NpcEffectType.expGamble:
        // Immediate effect
        return NpcEffect(type: effectType, isPositive: isPositive);
    }
  }

  /// Calculate the immediate EXP change from an effect (for instant effects)
  /// Returns the EXP delta (positive or negative)
  double calculateImmediateExpChange(
    NpcEffect effect,
    double currentExp,
    double maxExp,
  ) {
    switch (effect.type) {
      case NpcEffectType.expGiftSteal:
        // ±5-10% of maxExp
        final percent =
            NpcEffectConstants.giftStealMinPercent +
            _random.nextDouble() *
                (NpcEffectConstants.giftStealMaxPercent -
                    NpcEffectConstants.giftStealMinPercent);
        final amount = maxExp * percent;
        return effect.isPositive ? amount : -amount;

      case NpcEffectType.expGamble:
        if (effect.isPositive) {
          // Double current EXP → gain = currentExp
          return currentExp;
        } else {
          // Halve current EXP → lose half
          return -(currentExp * NpcEffectConstants.gambleHalveFraction);
        }

      default:
        return 0.0; // Duration-based effects have no immediate EXP change
    }
  }

  /// Apply active effects to a battle EXP change
  /// Returns the modified EXP change after applying all relevant effects
  double applyBattleEffects({
    required double baseExpChange,
    required bool isVictory,
    required double currentExp,
    required List<NpcEffect> activeEffects,
  }) {
    var modifiedExp = baseExpChange;

    for (final effect in activeEffects) {
      if (effect.isExpired) continue;

      switch (effect.type) {
        case NpcEffectType.expMultiplier:
          if (effect.isPositive) {
            modifiedExp *= NpcEffectConstants.positiveMultiplier;
          } else {
            modifiedExp *= NpcEffectConstants.negativeMultiplier;
          }

        case NpcEffectType.expInsurance:
          if (effect.isPositive && !isVictory) {
            // Positive insurance: no EXP penalty on loss
            modifiedExp = 0.0;
          } else if (!effect.isPositive && isVictory) {
            // Negative insurance: no EXP reward on win
            modifiedExp = 0.0;
          }

        case NpcEffectType.expFloor:
          if (effect.isPositive) {
            // Positive floor: EXP can't drop below stored value
            final projectedExp = currentExp + modifiedExp;
            if (projectedExp < effect.storedValue) {
              modifiedExp = effect.storedValue - currentExp;
            }
          } else {
            // Negative floor (ceiling): EXP can't gain above stored value
            final projectedExp = currentExp + modifiedExp;
            if (projectedExp > effect.storedValue) {
              modifiedExp = effect.storedValue - currentExp;
            }
          }

        default:
          break; // Instant effects don't apply during battles
      }
    }

    return modifiedExp;
  }

  /// Consume one battle charge from all duration-based effects
  /// and remove expired ones. Returns the cleaned list.
  List<NpcEffect> consumeBattleCharges(List<NpcEffect> effects) {
    for (final effect in effects) {
      effect.consumeBattle();
    }
    effects.removeWhere((e) => e.isExpired);
    return effects;
  }
}
