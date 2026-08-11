import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_category.dart';
import 'settings_tile.dart';
import 'time_picker_sheet.dart';

class AddTaskSheet extends StatefulWidget {
  final DateTime initialDate;
  final List<TaskCategory> categories;
  final bool notificationsEnabled;
  final ValueChanged<Task> onSave;
  final ValueChanged<List<TaskCategory>> onCategoriesChanged;

  const AddTaskSheet({
    super.key,
    required this.initialDate,
    required this.categories,
    required this.notificationsEnabled,
    required this.onSave,
    required this.onCategoriesChanged,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _date;
  TimeOfDay? _time;
  late TaskCategory _category;
  late List<TaskCategory> _categories;
  int _priority = 1;
  bool _reminder = true;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _categories = List.of(widget.categories);
    _category = _categories.first;
    _reminder = widget.notificationsEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory() async {
    final result = await showModalBottomSheet<TaskCategory>(
      context: context,
      builder: (sheetContext) => _CategorySheet(categories: _categories),
    );
    if (result != null) setState(() => _category = result);
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    var color = Colors.blue;
    final created = await showDialog<TaskCategory>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Новая категория'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Например, Спорт')),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: [
            Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.red, Colors.teal, Colors.pink,
          ].map((item) => GestureDetector(
            onTap: () => setDialogState(() => color = item),
            child: CircleAvatar(backgroundColor: item, radius: color == item ? 17 : 14, child: color == item ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
          )).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, TaskCategory(name: name, colorValue: color.toARGB32()));
          }, child: const Text('Добавить')),
        ],
      )),
    );
    controller.dispose();
    if (created == null) return;
    final updated = [..._categories, created];
    widget.onCategoriesChanged(updated);
    setState(() {
      _categories = updated;
      _category = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Новая задача', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        TextField(controller: _titleController, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _descriptionController, maxLines: 2, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Заметка', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SettingsTile(icon: Icons.calendar_today_outlined, title: 'Дата', value: '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}', onTap: () async {
          final value = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100), locale: const Locale('ru'));
          if (value != null) setState(() => _date = value);
        }),
        SettingsTile(icon: Icons.access_time, title: 'Время', value: _time == null ? 'Не задано' : _time!.format(context), onTap: () => showModalBottomSheet(context: context, builder: (_) => TimePickerSheet(initialTime: _time, onSelected: (time) => setState(() => _time = time)))),
        SettingsTile(icon: Icons.circle, title: 'Категория', value: _category.name, onTap: _selectCategory),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _createCategory, icon: const Icon(Icons.add), label: const Text('Создать категорию'))),
        SettingsTile(icon: Icons.flag_outlined, title: 'Приоритет', value: ['Низкий', 'Средний', 'Высокий'][_priority - 1], onTap: () async {
          final value = await showModalBottomSheet<int>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => ListTile(title: Text(['Низкий', 'Средний', 'Высокий'][i]), onTap: () => Navigator.pop(context, i + 1))))));
          if (value != null) setState(() => _priority = value);
        }),
        SwitchListTile.adaptive(contentPadding: const EdgeInsets.symmetric(horizontal: 8), secondary: const Icon(Icons.notifications_outlined), title: const Text('Напоминание'), subtitle: Text(_time == null ? 'Выберите время для напоминания' : 'В момент начала задачи'), value: _reminder, onChanged: !widget.notificationsEnabled || _time == null ? null : (value) => setState(() => _reminder = value)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
          if (_titleController.text.trim().isEmpty) return;
          widget.onSave(Task(title: _titleController.text.trim(), description: _descriptionController.text.trim(), date: _date, time: _time == null ? null : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}', category: _category.name, priority: _priority, reminder: _reminder && _time != null));
          Navigator.pop(context);
        }, child: const Text('Сохранить'))),
      ])),
    ));
  }
}

class _CategorySheet extends StatelessWidget {
  final List<TaskCategory> categories;
  const _CategorySheet({required this.categories});

  @override
  Widget build(BuildContext context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Padding(padding: EdgeInsets.all(16), child: Text('Категория', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
    ...categories.map((category) => ListTile(leading: CircleAvatar(backgroundColor: category.color, radius: 10), title: Text(category.name), onTap: () => Navigator.pop(context, category))),
    const SizedBox(height: 8),
  ]));
}
