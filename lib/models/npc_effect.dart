import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import 'battle_result.dart';
import 'explore_map.dart';

// ─── Duration type for NPC effects ────────────────────────────────────

/// How an effect's lifetime is measured.
enum EffectDurationType {
  /// Effect is applied instantly and does not persist.
  instant,

  /// Effect lasts for a number of battles.
  battles,

  /// Effect lasts for a number of player moves.
  moves,
}

// ─── NpcEffectDefinition (Strategy interface) ─────────────────────────

/// Abstract base class for NPC effect definitions.
/// Each effect type implements this to self-describe its behavior and UI.
///
/// **Lifecycle hooks** (all have no-op defaults so existing effects are
/// unaffected when new hooks are added):
///
/// | Hook | When called |
/// |------|-------------|
/// | [applyImmediate] | Once, at encounter time |
/// | [applyBattle] | Each battle, to modify EXP |
/// | [modifyPlayerFC] | Before battle, modify player FC |
/// | [modifyEnemyFC] | Before battle, modify enemy FC |
/// | [overrideBattleOutcome] | After FC comparison, override result |
/// | [modifyFleeChance] | Before flee roll |
/// | [modifyFovRadius] | Each FOV update |
/// | [modifyHouseRestore] | When entering a house |
/// | [modifyNextNpcEffect] | After generating the *next* NPC effect |
/// | [applyMapEffect] | Once at encounter, mutate the map |
/// | [onMove] | Each time the player moves a cell |
abstract class NpcEffectDefinition {
  /// Unique identifier for this effect type (e.g. 'exp_gift_steal')
  String get typeId;

  /// How this effect's duration is tracked.
  EffectDurationType get durationType;

  /// Convenience: whether the effect fires once and is done.
  bool get isImmediate => durationType == EffectDurationType.instant;

  /// Generate a new effect instance of this type
  NpcEffect generate(Random random, double currentExp, double maxExp);

  // ── EXP hooks ──────────────────────────────────────────────────────

  /// Calculate the immediate EXP change for instant effects.
  /// Returns 0.0 for duration-based effects.
  double applyImmediate(
    NpcEffect effect,
    double currentExp,
    double maxExp,
    Random random,
  ) => 0.0;

  /// Modify the base EXP change during a battle for duration-based effects.
  /// Returns the (possibly modified) EXP change.
  /// [cellType] indicates whether the enemy was a monster or boss.
  double applyBattle(
    NpcEffect effect,
    double baseExpChange,
    bool isVictory,
    double currentExp,
    ExploreCellType cellType,
  ) => baseExpChange;

  /// Called after a battle completes, for side-effects (e.g. item drops).
  /// This is NOT for modifying EXP — use [applyBattle] for that.
  void onBattleComplete(
    NpcEffect effect,
    bool isVictory,
    ExploreCellType cellType,
    ExploreMap map,
  ) {}

  // ── FC / battle hooks ──────────────────────────────────────────────

  /// Modify the player's fighting capacity before a battle.
  double modifyPlayerFC(NpcEffect effect, double baseFC) => baseFC;

  /// Modify the enemy's fighting capacity before a battle.
  double modifyEnemyFC(
    NpcEffect effect,
    double baseEnemyFC,
    ExploreCellType cellType,
  ) => baseEnemyFC;

  /// Optionally override the battle outcome. Return `null` to use the
  /// normal judge logic.
  /// [cellType] indicates whether the enemy is a monster or boss.
  BattleOutcome? overrideBattleOutcome(
    NpcEffect effect,
    double playerFC,
    double enemyFC,
    ExploreCellType cellType,
  ) => null;

  /// Modify the base flee success chance (0.0–1.0).
  double modifyFleeChance(NpcEffect effect, double baseChance) => baseChance;

  // ── Map / movement hooks ───────────────────────────────────────────

  /// Modify the default FOV radius.
  int modifyFovRadius(NpcEffect effect, int baseRadius) => baseRadius;

  /// Called each time the player moves one cell (for move-duration effects).
  void onMove(NpcEffect effect, ExploreMap map) {}

  /// Mutate the map at encounter time (e.g. reveal cells, place items).
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {}

  // ── House / NPC chain hooks ────────────────────────────────────────

  /// Modify the AP restored when entering a house.
  int modifyHouseRestore(NpcEffect effect, int baseRestore) => baseRestore;

  /// Modify the AP cost for a particular action.
  /// [baseCost] is the base AP cost, [actionType] describes the action.
  int modifyAPCost(NpcEffect effect, int baseCost, String actionType) =>
      baseCost;

  /// Transform the *next* generated NPC effect (for NPC-chain effects).
  /// Return the (possibly modified) effect.
  NpcEffect modifyNextNpcEffect(NpcEffect self, NpcEffect generated) =>
      generated;

  // ── UI ─────────────────────────────────────────────────────────────

  /// Get the icon for this effect
  IconData getIcon(NpcEffect effect);

  /// Get the localized name for this effect
  String getName(NpcEffect effect, AppLocalizations l10n);

  /// Get the localized encounter description (shown when first meeting NPC)
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  });

  /// Get the localized active description (shown in the active effects list)
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n);
}

// ─── NpcEffectRegistry ────────────────────────────────────────────────

/// Central registry for all NPC effect definitions.
/// Effects register themselves here, and the rest of the system looks them up.
class NpcEffectRegistry {
  static final Map<String, NpcEffectDefinition> _definitions = {};
  static bool _builtInInitialized = false;

  /// Register an effect definition
  static void register(NpcEffectDefinition def) {
    _definitions[def.typeId] = def;
  }

  /// Get a definition by typeId
  static NpcEffectDefinition? get(String typeId) => _definitions[typeId];

  /// Get all registered definitions
  static List<NpcEffectDefinition> get all => _definitions.values.toList();

  /// Number of registered definitions
  static int get count => _definitions.length;

  /// Initialize all built-in effect definitions.
  /// Safe to call multiple times — only registers once.
  static void initialize() {
    if (_builtInInitialized) return;
    _builtInInitialized = true;
    register(ExpGiftStealDefinition());
    register(ExpMultiplierDefinition());
    register(ExpInsuranceDefinition());
    register(ExpFloorDefinition());
    register(ExpGambleDefinition());
  }

  /// Clear all registrations (for testing)
  static void clear() {
    _definitions.clear();
    _builtInInitialized = false;
  }
}

// ─── NpcEffect model ──────────────────────────────────────────────────

/// Represents an active NPC effect on the player.
/// Uses string-based typeId and flexible data map for extensibility.
class NpcEffect {
  /// The effect type identifier (matches NpcEffectDefinition.typeId)
  final String typeId;

  /// Whether this effect is positive (true) or negative (false)
  final bool isPositive;

  /// The duration type of this effect, stored for self-contained expiry checks.
  final EffectDurationType durationType;

  /// Remaining battle count for battle-duration effects (0 = instant/expired)
  int remainingBattles;

  /// Remaining move count for move-duration effects (0 = instant/expired)
  int remainingMoves;

  /// Flexible data storage for effect-specific values
  final Map<String, dynamic> data;

  NpcEffect({
    required this.typeId,
    required this.isPositive,
    EffectDurationType? durationType,
    this.remainingBattles = 0,
    this.remainingMoves = 0,
    Map<String, dynamic>? data,
  }) : durationType = durationType ?? _lookupDurationType(typeId),
       data = data ?? {};

  /// Lookup the durationType from registry, defaulting to instant if unknown.
  static EffectDurationType _lookupDurationType(String typeId) {
    final def = NpcEffectRegistry.get(typeId);
    return def?.durationType ?? EffectDurationType.instant;
  }

  /// Check if this is a duration-based effect that has expired.
  /// Unknown typeIds (orphaned effects) are considered expired.
  bool get isExpired {
    return switch (durationType) {
      EffectDurationType.instant => false,
      EffectDurationType.battles => remainingBattles <= 0,
      EffectDurationType.moves => remainingMoves <= 0,
    };
  }

  /// Check if this effect is duration-based (not instant).
  bool get isDurationBased => durationType != EffectDurationType.instant;

  /// Convenience getter for storedValue (backward compatibility)
  double get storedValue => (data['storedValue'] as num?)?.toDouble() ?? 0.0;

  /// Consume one battle charge for battle-duration effects
  void consumeBattle() {
    if (durationType == EffectDurationType.battles && remainingBattles > 0) {
      remainingBattles--;
    }
  }

  /// Consume one move charge for move-duration effects
  void consumeMove() {
    if (durationType == EffectDurationType.moves && remainingMoves > 0) {
      remainingMoves--;
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
    'typeId': typeId,
    'isPositive': isPositive,
    'durationType': durationType.index,
    'remainingBattles': remainingBattles,
    'remainingMoves': remainingMoves,
    'data': data,
  };

  /// Create from JSON with backward compatibility for legacy int-based format
  factory NpcEffect.fromJson(Map<String, dynamic> json) {
    // Ensure registry is initialized for isDurationBased/isExpired lookups
    NpcEffectRegistry.initialize();

    // Migrate from int-based 'type' to string 'typeId'
    String typeId;
    if (json.containsKey('typeId')) {
      typeId = json['typeId'] as String;
    } else {
      final typeIndex = json['type'] as int;
      typeId = _legacyTypeIdMap[typeIndex] ?? 'exp_gift_steal';
    }

    // Migrate 'storedValue' to 'data' map
    Map<String, dynamic> data;
    if (json.containsKey('data')) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    } else {
      data = {};
      final storedValue = (json['storedValue'] as num?)?.toDouble();
      if (storedValue != null && storedValue != 0.0) {
        data['storedValue'] = storedValue;
      }
    }

    // Parse durationType from JSON or look up from registry
    EffectDurationType? durationType;
    if (json.containsKey('durationType')) {
      final dtIndex = json['durationType'] as int;
      durationType = EffectDurationType.values[dtIndex];
    }

    return NpcEffect(
      typeId: typeId,
      isPositive: json['isPositive'] as bool,
      durationType: durationType,
      remainingBattles: json['remainingBattles'] as int? ?? 0,
      remainingMoves: json['remainingMoves'] as int? ?? 0,
      data: data,
    );
  }

  /// Maps old enum index to new typeId string for backward compatibility
  static const Map<int, String> _legacyTypeIdMap = {
    0: 'exp_gift_steal',
    1: 'exp_multiplier',
    2: 'exp_insurance',
    3: 'exp_floor',
    4: 'exp_gamble',
  };
}

// ─── NpcEffectService (thin delegator) ────────────────────────────────

/// Service for generating and applying NPC effects.
/// Delegates all type-specific behavior to the registry.
class NpcEffectService {
  final Random _random;

  NpcEffectService({Random? random}) : _random = random ?? Random() {
    NpcEffectRegistry.initialize();
  }

  /// Generate a random NPC effect.
  /// Active effects with [modifyNextNpcEffect] hooks are applied to the result.
  NpcEffect generateEffect({
    required double currentExp,
    required double maxExp,
    List<NpcEffect>? activeEffects,
  }) {
    final definitions = NpcEffectRegistry.all;
    final def = definitions[_random.nextInt(definitions.length)];
    var effect = def.generate(_random, currentExp, maxExp);

    // Let active NPC-chain effects modify the generated effect
    if (activeEffects != null) {
      for (final active in activeEffects) {
        if (active.isExpired) continue;
        final activeDef = NpcEffectRegistry.get(active.typeId);
        if (activeDef == null) continue;
        effect = activeDef.modifyNextNpcEffect(active, effect);
      }
    }

    return effect;
  }

  /// Calculate the immediate EXP change from an effect (for instant effects).
  /// Returns the EXP delta (positive or negative).
  double calculateImmediateExpChange(
    NpcEffect effect,
    double currentExp,
    double maxExp,
  ) {
    final def = NpcEffectRegistry.get(effect.typeId);
    if (def == null) return 0.0;
    return def.applyImmediate(effect, currentExp, maxExp, _random);
  }

  /// Apply active effects to a battle EXP change.
  /// Returns the modified EXP change after applying all relevant effects.
  double applyBattleEffects({
    required double baseExpChange,
    required bool isVictory,
    required double currentExp,
    required ExploreCellType cellType,
    required List<NpcEffect> activeEffects,
  }) {
    var modifiedExp = baseExpChange;

    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      modifiedExp = def.applyBattle(
        effect,
        modifiedExp,
        isVictory,
        currentExp,
        cellType,
      );
    }

    return modifiedExp;
  }

  /// Consume one battle charge from all battle-duration effects
  /// and remove expired ones. Returns the cleaned list.
  List<NpcEffect> consumeBattleCharges(List<NpcEffect> effects) {
    for (final effect in effects) {
      effect.consumeBattle();
    }
    effects.removeWhere((e) => e.isExpired);
    return effects;
  }

  /// Consume one move charge from all move-duration effects,
  /// call [NpcEffectDefinition.onMove], and remove expired ones.
  List<NpcEffect> consumeMoveCharges(List<NpcEffect> effects, ExploreMap map) {
    for (final effect in effects) {
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def != null && !effect.isExpired) {
        def.onMove(effect, map);
      }
      effect.consumeMove();
    }
    effects.removeWhere((e) => e.isExpired);
    return effects;
  }

  // ── FC / battle orchestration ────────────────────────────────────

  /// Apply all active FC modifiers to the player's base fighting capacity.
  double applyPlayerFCModifiers(double baseFC, List<NpcEffect> activeEffects) {
    var fc = baseFC;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      fc = def.modifyPlayerFC(effect, fc);
    }
    return fc;
  }

  /// Apply all active modifiers to an enemy's base fighting capacity.
  double applyEnemyFCModifiers(
    double baseEnemyFC,
    ExploreCellType cellType,
    List<NpcEffect> activeEffects,
  ) {
    var fc = baseEnemyFC;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      fc = def.modifyEnemyFC(effect, fc, cellType);
    }
    return fc;
  }

  /// Check whether any active effect overrides the battle outcome.
  /// Returns the first non-null override, or `null` to use default logic.
  BattleOutcome? getOutcomeOverride(
    double playerFC,
    double enemyFC,
    ExploreCellType cellType,
    List<NpcEffect> activeEffects,
  ) {
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      final override = def.overrideBattleOutcome(
        effect,
        playerFC,
        enemyFC,
        cellType,
      );
      if (override != null) return override;
    }
    return null;
  }

  /// Apply all active flee-chance modifiers.
  double applyFleeModifiers(double baseChance, List<NpcEffect> activeEffects) {
    var chance = baseChance;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      chance = def.modifyFleeChance(effect, chance);
    }
    return chance.clamp(0.0, 1.0);
  }

  // ── Map / movement orchestration ─────────────────────────────────

  /// Apply all active FOV modifiers.
  int applyFovModifiers(int baseRadius, List<NpcEffect> activeEffects) {
    var radius = baseRadius;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      radius = def.modifyFovRadius(effect, radius);
    }
    return radius < 1 ? 1 : radius; // at least 1
  }

  /// Apply all encounter-time map mutations.
  void applyMapEffects(NpcEffect effect, ExploreMap map) {
    final def = NpcEffectRegistry.get(effect.typeId);
    if (def == null) return;
    def.applyMapEffect(effect, map, _random);
  }

  // ── House / NPC chain orchestration ──────────────────────────────

  /// Apply all active house-restore modifiers.
  int applyHouseRestoreModifiers(
    int baseRestore,
    List<NpcEffect> activeEffects,
  ) {
    var restore = baseRestore;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      restore = def.modifyHouseRestore(effect, restore);
    }
    return restore < 0 ? 0 : restore; // at least 0
  }

  /// Apply all active AP cost modifiers.
  int applyAPCostModifiers(
    int baseCost,
    String actionType,
    List<NpcEffect> activeEffects,
  ) {
    var cost = baseCost;
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      cost = def.modifyAPCost(effect, cost, actionType);
    }
    return cost < 0 ? 0 : cost; // at least 0
  }

  /// Notify all active effects that a battle completed (side-effects only).
  void notifyBattleComplete(
    bool isVictory,
    ExploreCellType cellType,
    ExploreMap map,
    List<NpcEffect> activeEffects,
  ) {
    for (final effect in activeEffects) {
      if (effect.isExpired) continue;
      final def = NpcEffectRegistry.get(effect.typeId);
      if (def == null) continue;
      def.onBattleComplete(effect, isVictory, cellType, map);
    }
  }
}

// ─── Concrete Effect Definitions ──────────────────────────────────────

/// EXP gift/steal: ±5-10% maxExp immediate change
class ExpGiftStealDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'exp_gift_steal';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  double applyImmediate(
    NpcEffect effect,
    double currentExp,
    double maxExp,
    Random random,
  ) {
    final percent =
        NpcEffectConstants.giftStealMinPercent +
        random.nextDouble() *
            (NpcEffectConstants.giftStealMaxPercent -
                NpcEffectConstants.giftStealMinPercent);
    final amount = maxExp * percent;
    return effect.isPositive ? amount : -amount;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.card_giftcard : Icons.money_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameExpGiftSteal;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    final amount = NumberFormatter.format((expChange ?? 0).abs());
    return effect.isPositive
        ? l10n.npcEffectExpGiftPositive(amount)
        : l10n.npcEffectExpStealNegative(amount);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// EXP multiplier: Next N battles give 2x or 0.5x EXP
class ExpMultiplierDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'exp_multiplier';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.multiplierDurationBattles,
    );
  }

  @override
  double applyBattle(
    NpcEffect effect,
    double baseExpChange,
    bool isVictory,
    double currentExp,
    ExploreCellType cellType,
  ) {
    if (effect.isPositive) {
      return baseExpChange * NpcEffectConstants.positiveMultiplier;
    } else {
      return baseExpChange * NpcEffectConstants.negativeMultiplier;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.speed;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameExpMultiplier;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectExpMultiplierPositive(
            NpcEffectConstants.multiplierDurationBattles,
          )
        : l10n.npcEffectExpMultiplierNegative(
            NpcEffectConstants.multiplierDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescMultiplierPositive
        : l10n.npcEffectDescMultiplierNegative;
  }
}

/// EXP insurance: Next loss no penalty / Next win no reward
class ExpInsuranceDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'exp_insurance';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.insuranceDurationBattles,
    );
  }

  @override
  double applyBattle(
    NpcEffect effect,
    double baseExpChange,
    bool isVictory,
    double currentExp,
    ExploreCellType cellType,
  ) {
    if (effect.isPositive && !isVictory) {
      // Positive insurance: no EXP penalty on loss
      return 0.0;
    } else if (!effect.isPositive && isVictory) {
      // Negative insurance: no EXP reward on win
      return 0.0;
    }
    return baseExpChange;
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.shield;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameExpInsurance;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectExpInsurancePositive
        : l10n.npcEffectExpInsuranceNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescInsurancePositive
        : l10n.npcEffectDescInsuranceNegative;
  }
}

/// EXP floor: Current EXP can't drop below (or above) current value
/// for N battles
class ExpFloorDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'exp_floor';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.floorDurationBattles,
      data: {'storedValue': currentExp},
    );
  }

  @override
  double applyBattle(
    NpcEffect effect,
    double baseExpChange,
    bool isVictory,
    double currentExp,
    ExploreCellType cellType,
  ) {
    if (effect.isPositive) {
      // Positive floor: EXP can't drop below stored value
      final projectedExp = currentExp + baseExpChange;
      if (projectedExp < effect.storedValue) {
        return effect.storedValue - currentExp;
      }
    } else {
      // Negative floor (ceiling): EXP can't gain above stored value
      final projectedExp = currentExp + baseExpChange;
      if (projectedExp > effect.storedValue) {
        return effect.storedValue - currentExp;
      }
    }
    return baseExpChange;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.arrow_downward : Icons.arrow_upward;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameExpFloor;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectExpFloorPositive(
            NpcEffectConstants.floorDurationBattles,
          )
        : l10n.npcEffectExpFloorNegative(
            NpcEffectConstants.floorDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescFloorPositive(
            NumberFormatter.format(effect.storedValue),
          )
        : l10n.npcEffectDescFloorNegative(
            NumberFormatter.format(effect.storedValue),
          );
  }
}

/// EXP gamble: Double or halve current EXP immediately
class ExpGambleDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'exp_gamble';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  double applyImmediate(
    NpcEffect effect,
    double currentExp,
    double maxExp,
    Random random,
  ) {
    if (effect.isPositive) {
      // Double current EXP → gain = currentExp
      return currentExp;
    } else {
      // Halve current EXP → lose half
      return -(currentExp * NpcEffectConstants.gambleHalveFraction);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.casino;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameExpGamble;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectExpGamblePositive
        : l10n.npcEffectExpGambleNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}
