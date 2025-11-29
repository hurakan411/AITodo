class TaskProposal {
  final String title;
  final int estimateMinutes;
  final DateTime deadlineAt;
  final int weight;
  final String aiComment;
  final int bufferMinutes;

  TaskProposal({
    required this.title,
    required this.estimateMinutes,
    required this.deadlineAt,
    required this.weight,
    this.aiComment = '',
    this.bufferMinutes = 0,
  });

  factory TaskProposal.fromJson(Map<String, dynamic> json) {
    print('DEBUG: TaskProposal.fromJson: $json');
    return TaskProposal(
        title: json['title'] as String,
        estimateMinutes: json['estimate_minutes'] as int,
        deadlineAt: DateTime.parse(json['deadline_at'] as String),
        weight: json['weight'] as int? ?? 1,
        aiComment: json['ai_comment'] as String? ?? '',
        bufferMinutes: json['buffer_minutes'] as int? ?? 0,
      );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'estimate_minutes': estimateMinutes,
        'deadline_at': deadlineAt.toIso8601String(),
        'weight': weight,
        'ai_comment': aiComment,
      };
}
