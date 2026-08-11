import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  final Color categoryColor;
  const TaskDetailsScreen({super.key, required this.task, required this.categoryColor});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Задача')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(task.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      if (task.description.isNotEmpty) ...[const SizedBox(height: 10), Text(task.description, style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant))],
      const SizedBox(height: 24),
      _InfoCard(icon: Icons.calendar_today_outlined, label: 'Дата', value: task.date == null ? 'Не задана' : DateFormat('d MMMM y', 'ru_RU').format(task.date!)),
      if (task.time != null) _InfoCard(icon: Icons.access_time, label: 'Время', value: task.time!),
      _InfoCard(icon: Icons.circle, iconColor: categoryColor, label: 'Категория', value: task.category),
      _InfoCard(icon: Icons.flag_outlined, label: 'Приоритет', value: ['Низкий', 'Средний', 'Высокий'][task.priority - 1]),
      _InfoCard(icon: task.reminder ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, label: 'Напоминание', value: task.reminder ? 'Включено' : 'Выключено'),
      _InfoCard(icon: task.isCompleted ? Icons.check_circle_outline : Icons.radio_button_unchecked, label: 'Статус', value: task.isCompleted ? 'Выполнено' : 'Не выполнено'),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  const _InfoCard({required this.icon, this.iconColor, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: iconColor), title: Text(label), subtitle: Text(value)));
}
