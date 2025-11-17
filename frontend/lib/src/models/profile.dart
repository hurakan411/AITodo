class Profile {
  final String userId;
  final int points;
  final int rank;

  Profile({required this.userId, required this.points, required this.rank});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: (json['user_id'] ?? 'local') as String,
        points: json['points'] as int? ?? 0,
        rank: json['rank'] as int? ?? 2,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'points': points,
        'rank': rank,
      };
}
