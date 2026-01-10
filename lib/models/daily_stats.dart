class DailyStats {
  int keyboardCount;
  int mouseClickCount;
  int mouseMoveDistance;

  DailyStats({
    this.keyboardCount = 0,
    this.mouseClickCount = 0,
    this.mouseMoveDistance = 0,
  });

  Map<String, dynamic> toJson() => {
    'keyboardCount': keyboardCount,
    'mouseClickCount': mouseClickCount,
    'mouseMoveDistance': mouseMoveDistance,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      keyboardCount: json['keyboardCount'] as int? ?? 0,
      mouseClickCount: json['mouseClickCount'] as int? ?? 0,
      mouseMoveDistance: (json['mouseMoveDistance'] as num?)?.toInt() ?? 0,
    );
  }
}
