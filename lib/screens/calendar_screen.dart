import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../services/storage_service.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_list.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<String, List<Task>> _tasks = {};
  List<TaskCategory> _categories = StorageService.defaultCategories;
  bool _notificationsEnabled = true;
  bool _loading = true;

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final values = await Future.wait<dynamic>([
      StorageService.loadTasks(),
      StorageService.loadCategories(),
      StorageService.loadNotificationsEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _tasks = values[0] as Map<String, List<Task>>;
      _categories = values[1] as List<TaskCategory>;
      _notificationsEnabled = values[2] as bool;
      _loading = false;
    });
  }

  Future<void> _saveTasks() => StorageService.saveTasks(_tasks);

  Color _categoryColor(String name) {
    for (final category in _categories) {
      if (category.name == name) return category.color;
    }
    return Colors.indigo;
  }

  void _addTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTaskSheet(
        initialDate: _selectedDay,
        categories: _categories,
        notificationsEnabled: _notificationsEnabled,
        onCategoriesChanged: (categories) {
          setState(() => _categories = categories);
          StorageService.saveCategories(categories);
        },
        onSave: (task) {
          setState(() {
            final key = _dateKey(task.date!);
            _tasks.putIfAbsent(key, () => []).add(task);
          });
          _saveTasks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = _dateKey(_selectedDay);
    final dayTasks = _tasks[key] ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Сегодня',
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
            }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TableCalendar<Task>(
                      firstDay: DateTime.utc(2020),
                      lastDay: DateTime.utc(2100),
                      focusedDay: _focusedDay,
                      locale: 'ru_RU',
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        titleCentered: false,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .22),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                      ),
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) => setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      }),
                      eventLoader: (day) => _tasks[_dateKey(day)] ?? [],
                      calendarBuilders: CalendarBuilders<Task>(
                        markerBuilder: (_, day, events) {
                          final tasks = _tasks[_dateKey(day)];
                          if (tasks == null || tasks.isEmpty) return null;
                          return Positioned(
                            bottom: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: events
                                  .take(3)
                                  .map(
                                    (task) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _categoryColor(task.category),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'd MMMM',
                                  'ru_RU',
                                ).format(_selectedDay),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                dayTasks.isEmpty
                                    ? 'Нет запланированных задач'
                                    : '${dayTasks.length} ${_taskWord(dayTasks.length)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showSettings,
                          icon: const Icon(Icons.tune),
                          tooltip: 'Настройки',
                        ),
                      ],
                    ),
                  ),
                ),
                if (dayTasks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Добавьте первую задачу на этот день'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    sliver: TaskList(
                      tasks: dayTasks,
                      categoryColor: _categoryColor,
                      onDelete: (index) {
                        setState(() {
                          dayTasks.removeAt(index);
                          if (dayTasks.isEmpty) _tasks.remove(key);
                        });
                        _saveTasks();
                      },
                      onChanged: (index, value) {
                        setState(
                          () => dayTasks[index].isCompleted = value ?? false,
                        );
                        _saveTasks();
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
    );
  }

  String _taskWord(int count) =>
      count == 1 ? 'задача' : (count >= 2 && count <= 4 ? 'задачи' : 'задач');

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Настройки',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              SwitchListTile.adaptive(
                title: const Text('Напоминания'),
                subtitle: const Text('Разрешить напоминания о задачах'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  StorageService.saveNotificationsEnabled(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Категории'),
                subtitle: Text('${_categories.length} категорий'),
                onTap: () {
                  Navigator.pop(context);
                  _addTask();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
