class Task {
  String title;
  String description;
  bool isCompleted;
  DateTime? date;
  String? time;
  int priority;
  String category;
  bool reminder;

  Task({
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.date,
    this.time,
    this.priority = 1,
    this.category = 'Личное',
    this.reminder = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
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
