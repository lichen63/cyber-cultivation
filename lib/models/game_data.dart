class GameData {
  final int level;
  final double currentExp;
  final bool isAlwaysOnTop;
  final double? windowWidth;
  final double? windowHeight;
  final String? userId;

  GameData({
    required this.level,
    required this.currentExp,
    this.isAlwaysOnTop = true,
    this.windowWidth,
    this.windowHeight,
    this.userId,
  });

  // Convert a GameData object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentExp': currentExp.isInfinite ? 0 : currentExp.toInt(),
      'isAlwaysOnTop': isAlwaysOnTop,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'userId': userId,
    };
  }

  // Convert a Map object into a GameData object
  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      level: json['level'] as int,
      currentExp: (json['currentExp'] as num).toDouble(),
      isAlwaysOnTop: json['isAlwaysOnTop'] as bool? ?? true,
      windowWidth: (json['windowWidth'] as num?)?.toDouble(),
      windowHeight: (json['windowHeight'] as num?)?.toDouble(),
      userId: json['userId'] as String?,
    );
  }

  GameData copyWith({
    int? level,
    double? currentExp,
    bool? isAlwaysOnTop,
    double? windowWidth,
    double? windowHeight,
    String? userId,
  }) {
    return GameData(
      level: level ?? this.level,
      currentExp: currentExp ?? this.currentExp,
      isAlwaysOnTop: isAlwaysOnTop ?? this.isAlwaysOnTop,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      userId: userId ?? this.userId,
    );
  }
}
