class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? date;
  String? time;
  int priority;
  String category;
  bool reminder;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.date,
    this.time,
    this.priority = 1,
    this.category = 'Личное',
    this.reminder = false,
  }) : id = id ?? 'task_${DateTime.now().microsecondsSinceEpoch}';

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String?,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
    time: json['time'] as String?,
    priority: json['priority'] as int? ?? 1,
    category: json['category'] as String? ?? 'Личное',
    reminder: json['reminder'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'date': date?.toIso8601String(),
    'time': time,
    'priority': priority,
    'category': category,
    'reminder': reminder,
  };
}
