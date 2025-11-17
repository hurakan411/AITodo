class Task {
  final String id;
  final String title;
  final String status; // PENDING / ACTIVE / COMPLETED / FAILED
  final int estimateMinutes;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final bool extensionUsed;
  final int weight;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.estimateMinutes,
    required this.createdAt,
    required this.deadlineAt,
    required this.extensionUsed,
    required this.weight,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        status: json['status'] as String,
        estimateMinutes: json['estimate_minutes'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        deadlineAt: DateTime.parse(json['deadline_at'] as String),
        extensionUsed: json['extension_used'] as bool? ?? false,
        weight: json['weight'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'estimate_minutes': estimateMinutes,
        'created_at': createdAt.toIso8601String(),
        'deadline_at': deadlineAt.toIso8601String(),
        'extension_used': extensionUsed,
        'weight': weight,
      };
}
