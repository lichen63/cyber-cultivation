class GameData {
  final int level;
  final double currentExp;

  GameData({
    required this.level,
    required this.currentExp,
  });

  // Convert a GameData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentExp': currentExp,
    };
  }

  // Convert a Map object into a GameData object
  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      level: json['level'] as int,
      currentExp: (json['currentExp'] as num).toDouble(),
    );
  }
}
