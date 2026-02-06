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
    // FC / Battle effects
    register(FcBuffDefinition());
    register(GuaranteedOutcomeDefinition());
    register(FleeMasteryDefinition());
    register(FirstStrikeDefinition());
    register(GlassCannonDefinition());
    // Map / Terrain effects
    register(PathClearingDefinition());
    register(RiverBridgeDefinition());
    register(MonsterCleanseDefinition());
    register(BossShiftDefinition());
    register(SafeZoneDefinition());
    register(TerrainSwapDefinition());
    // Vision / Revelation effects
    register(FovModifyDefinition());
    register(BossRadarDefinition());
    register(NpcRadarDefinition());
    register(MapRevealDefinition());
    register(MonsterRadarDefinition());
    register(HouseRadarDefinition());
    // Movement effects
    register(TeleportDefinition());
    register(SpeedBoostDefinition());
    register(TeleportHouseDefinition());
    register(PathfinderDefinition());
    // Monster / Enemy manipulation effects
    register(WeakenEnemiesDefinition());
    register(MonsterConversionDefinition());
    register(BossDowngradeDefinition());
    register(MonsterFreezeDefinition());
    register(ClearWaveDefinition());
    register(MonsterMagnetDefinition());
    // NPC Chain effects
    register(NpcBlessingChainDefinition());
    register(NpcSpawnDefinition());
    register(NpcUpgradeDefinition());
    // House effects
    register(HouseSpawnDefinition());
    register(HouseUpgradeDefinition());
    // Combo / Conditional effects
    register(RiskRewardDefinition());
    register(SacrificeDefinition());
    register(AllInDefinition());
    register(MirrorDefinition());
    register(CounterStackDefinition());
    // Meta / Map-Level effects
    register(MapScrambleDefinition());
    register(CellCounterDefinition());
    register(ProgressBoostDefinition());
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

// ─── FC / Battle Effect Definitions ───────────────────────────────────

/// FC buff/debuff: ±20% FC for next N battles
class FcBuffDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'fc_buff';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.fcBuffDurationBattles,
    );
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    if (effect.isPositive) {
      return baseFC * NpcEffectConstants.fcBuffMultiplier;
    } else {
      return baseFC * NpcEffectConstants.fcDebuffMultiplier;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.trending_up : Icons.trending_down;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameFcBuff;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectFcBuffPositive(NpcEffectConstants.fcBuffDurationBattles)
        : l10n.npcEffectFcBuffNegative(
            NpcEffectConstants.fcBuffDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescFcBuffPositive
        : l10n.npcEffectDescFcBuffNegative;
  }
}

/// Guaranteed outcome: next battle guaranteed win/loss
class GuaranteedOutcomeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'guaranteed_outcome';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.guaranteedOutcomeDurationBattles,
    );
  }

  @override
  BattleOutcome? overrideBattleOutcome(
    NpcEffect effect,
    double playerFC,
    double enemyFC,
    ExploreCellType cellType,
  ) {
    return effect.isPositive ? BattleOutcome.victory : BattleOutcome.defeat;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.emoji_events : Icons.dangerous;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameGuaranteedOutcome;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectGuaranteedOutcomePositive
        : l10n.npcEffectGuaranteedOutcomeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescGuaranteedOutcomePositive
        : l10n.npcEffectDescGuaranteedOutcomeNegative;
  }
}

/// Flee mastery: next N flee attempts always succeed/fail
class FleeMasteryDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'flee_mastery';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.fleeMasteryDurationBattles,
    );
  }

  @override
  double modifyFleeChance(NpcEffect effect, double baseChance) {
    // 1.0 = always succeed, 0.0 = always fail
    return effect.isPositive ? 1.0 : 0.0;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.directions_run : Icons.block;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameFleeMastery;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectFleeMasteryPositive(
            NpcEffectConstants.fleeMasteryDurationBattles,
          )
        : l10n.npcEffectFleeMasteryNegative(
            NpcEffectConstants.fleeMasteryDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescFleeMasteryPositive
        : l10n.npcEffectDescFleeMasteryNegative;
  }
}

/// First strike: enemy/player FC counted at 50%
class FirstStrikeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'first_strike';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.firstStrikeDurationBattles,
    );
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    // Negative: player FC at 50%
    return effect.isPositive
        ? baseFC
        : baseFC * NpcEffectConstants.firstStrikeFCMultiplier;
  }

  @override
  double modifyEnemyFC(
    NpcEffect effect,
    double baseEnemyFC,
    ExploreCellType cellType,
  ) {
    // Positive: enemy FC at 50%
    return effect.isPositive
        ? baseEnemyFC * NpcEffectConstants.firstStrikeFCMultiplier
        : baseEnemyFC;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.flash_on : Icons.flash_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameFirstStrike;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectFirstStrikePositive
        : l10n.npcEffectFirstStrikeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescFirstStrikePositive
        : l10n.npcEffectDescFirstStrikeNegative;
  }
}

/// Glass cannon: ±50% FC for next 1 battle
class GlassCannonDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'glass_cannon';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.glassCannonDurationBattles,
    );
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    if (effect.isPositive) {
      return baseFC * NpcEffectConstants.glassCannonPositiveMultiplier;
    } else {
      return baseFC * NpcEffectConstants.glassCannonNegativeMultiplier;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.bolt : Icons.broken_image;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameGlassCannon;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectGlassCannonPositive
        : l10n.npcEffectGlassCannonNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescGlassCannonPositive
        : l10n.npcEffectDescGlassCannonNegative;
  }
}

// ─── Map / Terrain Effect Definitions ─────────────────────────────────

/// Path clearing: Remove or add mountains
class PathClearingDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'path_clearing';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final count =
        NpcEffectConstants.pathClearingMinCells +
        random.nextInt(
          NpcEffectConstants.pathClearingMaxCells -
              NpcEffectConstants.pathClearingMinCells +
              1,
        );
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      data: {'count': count},
    );
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final count =
        (effect.data['count'] as int?) ??
        NpcEffectConstants.pathClearingMinCells;

    if (effect.isPositive) {
      // Remove random mountains
      _removeCellsOfType(map, ExploreCellType.mountain, count, random);
    } else {
      // Convert blank cells to mountains
      _convertBlankToCellType(map, ExploreCellType.mountain, count, random);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.terrain : Icons.landscape;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNamePathClearing;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    final count =
        (effect.data['count'] as int?) ??
        NpcEffectConstants.pathClearingMinCells;
    return effect.isPositive
        ? l10n.npcEffectPathClearingPositive(count)
        : l10n.npcEffectPathClearingNegative(count);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// River bridge: Remove or add rivers
class RiverBridgeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'river_bridge';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final count =
        NpcEffectConstants.riverBridgeMinCells +
        random.nextInt(
          NpcEffectConstants.riverBridgeMaxCells -
              NpcEffectConstants.riverBridgeMinCells +
              1,
        );
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      data: {'count': count},
    );
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final count =
        (effect.data['count'] as int?) ??
        NpcEffectConstants.riverBridgeMinCells;

    if (effect.isPositive) {
      // Remove random rivers
      _removeCellsOfType(map, ExploreCellType.river, count, random);
    } else {
      // Convert blank cells to rivers
      _convertBlankToCellType(map, ExploreCellType.river, count, random);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.water_drop : Icons.waves;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameRiverBridge;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    final count =
        (effect.data['count'] as int?) ??
        NpcEffectConstants.riverBridgeMinCells;
    return effect.isPositive
        ? l10n.npcEffectRiverBridgePositive(count)
        : l10n.npcEffectRiverBridgeNegative(count);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Monster cleanse: Remove or spawn monsters
class MonsterCleanseDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'monster_cleanse';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Remove nearest monsters
      _removeNearestCellsOfType(
        map,
        ExploreCellType.monster,
        NpcEffectConstants.monsterCleanseCount,
      );
    } else {
      // Spawn new monsters on blank cells
      _convertBlankToCellType(
        map,
        ExploreCellType.monster,
        NpcEffectConstants.monsterSpawnCount,
        random,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.pest_control : Icons.bug_report;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMonsterCleanse;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMonsterCleansePositive(
            NpcEffectConstants.monsterCleanseCount,
          )
        : l10n.npcEffectMonsterCleanseNegative(
            NpcEffectConstants.monsterSpawnCount,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Boss shift: Remove or spawn boss
class BossShiftDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'boss_shift';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Remove nearest boss
      _removeNearestCellsOfType(
        map,
        ExploreCellType.boss,
        NpcEffectConstants.bossRemoveCount,
      );
    } else {
      // Spawn new boss on blank cell
      _convertBlankToCellType(
        map,
        ExploreCellType.boss,
        NpcEffectConstants.bossSpawnCount,
        random,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.shield : Icons.whatshot;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameBossShift;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectBossShiftPositive
        : l10n.npcEffectBossShiftNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Safe zone: Clear or spawn monsters in 5x5 area around player
class SafeZoneDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'safe_zone';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final radius = NpcEffectConstants.safeZoneRadius;
    final playerX = map.playerX;
    final playerY = map.playerY;

    if (effect.isPositive) {
      // Clear 5x5 area around player (monsters/bosses -> blank)
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            final cell = map.grid[y][x];
            if (cell.type == ExploreCellType.monster ||
                cell.type == ExploreCellType.boss) {
              map.grid[y][x] = ExploreCell(
                type: ExploreCellType.blank,
                x: x,
                y: y,
              );
            }
          }
        }
      }
    } else {
      // Spawn monsters in 5x5 area around player (blank -> monster)
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          if (dx == 0 && dy == 0) continue; // Don't spawn on player
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            final cell = map.grid[y][x];
            if (cell.type == ExploreCellType.blank) {
              map.grid[y][x] = ExploreCell(
                type: ExploreCellType.monster,
                x: x,
                y: y,
              );
            }
          }
        }
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.security : Icons.warning;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameSafeZone;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectSafeZonePositive
        : l10n.npcEffectSafeZoneNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Terrain swap: Convert mountains to blank or blank to mountains
class TerrainSwapDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'terrain_swap';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final count = NpcEffectConstants.terrainSwapCount;

    if (effect.isPositive) {
      // Convert mountains to blank
      _removeCellsOfType(map, ExploreCellType.mountain, count, random);
    } else {
      // Convert blank to mountains near player
      _convertBlankToCellTypeNearPlayer(
        map,
        ExploreCellType.mountain,
        count,
        random,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.grass : Icons.filter_hdr;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameTerrainSwap;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectTerrainSwapPositive(NpcEffectConstants.terrainSwapCount)
        : l10n.npcEffectTerrainSwapNegative(
            NpcEffectConstants.terrainSwapCount,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

// ─── Vision / Revelation Effect Definitions ───────────────────────────

/// FOV modify: Increase or decrease FOV permanently
class FovModifyDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'fov_modify';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final amounts = NpcEffectConstants.fovModifyAmounts;
    final amount = amounts[random.nextInt(amounts.length)];
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      data: {'amount': amount},
    );
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final amount = (effect.data['amount'] as int?) ?? 2;
    // Store the FOV modifier in the effect data for later use
    // The actual modification is applied via the persistent effect
    // We need to make this a duration-based effect that persists
    effect.data['fovModifier'] = effect.isPositive ? amount : -amount;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.visibility : Icons.visibility_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameFovModify;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    final amount = (effect.data['amount'] as int?) ?? 2;
    return effect.isPositive
        ? l10n.npcEffectFovModifyPositive(amount)
        : l10n.npcEffectFovModifyNegative(amount);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Boss radar: Reveal or hide boss locations
class BossRadarDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'boss_radar';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final isPositive = random.nextBool();
    if (isPositive) {
      return NpcEffect(typeId: typeId, isPositive: true);
    } else {
      // Negative: hide bosses for N moves (duration-based effect)
      return NpcEffect(
        typeId: typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.radarHideDurationMoves,
        data: {'hiddenType': ExploreCellType.boss.index},
      );
    }
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Reveal nearest boss location
      _revealNearestCellOfType(map, ExploreCellType.boss);
    } else {
      // Store info about hidden bosses - this is handled via active effect
      effect.data['hiddenType'] = ExploreCellType.boss.index;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.gps_fixed : Icons.gps_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameBossRadar;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectBossRadarPositive
        : l10n.npcEffectBossRadarNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive ? '' : l10n.npcEffectDescBossRadarNegative;
  }
}

/// NPC radar: Reveal or hide NPC locations
class NpcRadarDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'npc_radar';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final isPositive = random.nextBool();
    if (isPositive) {
      return NpcEffect(typeId: typeId, isPositive: true);
    } else {
      // Negative: hide NPCs for N moves (duration-based effect)
      return NpcEffect(
        typeId: typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.radarHideDurationMoves,
        data: {'hiddenType': ExploreCellType.npc.index},
      );
    }
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Reveal nearest NPC location
      _revealNearestCellOfType(map, ExploreCellType.npc);
    } else {
      // Store info about hidden NPCs - handled via active effect
      effect.data['hiddenType'] = ExploreCellType.npc.index;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.person_pin : Icons.person_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameNpcRadar;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectNpcRadarPositive
        : l10n.npcEffectNpcRadarNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive ? '' : l10n.npcEffectDescNpcRadarNegative;
  }
}

/// Map reveal: Reveal 20% of map or shrink FOV to 1 for N moves
class MapRevealDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'map_reveal';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final isPositive = random.nextBool();
    if (isPositive) {
      return NpcEffect(typeId: typeId, isPositive: true);
    } else {
      // Negative: shrink FOV for N moves (make it a duration-based effect)
      return NpcEffect(
        typeId: typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.fovShrinkMovesDuration,
      );
    }
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Reveal 20% of unexplored map
      final unvisited = <(int, int)>[];
      for (int y = 0; y < map.height; y++) {
        for (int x = 0; x < map.width; x++) {
          if (!map.isVisited(x, y)) {
            unvisited.add((x, y));
          }
        }
      }

      final toReveal = (unvisited.length * NpcEffectConstants.mapRevealPercent)
          .round();
      unvisited.shuffle(random);

      for (int i = 0; i < toReveal && i < unvisited.length; i++) {
        final (x, y) = unvisited[i];
        map.markVisited(x, y);
      }
    }
    // Negative effect is handled by modifyFovRadius
  }

  @override
  int modifyFovRadius(NpcEffect effect, int baseRadius) {
    // Negative: shrink FOV to 1
    if (!effect.isPositive) {
      return NpcEffectConstants.fovShrinkMinRadius;
    }
    return baseRadius;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.map : Icons.cloud;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMapReveal;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMapRevealPositive
        : l10n.npcEffectMapRevealNegative(
            NpcEffectConstants.fovShrinkMovesDuration,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive ? '' : l10n.npcEffectDescMapRevealNegative;
  }
}

/// Monster radar: Reveal or hide monsters within range
class MonsterRadarDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'monster_radar';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final isPositive = random.nextBool();
    if (isPositive) {
      return NpcEffect(typeId: typeId, isPositive: true);
    } else {
      // Negative: hide monsters in range for N moves (duration-based effect)
      return NpcEffect(
        typeId: typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.radarHideDurationMoves,
        data: {
          'hiddenType': ExploreCellType.monster.index,
          'range': NpcEffectConstants.monsterRadarRange,
        },
      );
    }
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final range = NpcEffectConstants.monsterRadarRange;
    final playerX = map.playerX;
    final playerY = map.playerY;

    if (effect.isPositive) {
      // Reveal all monsters within range
      for (int dy = -range; dy <= range; dy++) {
        for (int dx = -range; dx <= range; dx++) {
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            final cell = map.grid[y][x];
            if (cell.type == ExploreCellType.monster) {
              map.markVisited(x, y);
            }
          }
        }
      }
    } else {
      // Store info about hidden monsters within range
      effect.data['hiddenType'] = ExploreCellType.monster.index;
      effect.data['range'] = range;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.radar : Icons.blur_on;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMonsterRadar;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMonsterRadarPositive
        : l10n.npcEffectMonsterRadarNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive ? '' : l10n.npcEffectDescMonsterRadarNegative;
  }
}

/// House radar: Reveal or hide house locations
class HouseRadarDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'house_radar';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    final isPositive = random.nextBool();
    if (isPositive) {
      return NpcEffect(typeId: typeId, isPositive: true);
    } else {
      // Negative: hide houses for N moves (duration-based effect)
      return NpcEffect(
        typeId: typeId,
        isPositive: false,
        durationType: EffectDurationType.moves,
        remainingMoves: NpcEffectConstants.radarHideDurationMoves,
        data: {'hiddenType': ExploreCellType.house.index},
      );
    }
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Reveal nearest house location
      _revealNearestCellOfType(map, ExploreCellType.house);
    } else {
      // Store info about hidden houses - handled via active effect
      effect.data['hiddenType'] = ExploreCellType.house.index;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.home : Icons.home_outlined;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameHouseRadar;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectHouseRadarPositive
        : l10n.npcEffectHouseRadarNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive ? '' : l10n.npcEffectDescHouseRadarNegative;
  }
}

// ─── Helper functions for map manipulation ────────────────────────────

/// Remove random cells of specified type and convert to blank
void _removeCellsOfType(
  ExploreMap map,
  ExploreCellType type,
  int count,
  Random random,
) {
  final cells = <(int, int)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type) {
        cells.add((x, y));
      }
    }
  }

  cells.shuffle(random);
  for (int i = 0; i < count && i < cells.length; i++) {
    final (x, y) = cells[i];
    map.grid[y][x] = ExploreCell(type: ExploreCellType.blank, x: x, y: y);
  }
}

/// Convert random blank cells to specified type
void _convertBlankToCellType(
  ExploreMap map,
  ExploreCellType type,
  int count,
  Random random,
) {
  final blanks = <(int, int)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == ExploreCellType.blank &&
          !(x == map.playerX && y == map.playerY)) {
        blanks.add((x, y));
      }
    }
  }

  blanks.shuffle(random);
  for (int i = 0; i < count && i < blanks.length; i++) {
    final (x, y) = blanks[i];
    map.grid[y][x] = ExploreCell(type: type, x: x, y: y);
  }
}

/// Convert blank cells near player to specified type
void _convertBlankToCellTypeNearPlayer(
  ExploreMap map,
  ExploreCellType type,
  int count,
  Random random,
) {
  final playerX = map.playerX;
  final playerY = map.playerY;

  // Collect blank cells sorted by distance to player
  final blanks = <(int, int, double)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == ExploreCellType.blank &&
          !(x == playerX && y == playerY)) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        blanks.add((x, y, distance));
      }
    }
  }

  // Sort by distance and take the nearest blank cells
  blanks.sort((a, b) => a.$3.compareTo(b.$3));

  // Add some randomness to the nearest cells
  final nearestCount = min(count * 3, blanks.length);
  final candidates = blanks.sublist(0, nearestCount);
  candidates.shuffle(random);

  for (int i = 0; i < count && i < candidates.length; i++) {
    final (x, y, _) = candidates[i];
    map.grid[y][x] = ExploreCell(type: type, x: x, y: y);
  }
}

/// Remove nearest cells of specified type (by distance from player)
void _removeNearestCellsOfType(
  ExploreMap map,
  ExploreCellType type,
  int count,
) {
  final playerX = map.playerX;
  final playerY = map.playerY;

  // Collect cells of type sorted by distance
  final cells = <(int, int, double)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        cells.add((x, y, distance));
      }
    }
  }

  // Sort by distance (nearest first)
  cells.sort((a, b) => a.$3.compareTo(b.$3));

  for (int i = 0; i < count && i < cells.length; i++) {
    final (x, y, _) = cells[i];
    map.grid[y][x] = ExploreCell(type: ExploreCellType.blank, x: x, y: y);
  }
}

/// Reveal nearest cell of specified type (mark as visited)
void _revealNearestCellOfType(ExploreMap map, ExploreCellType type) {
  final playerX = map.playerX;
  final playerY = map.playerY;

  double nearestDist = double.infinity;
  int? nearestX;
  int? nearestY;

  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type && !map.isVisited(x, y)) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        if (distance < nearestDist) {
          nearestDist = distance;
          nearestX = x;
          nearestY = y;
        }
      }
    }
  }

  if (nearestX != null && nearestY != null) {
    map.markVisited(nearestX, nearestY);
  }
}

// ─── Movement Effect Definitions ──────────────────────────────────────

/// Teleport: teleport to random far blank cell or back to spawn
class TeleportDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'teleport';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Teleport to random blank cell far away
      _teleportToFarBlankCell(map, random);
    } else {
      // Teleport back to spawn point (center of map)
      final centerX = map.width ~/ 2;
      final centerY = map.height ~/ 2;
      // Find nearest walkable cell to center
      var (targetX, targetY) = _findNearestWalkableCell(map, centerX, centerY);
      map.playerX = targetX;
      map.playerY = targetY;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.my_location : Icons.undo;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameTeleport;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectTeleportPositive
        : l10n.npcEffectTeleportNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Speed boost: move 2 cells per step or need 2 presses to move
class SpeedBoostDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'speed_boost';

  @override
  EffectDurationType get durationType => EffectDurationType.moves;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingMoves: NpcEffectConstants.speedBoostDurationMoves,
      data: {'pressCount': 0}, // For negative effect tracking
    );
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.fast_forward : Icons.slow_motion_video;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameSpeedBoost;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectSpeedBoostPositive(
            NpcEffectConstants.speedBoostDurationMoves,
          )
        : l10n.npcEffectSpeedBoostNegative(
            NpcEffectConstants.speedBoostDurationMoves,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescSpeedBoostPositive
        : l10n.npcEffectDescSpeedBoostNegative;
  }
}

/// Teleport to house: teleport to nearest house or boss
class TeleportHouseDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'teleport_house';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final targetType = effect.isPositive
        ? ExploreCellType.house
        : ExploreCellType.boss;
    final (x, y) = _findNearestCellOfType(map, targetType);
    if (x != null && y != null) {
      // Teleport adjacent to target (not on it)
      final adjacent = _findAdjacentWalkableCell(map, x, y);
      if (adjacent != null) {
        map.playerX = adjacent.$1;
        map.playerY = adjacent.$2;
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.home : Icons.whatshot;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameTeleportHouse;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectTeleportHousePositive
        : l10n.npcEffectTeleportHouseNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Pathfinder: reveal path to house or remove all houses
class PathfinderDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'pathfinder';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Reveal path to nearest house
      final (hx, hy) = _findNearestCellOfType(map, ExploreCellType.house);
      if (hx != null && hy != null) {
        _revealPathToTarget(map, hx, hy);
      }
    } else {
      // Remove all houses from map
      for (int y = 0; y < map.height; y++) {
        for (int x = 0; x < map.width; x++) {
          if (map.grid[y][x].type == ExploreCellType.house) {
            map.grid[y][x] = ExploreCell(
              type: ExploreCellType.blank,
              x: x,
              y: y,
            );
          }
        }
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.route : Icons.not_listed_location;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNamePathfinder;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectPathfinderPositive
        : l10n.npcEffectPathfinderNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

// ─── Monster / Enemy Manipulation Definitions ─────────────────────────

/// Weaken enemies: monsters in radius get ±30% FC
class WeakenEnemiesDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'weaken_enemies';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final radius = NpcEffectConstants.weakenEnemiesRadius;
    // Store weakened/strengthened monster positions in effect data
    final affectedMonsters = <String>[];
    final playerX = map.playerX;
    final playerY = map.playerY;

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final x = playerX + dx;
        final y = playerY + dy;
        if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
          final cell = map.grid[y][x];
          if (cell.type == ExploreCellType.monster) {
            affectedMonsters.add('$x,$y');
          }
        }
      }
    }
    effect.data['affectedMonsters'] = affectedMonsters;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.healing : Icons.local_fire_department;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameWeakenEnemies;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectWeakenEnemiesPositive
        : l10n.npcEffectWeakenEnemiesNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Monster conversion: monsters become NPCs or vice versa
class MonsterConversionDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'monster_conversion';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final count = NpcEffectConstants.monsterConversionCount;

    if (effect.isPositive) {
      // Convert nearest monsters to NPCs
      _convertNearestCells(
        map,
        ExploreCellType.monster,
        ExploreCellType.npc,
        count,
      );
    } else {
      // Convert nearest NPCs to monsters
      _convertNearestCells(
        map,
        ExploreCellType.npc,
        ExploreCellType.monster,
        count,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.pets : Icons.pest_control;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMonsterConversion;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMonsterConversionPositive(
            NpcEffectConstants.monsterConversionCount,
          )
        : l10n.npcEffectMonsterConversionNegative(
            NpcEffectConstants.monsterConversionCount,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Boss downgrade: boss becomes monster or vice versa
class BossDowngradeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'boss_downgrade';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Nearest boss becomes monster
      _convertNearestCells(
        map,
        ExploreCellType.boss,
        ExploreCellType.monster,
        1,
      );
    } else {
      // Nearest monster becomes boss
      _convertNearestCells(
        map,
        ExploreCellType.monster,
        ExploreCellType.boss,
        1,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.arrow_downward : Icons.arrow_upward;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameBossDowngrade;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectBossDowngradePositive
        : l10n.npcEffectBossDowngradeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Monster freeze: next monster flees or gets FC boost
class MonsterFreezeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'monster_freeze';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.monsterFreezeDurationBattles,
    );
  }

  @override
  BattleOutcome? overrideBattleOutcome(
    NpcEffect effect,
    double playerFC,
    double enemyFC,
    ExploreCellType cellType,
  ) {
    // Only affects monsters, not bosses
    if (cellType != ExploreCellType.monster) return null;

    if (effect.isPositive) {
      // Monster flees = auto-win
      return BattleOutcome.victory;
    }
    return null;
  }

  @override
  double modifyEnemyFC(
    NpcEffect effect,
    double baseEnemyFC,
    ExploreCellType cellType,
  ) {
    // Only affects monsters, not bosses
    if (cellType != ExploreCellType.monster) return baseEnemyFC;

    if (!effect.isPositive) {
      return baseEnemyFC * NpcEffectConstants.monsterFreezeFCBoost;
    }
    return baseEnemyFC;
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.ac_unit : Icons.whatshot;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMonsterFreeze;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMonsterFreezePositive
        : l10n.npcEffectMonsterFreezeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescMonsterFreezePositive
        : l10n.npcEffectDescMonsterFreezeNegative;
  }
}

/// Clear wave: remove or spawn monsters in radius
class ClearWaveDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'clear_wave';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final radius = NpcEffectConstants.clearWaveRadius;
    final playerX = map.playerX;
    final playerY = map.playerY;

    if (effect.isPositive) {
      // Remove all monsters in radius
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            if (map.grid[y][x].type == ExploreCellType.monster) {
              map.grid[y][x] = ExploreCell(
                type: ExploreCellType.blank,
                x: x,
                y: y,
              );
            }
          }
        }
      }
    } else {
      // Convert blank cells to monsters in radius
      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          if (dx == 0 && dy == 0) continue; // Don't spawn on player
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            if (map.grid[y][x].type == ExploreCellType.blank) {
              map.grid[y][x] = ExploreCell(
                type: ExploreCellType.monster,
                x: x,
                y: y,
              );
            }
          }
        }
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.cleaning_services : Icons.bug_report;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameClearWave;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectClearWavePositive
        : l10n.npcEffectClearWaveNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Monster magnet: push or pull monsters
class MonsterMagnetDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'monster_magnet';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final radius = NpcEffectConstants.monsterMagnetRadius;
    final moveDistance = NpcEffectConstants.monsterMagnetMoveDistance;
    final playerX = map.playerX;
    final playerY = map.playerY;

    // Collect monsters in radius
    final monsters = <(int, int)>[];
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final x = playerX + dx;
        final y = playerY + dy;
        if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
          if (map.grid[y][x].type == ExploreCellType.monster) {
            monsters.add((x, y));
          }
        }
      }
    }

    // Move each monster
    for (final (mx, my) in monsters) {
      final dx = mx - playerX;
      final dy = my - playerY;

      int newX, newY;
      if (effect.isPositive) {
        // Move away from player
        newX = mx + (dx == 0 ? 0 : (dx > 0 ? moveDistance : -moveDistance));
        newY = my + (dy == 0 ? 0 : (dy > 0 ? moveDistance : -moveDistance));
      } else {
        // Move toward player
        newX = mx - (dx == 0 ? 0 : (dx > 0 ? moveDistance : -moveDistance));
        newY = my - (dy == 0 ? 0 : (dy > 0 ? moveDistance : -moveDistance));
      }

      // Clamp to map bounds
      newX = newX.clamp(0, map.width - 1);
      newY = newY.clamp(0, map.height - 1);

      // Only move if target is blank and not player position
      if (newX != playerX || newY != playerY) {
        if (map.grid[newY][newX].type == ExploreCellType.blank) {
          map.grid[my][mx] = ExploreCell(
            type: ExploreCellType.blank,
            x: mx,
            y: my,
          );
          map.grid[newY][newX] = ExploreCell(
            type: ExploreCellType.monster,
            x: newX,
            y: newY,
          );
        }
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.call_missed_outgoing : Icons.call_received;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMonsterMagnet;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMonsterMagnetPositive
        : l10n.npcEffectMonsterMagnetNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

// ─── NPC Chain Effect Definitions ─────────────────────────────────────

/// NPC blessing chain: next NPC guaranteed positive/negative
class NpcBlessingChainDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'npc_blessing_chain';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: 1, // Consumed on next NPC encounter
    );
  }

  @override
  NpcEffect modifyNextNpcEffect(NpcEffect self, NpcEffect generated) {
    // Force the polarity of the next NPC effect
    return NpcEffect(
      typeId: generated.typeId,
      isPositive: self.isPositive, // Force to match our polarity
      durationType: generated.durationType,
      remainingBattles: generated.remainingBattles,
      remainingMoves: generated.remainingMoves,
      data: Map.from(generated.data),
    );
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.auto_awesome : Icons.cloud;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameNpcBlessingChain;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectNpcBlessingChainPositive
        : l10n.npcEffectNpcBlessingChainNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescNpcBlessingChainPositive
        : l10n.npcEffectDescNpcBlessingChainNegative;
  }
}

/// NPC spawn: spawn or remove NPCs
class NpcSpawnDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'npc_spawn';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Spawn new NPCs
      _convertBlankToCellType(
        map,
        ExploreCellType.npc,
        NpcEffectConstants.npcSpawnCount,
        random,
      );
    } else {
      // Remove random NPCs
      _removeRandomCellsOfType(
        map,
        ExploreCellType.npc,
        NpcEffectConstants.npcRemoveCount,
        random,
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.person_add : Icons.person_remove;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameNpcSpawn;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectNpcSpawnPositive(NpcEffectConstants.npcSpawnCount)
        : l10n.npcEffectNpcSpawnNegative(NpcEffectConstants.npcRemoveCount);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// NPC upgrade: double or reverse next NPC effect
class NpcUpgradeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'npc_upgrade';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: 1, // Consumed on next NPC encounter
    );
  }

  @override
  NpcEffect modifyNextNpcEffect(NpcEffect self, NpcEffect generated) {
    if (self.isPositive) {
      // Double the next effect (e.g., double duration or stored value)
      final newData = Map<String, dynamic>.from(generated.data);
      if (newData.containsKey('storedValue')) {
        newData['storedValue'] = ((newData['storedValue'] as num?) ?? 0) * 2;
      }
      return NpcEffect(
        typeId: generated.typeId,
        isPositive: generated.isPositive,
        durationType: generated.durationType,
        remainingBattles: generated.remainingBattles * 2,
        remainingMoves: generated.remainingMoves * 2,
        data: newData,
      );
    } else {
      // Reverse the polarity
      return NpcEffect(
        typeId: generated.typeId,
        isPositive: !generated.isPositive,
        durationType: generated.durationType,
        remainingBattles: generated.remainingBattles,
        remainingMoves: generated.remainingMoves,
        data: Map.from(generated.data),
      );
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.upgrade : Icons.swap_vert;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameNpcUpgrade;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectNpcUpgradePositive
        : l10n.npcEffectNpcUpgradeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescNpcUpgradePositive
        : l10n.npcEffectDescNpcUpgradeNegative;
  }
}

// ─── House Effect Definitions ─────────────────────────────────────────

/// House spawn: spawn or remove house
class HouseSpawnDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'house_spawn';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Spawn house near player
      _convertBlankToCellTypeNearPlayer(map, ExploreCellType.house, 1, random);
    } else {
      // Remove nearest house
      _removeNearestCellsOfType(map, ExploreCellType.house, 1);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.add_home : Icons.home_work;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameHouseSpawn;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectHouseSpawnPositive
        : l10n.npcEffectHouseSpawnNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// House upgrade: next house gives 2x or 0.5x benefit
class HouseUpgradeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'house_upgrade';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: 1, // Consumed on next house visit
    );
  }

  @override
  int modifyHouseRestore(NpcEffect effect, int baseRestore) {
    if (effect.isPositive) {
      return (baseRestore * 2).round();
    } else {
      return (baseRestore * 0.5).round();
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.hotel : Icons.night_shelter;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameHouseUpgrade;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectHouseUpgradePositive
        : l10n.npcEffectHouseUpgradeNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescHouseUpgradePositive
        : l10n.npcEffectDescHouseUpgradeNegative;
  }
}

// ─── Combo / Conditional Effect Definitions ───────────────────────────

/// Risk/reward: +50% EXP -20% FC or vice versa
class RiskRewardDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'risk_reward';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.riskRewardDurationBattles,
    );
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    if (effect.isPositive) {
      return baseFC * NpcEffectConstants.riskRewardFCMultiplier;
    } else {
      return baseFC * NpcEffectConstants.riskRewardFCNegativeMultiplier;
    }
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
      return baseExpChange * NpcEffectConstants.riskRewardExpMultiplier;
    } else {
      return baseExpChange * NpcEffectConstants.riskRewardExpNegativeMultiplier;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.casino : Icons.security;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameRiskReward;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectRiskRewardPositive(
            NpcEffectConstants.riskRewardDurationBattles,
          )
        : l10n.npcEffectRiskRewardNegative(
            NpcEffectConstants.riskRewardDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescRiskRewardPositive
        : l10n.npcEffectDescRiskRewardNegative;
  }
}

/// Sacrifice: lose EXP now for FC boost, or vice versa
class SacrificeDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'sacrifice';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.sacrificeDurationBattles,
    );
  }

  @override
  double applyImmediate(
    NpcEffect effect,
    double currentExp,
    double maxExp,
    Random random,
  ) {
    final expChange = maxExp * NpcEffectConstants.sacrificeExpLossPercent;
    return effect.isPositive ? -expChange : expChange;
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    if (effect.isPositive) {
      return baseFC * NpcEffectConstants.sacrificeFCBoost;
    } else {
      return baseFC * NpcEffectConstants.sacrificeFCPenalty;
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.local_fire_department : Icons.dark_mode;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameSacrifice;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectSacrificePositive(
            NpcEffectConstants.sacrificeDurationBattles,
          )
        : l10n.npcEffectSacrificeNegative(
            NpcEffectConstants.sacrificeDurationBattles,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescSacrificePositive
        : l10n.npcEffectDescSacrificeNegative;
  }
}

/// All-in: clear monsters and gain EXP, or spawn boss and lose EXP
class AllInDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'all_in';

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
    final expChange = maxExp * NpcEffectConstants.allInExpGainPercent;
    return effect.isPositive ? expChange : -expChange;
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    if (effect.isPositive) {
      // Clear all monsters in radius
      final radius = NpcEffectConstants.allInClearRadius;
      final playerX = map.playerX;
      final playerY = map.playerY;

      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final x = playerX + dx;
          final y = playerY + dy;
          if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
            if (map.grid[y][x].type == ExploreCellType.monster) {
              map.grid[y][x] = ExploreCell(
                type: ExploreCellType.blank,
                x: x,
                y: y,
              );
            }
          }
        }
      }
    } else {
      // Spawn extra boss
      _convertBlankToCellType(map, ExploreCellType.boss, 1, random);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.stars : Icons.warning_amber;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameAllIn;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectAllInPositive
        : l10n.npcEffectAllInNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Mirror: double own FC or enemy copies your FC
class MirrorDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'mirror';

  @override
  EffectDurationType get durationType => EffectDurationType.battles;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingBattles: NpcEffectConstants.mirrorDurationBattles,
    );
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    if (effect.isPositive) {
      return baseFC * NpcEffectConstants.mirrorFCMultiplier;
    }
    return baseFC;
  }

  @override
  double modifyEnemyFC(
    NpcEffect effect,
    double baseEnemyFC,
    ExploreCellType cellType,
  ) {
    // Negative: enemy copies player FC - this is complicated because
    // we don't have player FC here. Store a flag and handle in battle.
    return baseEnemyFC;
  }

  @override
  BattleOutcome? overrideBattleOutcome(
    NpcEffect effect,
    double playerFC,
    double enemyFC,
    ExploreCellType cellType,
  ) {
    if (!effect.isPositive) {
      // Enemy has same FC as player - 50/50 chance
      return Random().nextBool() ? BattleOutcome.victory : BattleOutcome.defeat;
    }
    return null;
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.flip;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMirror;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMirrorPositive
        : l10n.npcEffectMirrorNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    return effect.isPositive
        ? l10n.npcEffectDescMirrorPositive
        : l10n.npcEffectDescMirrorNegative;
  }
}

/// Counter stack: each step gives ±1% FC
class CounterStackDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'counter_stack';

  @override
  EffectDurationType get durationType => EffectDurationType.moves;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(
      typeId: typeId,
      isPositive: random.nextBool(),
      remainingMoves: NpcEffectConstants.counterStackMaxSteps,
      data: {'stacks': 0},
    );
  }

  @override
  void onMove(NpcEffect effect, ExploreMap map) {
    final currentStacks = (effect.data['stacks'] as int?) ?? 0;
    if (effect.isPositive) {
      // Positive: accumulate stacks up to max
      if (currentStacks < NpcEffectConstants.counterStackMaxSteps) {
        effect.data['stacks'] = currentStacks + 1;
      }
    } else {
      // Negative: just track remaining steps
      effect.data['stacks'] = currentStacks + 1;
    }
  }

  @override
  double modifyPlayerFC(NpcEffect effect, double baseFC) {
    final stacks = (effect.data['stacks'] as int?) ?? 0;
    final percentModifier =
        stacks * NpcEffectConstants.counterStackPerStepPercent;

    if (effect.isPositive) {
      return baseFC * (1 + percentModifier);
    } else {
      return baseFC * (1 - percentModifier);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.trending_up : Icons.trending_down;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameCounterStack;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectCounterStackPositive(
            NpcEffectConstants.counterStackMaxSteps,
          )
        : l10n.npcEffectCounterStackNegative(
            NpcEffectConstants.counterStackMaxSteps,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) {
    final stacks = (effect.data['stacks'] as int?) ?? 0;
    final percent =
        (stacks * 100 * NpcEffectConstants.counterStackPerStepPercent).round();
    return effect.isPositive
        ? l10n.npcEffectDescCounterStackPositive(percent, stacks)
        : l10n.npcEffectDescCounterStackNegative(
            percent,
            effect.remainingMoves,
          );
  }
}

// ─── Meta / Map-Level Effect Definitions ──────────────────────────────

/// Map scramble: shuffle monsters or NPCs to new positions
class MapScrambleDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'map_scramble';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final targetType = effect.isPositive
        ? ExploreCellType.monster
        : ExploreCellType.npc;

    // Collect all cells of target type
    final cells = <(int, int)>[];
    for (int y = 0; y < map.height; y++) {
      for (int x = 0; x < map.width; x++) {
        if (map.grid[y][x].type == targetType) {
          cells.add((x, y));
        }
      }
    }

    // Collect all blank cells
    final blanks = <(int, int)>[];
    for (int y = 0; y < map.height; y++) {
      for (int x = 0; x < map.width; x++) {
        if (map.grid[y][x].type == ExploreCellType.blank &&
            !(x == map.playerX && y == map.playerY)) {
          blanks.add((x, y));
        }
      }
    }

    // Clear old positions
    for (final (x, y) in cells) {
      map.grid[y][x] = ExploreCell(type: ExploreCellType.blank, x: x, y: y);
    }

    // Shuffle and place in new positions
    blanks.shuffle(random);
    for (int i = 0; i < cells.length && i < blanks.length; i++) {
      final (newX, newY) = blanks[i];
      map.grid[newY][newX] = ExploreCell(type: targetType, x: newX, y: newY);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) => Icons.shuffle;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameMapScramble;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectMapScramblePositive
        : l10n.npcEffectMapScrambleNegative;
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Cell counter: show monster count or fake count
class CellCounterDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'cell_counter';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    // Count monsters on map
    int count = 0;
    for (int y = 0; y < map.height; y++) {
      for (int x = 0; x < map.width; x++) {
        if (map.grid[y][x].type == ExploreCellType.monster) {
          count++;
        }
      }
    }

    if (effect.isPositive) {
      effect.data['monsterCount'] = count;
    } else {
      // Add random offset ±5
      final offset = random.nextInt(11) - 5; // -5 to +5
      effect.data['monsterCount'] = (count + offset).clamp(0, count + 10);
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.format_list_numbered : Icons.help;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameCellCounter;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    final count = effect.data['monsterCount'] as int? ?? 0;
    return effect.isPositive
        ? l10n.npcEffectCellCounterPositive(count)
        : l10n.npcEffectCellCounterNegative(count);
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

/// Progress boost: mark cells as explored or un-explore cells
class ProgressBoostDefinition extends NpcEffectDefinition {
  @override
  String get typeId => 'progress_boost';

  @override
  EffectDurationType get durationType => EffectDurationType.instant;

  @override
  NpcEffect generate(Random random, double currentExp, double maxExp) {
    return NpcEffect(typeId: typeId, isPositive: random.nextBool());
  }

  @override
  void applyMapEffect(NpcEffect effect, ExploreMap map, Random random) {
    final count = NpcEffectConstants.progressBoostCellCount;

    if (effect.isPositive) {
      // Mark random unexplored cells as explored
      final unvisited = <(int, int)>[];
      for (int y = 0; y < map.height; y++) {
        for (int x = 0; x < map.width; x++) {
          if (!map.isVisited(x, y)) {
            unvisited.add((x, y));
          }
        }
      }

      unvisited.shuffle(random);
      for (int i = 0; i < count && i < unvisited.length; i++) {
        final (x, y) = unvisited[i];
        map.markVisited(x, y);
      }
    } else {
      // Un-explore cells (remove from visited set)
      final visited = map.visitedCells.toList();
      visited.shuffle(random);

      for (int i = 0; i < count && i < visited.length; i++) {
        map.visitedCells.remove(visited[i]);
      }
    }
  }

  @override
  IconData getIcon(NpcEffect effect) =>
      effect.isPositive ? Icons.explore : Icons.explore_off;

  @override
  String getName(NpcEffect effect, AppLocalizations l10n) =>
      l10n.npcEffectNameProgressBoost;

  @override
  String getEncounterDescription(
    NpcEffect effect,
    AppLocalizations l10n, {
    double? expChange,
  }) {
    return effect.isPositive
        ? l10n.npcEffectProgressBoostPositive(
            NpcEffectConstants.progressBoostCellCount,
          )
        : l10n.npcEffectProgressBoostNegative(
            NpcEffectConstants.progressBoostCellCount,
          );
  }

  @override
  String getActiveDescription(NpcEffect effect, AppLocalizations l10n) => '';
}

// ─── Additional Helper Functions ──────────────────────────────────────

/// Teleport player to a random blank cell far from current position
void _teleportToFarBlankCell(ExploreMap map, Random random) {
  final playerX = map.playerX;
  final playerY = map.playerY;
  final minDistance = NpcEffectConstants.teleportMinDistance;

  // Collect blank cells far from player
  final farBlanks = <(int, int)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == ExploreCellType.blank) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        if (distance >= minDistance) {
          farBlanks.add((x, y));
        }
      }
    }
  }

  if (farBlanks.isNotEmpty) {
    final (newX, newY) = farBlanks[random.nextInt(farBlanks.length)];
    map.playerX = newX;
    map.playerY = newY;
  }
}

/// Find nearest walkable cell to target position
(int, int) _findNearestWalkableCell(ExploreMap map, int targetX, int targetY) {
  // Spiral outward from target
  for (int radius = 0; radius < max(map.width, map.height); radius++) {
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx.abs() != radius && dy.abs() != radius) continue;
        final x = targetX + dx;
        final y = targetY + dy;
        if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
          if (map.grid[y][x].isWalkable) {
            return (x, y);
          }
        }
      }
    }
  }
  return (targetX, targetY);
}

/// Find nearest cell of specified type
(int?, int?) _findNearestCellOfType(ExploreMap map, ExploreCellType type) {
  final playerX = map.playerX;
  final playerY = map.playerY;

  double nearestDist = double.infinity;
  int? nearestX;
  int? nearestY;

  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        if (distance < nearestDist) {
          nearestDist = distance;
          nearestX = x;
          nearestY = y;
        }
      }
    }
  }

  return (nearestX, nearestY);
}

/// Find an adjacent walkable cell to target
(int, int)? _findAdjacentWalkableCell(
  ExploreMap map,
  int targetX,
  int targetY,
) {
  final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
  for (final (dx, dy) in directions) {
    final x = targetX + dx;
    final y = targetY + dy;
    if (x >= 0 && x < map.width && y >= 0 && y < map.height) {
      if (map.grid[y][x].isWalkable) {
        return (x, y);
      }
    }
  }
  return null;
}

/// Reveal path from player to target by marking cells as visited
void _revealPathToTarget(ExploreMap map, int targetX, int targetY) {
  // Simple line path (not shortest path, but reveals direction)
  int x = map.playerX;
  int y = map.playerY;

  while (x != targetX || y != targetY) {
    map.markVisited(x, y);

    if (x < targetX) {
      x++;
    } else if (x > targetX) {
      x--;
    }

    if (y < targetY) {
      y++;
    } else if (y > targetY) {
      y--;
    }
  }
  map.markVisited(targetX, targetY);
}

/// Convert nearest cells of one type to another
void _convertNearestCells(
  ExploreMap map,
  ExploreCellType fromType,
  ExploreCellType toType,
  int count,
) {
  final playerX = map.playerX;
  final playerY = map.playerY;

  // Collect cells of type sorted by distance
  final cells = <(int, int, double)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == fromType) {
        final distance = sqrt(pow(x - playerX, 2) + pow(y - playerY, 2));
        cells.add((x, y, distance));
      }
    }
  }

  // Sort by distance (nearest first)
  cells.sort((a, b) => a.$3.compareTo(b.$3));

  for (int i = 0; i < count && i < cells.length; i++) {
    final (x, y, _) = cells[i];
    map.grid[y][x] = ExploreCell(type: toType, x: x, y: y);
  }
}

/// Remove random cells of specified type
void _removeRandomCellsOfType(
  ExploreMap map,
  ExploreCellType type,
  int count,
  Random random,
) {
  final cells = <(int, int)>[];
  for (int y = 0; y < map.height; y++) {
    for (int x = 0; x < map.width; x++) {
      if (map.grid[y][x].type == type) {
        cells.add((x, y));
      }
    }
  }

  cells.shuffle(random);
  for (int i = 0; i < count && i < cells.length; i++) {
    final (x, y) = cells[i];
    map.grid[y][x] = ExploreCell(type: ExploreCellType.blank, x: x, y: y);
  }
}
