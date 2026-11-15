import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_transaction.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import '../services/budget_storage.dart';
import '../services/note_storage.dart';
import '../services/storage_service.dart';
import 'note_editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenNotes;

  const DashboardScreen({
    super.key,
    required this.onOpenBudget,
    required this.onOpenCalendar,
    required this.onOpenNotes,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  double _balance = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;

  Map<String, List<Task>> _allTasks = {};
  List<TaskCategory> _categories = StorageService.defaultCategories;
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Публичный метод, чтобы обновлять данные при возврате на главный экран
  Future<void> reload() async {
    final results = await Future.wait<dynamic>([
      BudgetStorage.loadTransactions(),
      StorageService.loadTasks(),
      StorageService.loadCategories(),
      NoteStorage.loadNotes(),
    ]);

    if (!mounted) return;

    final transactions = results[0] as List<BudgetTransaction>;
    final loadedNotes = (results[3] as List<Note>)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final now = DateTime.now();

    double totalBalance = 0;
    double income = 0;
    double expense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalBalance += tx.amount;
        if (tx.date.year == now.year && tx.date.month == now.month) {
          income += tx.amount;
        }
      } else {
        totalBalance -= tx.amount;
        if (tx.date.year == now.year && tx.date.month == now.month) {
          expense += tx.amount;
        }
      }
    }

    setState(() {
      _balance = totalBalance;
      _monthIncome = income;
      _monthExpense = expense;
      _allTasks = results[1] as Map<String, List<Task>>;
      _categories = results[2] as List<TaskCategory>;
      _notes = loadedNotes;
      _loading = false;
    });
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  DateTime? _parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Color _categoryColor(String name) {
    for (final cat in _categories) {
      if (cat.name == name) return cat.color;
    }
    return const Color(0xFF5856D6);
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat('#,##0.##', 'ru_RU');
    return '${formatter.format(value)} ₽';
  }

  String _noteShortTitle(Note note) {
    final title = note.title.trim();
    if (title.isNotEmpty) return title;
    final text = note.plainText.trim();
    if (text.isNotEmpty) return text.split('\n').first;
    return 'Без названия';
  }

  Future<void> _openNoteEditor([Note? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    await reload();
  }

  /// Ищет задачи на сегодня; если их нет — ищет ближайший будущий день с задачами
  ({DateTime? date, List<Task> tasks, bool isToday}) _resolveDisplayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateKey(today);
    final todayTasks = _allTasks[todayKey] ?? [];

    if (todayTasks.isNotEmpty) {
      final sorted = List<Task>.from(todayTasks)
        ..sort((a, b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99'));
      return (date: today, tasks: sorted, isToday: true);
    }

    DateTime? nearestDate;
    List<Task> nearestTasks = [];

    for (final entry in _allTasks.entries) {
      if (entry.value.isEmpty) continue;
      final parsed = _parseDateKey(entry.key);
      if (parsed == null) continue;

      if (parsed.isAfter(today)) {
        if (nearestDate == null || parsed.isBefore(nearestDate)) {
          nearestDate = parsed;
          nearestTasks = entry.value;
        }
      }
    }

    if (nearestDate != null) {
      final sorted = List<Task>.from(nearestTasks)
        ..sort((a, b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99'));
      return (date: nearestDate, tasks: sorted, isToday: false);
    }

    return (date: null, tasks: const [], isToday: true);
  }

  Future<void> _toggleTask(DateTime date, Task task, bool? value) async {
    setState(() {
      task.isCompleted = value ?? false;
    });
    await StorageService.saveTasks(_allTasks);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rawHeaderDate = DateFormat('EEEE, dd.MM', 'ru_RU').format(now);
    final headerDate =
        rawHeaderDate[0].toUpperCase() + rawHeaderDate.substring(1);

    final taskBlock = _resolveDisplayTasks();

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  children: [
                    // 1. Верхняя левая дата небольшим шрифтом
                    Text(
                      headerDate,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Карточка баланса
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: widget.onOpenBudget,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(
                                0xFF5856D6,
                              ).withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5856D6,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 18,
                                          color: Color(0xFF5856D6),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Баланс',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 15,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _formatMoney(_balance),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: _balance < 0
                                      ? const Color(0xFFFF3B30)
                                      : const Color(0xFF16161A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _MiniStat(
                                    icon: Icons.south_west_rounded,
                                    color: const Color(0xFF34C759),
                                    text: '+ ${_formatMoney(_monthIncome)}',
                                  ),
                                  const SizedBox(width: 16),
                                  _MiniStat(
                                    icon: Icons.north_east_rounded,
                                    color: const Color(0xFFFF3B30),
                                    text: '− ${_formatMoney(_monthExpense)}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Окно с задачами из календаря
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      taskBlock.isToday
                                          ? 'Дела на сегодня'
                                          : 'Ближайшие дела',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (!taskBlock.isToday &&
                                        taskBlock.date != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Сегодня свободно • ${DateFormat('d MMMM (EE)', 'ru_RU').format(taskBlock.date!)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onOpenCalendar,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Календарь',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (taskBlock.tasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_available_outlined,
                                      size: 32,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Запланированных дел пока нет',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...List.generate(taskBlock.tasks.length, (index) {
                              final task = taskBlock.tasks[index];
                              final color = _categoryColor(task.category);
                              final isLast =
                                  index == taskBlock.tasks.length - 1;

                              return Column(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _toggleTask(
                                      taskBlock.date!,
                                      task,
                                      !task.isCompleted,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: task.isCompleted,
                                              shape: const CircleBorder(),
                                              activeColor: color,
                                              onChanged: (val) => _toggleTask(
                                                taskBlock.date!,
                                                task,
                                                val,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: task.isCompleted
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    color: task.isCompleted
                                                        ? Colors.grey.shade500
                                                        : const Color(
                                                            0xFF16161A,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 7,
                                                      height: 7,
                                                      decoration: BoxDecoration(
                                                        color: color,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      task.category,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (task.time != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF7F7FB),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                task.time!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF16161A),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 8,
                                      color: Colors.grey.shade100,
                                    ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. Виджет заметок
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Заметки',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onOpenNotes,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Все',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 104,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _notes.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                // Первый квадрат — всегда кнопка создания новой заметки
                                if (index == 0) {
                                  return _AddNoteSquare(
                                    onTap: () => _openNoteEditor(),
                                  );
                                }

                                final note = _notes[index - 1];
                                return _NoteSquare(
                                  title: _noteShortTitle(note),
                                  dateText: DateFormat(
                                    'dd.MM',
                                  ).format(note.updatedAt),
                                  onTap: () => _openNoteEditor(note),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AddNoteSquare extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNoteSquare({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF5856D6).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, size: 32, color: Color(0xFF5856D6)),
          ),
        ),
      ),
    );
  }
}

class _NoteSquare extends StatelessWidget {
  final String title;
  final String dateText;
  final VoidCallback onTap;

  const _NoteSquare({
    required this.title,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: Color(0xFF16161A),
                ),
              ),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MiniStat({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
