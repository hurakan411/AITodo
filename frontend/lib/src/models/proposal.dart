class TaskProposal {
  final String title;
  final int estimateMinutes;
  final DateTime deadlineAt;
  final int weight;
  final String aiComment;

  TaskProposal({
    required this.title,
    required this.estimateMinutes,
    required this.deadlineAt,
    required this.weight,
    this.aiComment = '',
  });

  factory TaskProposal.fromJson(Map<String, dynamic> json) => TaskProposal(
        title: json['title'] as String,
        estimateMinutes: json['estimate_minutes'] as int,
        deadlineAt: DateTime.parse(json['deadline_at'] as String),
        weight: json['weight'] as int? ?? 1,
        aiComment: json['ai_comment'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'estimate_minutes': estimateMinutes,
        'deadline_at': deadlineAt.toIso8601String(),
        'weight': weight,
        'ai_comment': aiComment,
      };
}
