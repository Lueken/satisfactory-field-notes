class GameSettings {
  /// Class names of unlocked alternate recipes
  final Set<String> unlockedAlternates;

  /// Max belt tier (1-6). Caps throughput.
  final int beltTier;

  /// Max miner tier (1-3). Affects extraction rates.
  final int minerTier;

  /// Whether overclocking is allowed globally.
  final bool overclockingEnabled;

  /// Whether Somersloop amplification is in use.
  final bool somersloopEnabled;

  /// Planner mode: true = advanced, false = simple.
  final bool advancedPlanner;

  const GameSettings({
    this.unlockedAlternates = const {},
    this.beltTier = 1,
    this.minerTier = 1,
    this.overclockingEnabled = false,
    this.somersloopEnabled = false,
    this.advancedPlanner = false,
  });

  /// Belt throughput caps in items/min
  static const beltRates = {
    1: 60,
    2: 120,
    3: 270,
    4: 480,
    5: 780,
    6: 1200,
  };

  int get beltRate => beltRates[beltTier] ?? 60;

  GameSettings copyWith({
    Set<String>? unlockedAlternates,
    int? beltTier,
    int? minerTier,
    bool? overclockingEnabled,
    bool? somersloopEnabled,
    bool? advancedPlanner,
  }) =>
      GameSettings(
        unlockedAlternates: unlockedAlternates ?? this.unlockedAlternates,
        beltTier: beltTier ?? this.beltTier,
        minerTier: minerTier ?? this.minerTier,
        overclockingEnabled: overclockingEnabled ?? this.overclockingEnabled,
        somersloopEnabled: somersloopEnabled ?? this.somersloopEnabled,
        advancedPlanner: advancedPlanner ?? this.advancedPlanner,
      );

  Map<String, dynamic> toJson() => {
        'unlockedAlternates': unlockedAlternates.toList(),
        'beltTier': beltTier,
        'minerTier': minerTier,
        'overclockingEnabled': overclockingEnabled,
        'somersloopEnabled': somersloopEnabled,
        'advancedPlanner': advancedPlanner,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        unlockedAlternates: (json['unlockedAlternates'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
        beltTier: (json['beltTier'] as num?)?.toInt() ?? 1,
        minerTier: (json['minerTier'] as num?)?.toInt() ?? 1,
        overclockingEnabled: json['overclockingEnabled'] as bool? ?? false,
        somersloopEnabled: json['somersloopEnabled'] as bool? ?? false,
        advancedPlanner: json['advancedPlanner'] as bool? ?? false,
      );
}
