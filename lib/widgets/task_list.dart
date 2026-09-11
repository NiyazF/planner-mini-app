import 'package:flutter/material.dart';
import '../models/task.dart';
import '../screens/task_details_screen.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final ValueChanged<int> onDelete;
  final void Function(int, bool?) onChanged;
  final Color Function(String) categoryColor;

  const TaskList({
    super.key,
    required this.tasks,
    required this.onDelete,
    required this.onChanged,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99'));
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final task = sorted[index];
        final originalIndex = tasks.indexOf(task);
        final color = categoryColor(task.category);
        return Dismissible(
          key: ObjectKey(task),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(originalIndex),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailsScreen(task: task, categoryColor: color),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      shape: const CircleBorder(),
                      activeColor: color,
                      onChanged: (value) => onChanged(originalIndex, value),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (task.time != null) ...[
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  task.time!,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 10),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.category,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (task.reminder)
                      const Icon(Icons.notifications_active_outlined, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      }, childCount: sorted.length),
    );
  }
}
