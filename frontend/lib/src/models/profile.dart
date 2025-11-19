class Profile {
  final String userId;
  final int points;

  Profile({required this.userId, required this.points});

  // ポイントに基づいてランクを自動計算
  int get rank {
    // バックエンドのRANK_THRESHOLDSと同じロジック
    const rankThresholds = {
      7: 120,
      6: 80,
      5: 60,
      4: 40,
      3: 20,
      2: 10,
      1: 0,
    };
    
    int calculatedRank = 1;
    for (var entry in rankThresholds.entries) {
      if (points >= entry.value) {
        calculatedRank = entry.key;
        break;
      }
    }
    return calculatedRank;
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: (json['user_id'] ?? 'local') as String,
        points: json['points'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'points': points,
      };
}
