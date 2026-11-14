import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кнопка-иконка (если понадобится использовать отдельно в AppBar)
class SupplementTrackerButton extends StatelessWidget {
  const SupplementTrackerButton({super.key});

  void _openTrackerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SupplementTrackerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.checklist_rtl_rounded),
      tooltip: 'Дни приема без таблеток',
      onPressed: () => _openTrackerModal(context),
    );
  }
}

/// Содержимое выезжающего окна с таблицей и полем для примечаний
class SupplementTrackerSheet extends StatefulWidget {
  const SupplementTrackerSheet({super.key});

  @override
  State<SupplementTrackerSheet> createState() => _SupplementTrackerSheetState();
}

class _SupplementTrackerSheetState extends State<SupplementTrackerSheet> {
  static const String _checksStorageKey = 'supplement_tracker_checks_v1';
  static const String _notesStorageKey = 'supplement_tracker_notes_v1';

  final List<String> days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  final List<String> items = [
    'Утро AAKG',
    'Обед AAKG',
    'Протеин Креатин',
    'Вечер ААКG',
  ];

  late List<List<bool>> checks;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDefaultChecks();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initDefaultChecks() {
    checks = List.generate(
      items.length,
      (_) => List.generate(days.length, (_) => false),
    );
  }

  /// Загрузка сохраненных галочек и текста примечаний
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Загружаем галочки
    final savedChecksJson = prefs.getString(_checksStorageKey);
    if (savedChecksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedChecksJson);
        final loadedChecks = decoded
            .map((row) => (row as List<dynamic>).map((e) => e as bool).toList())
            .toList();

        if (loadedChecks.length == items.length &&
            loadedChecks.every((row) => row.length == days.length)) {
          checks = loadedChecks;
        }
      } catch (_) {}
    }

    // 2. Загружаем текст примечаний
    final savedNotes = prefs.getString(_notesStorageKey);
    if (savedNotes != null) {
      _notesController.text = savedNotes;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Сохранение галочек
  Future<void> _saveChecks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checksStorageKey, jsonEncode(checks));
  }

  /// Сохранение текста примечаний
  Future<void> _saveNotes(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesStorageKey, text);
  }

  /// Сброс галочек на новую неделю (примечания остаются нетронутыми)
  Future<void> _resetChecks() async {
    setState(() {
      _initDefaultChecks();
    });
    await _saveChecks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        // Поднимаем окно над клавиатурой при вводе текста
        padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Индикатор шторки сверху
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Шапка окна: Заголовок + кнопки сброса и закрытия
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Дни приема без таблеток',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetChecks,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Сброс'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Таблица с чекбоксами
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    horizontalMargin: 8,
                    headingRowHeight: 44,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 48,
                    border: TableBorder.all(
                      color: Colors.grey.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    columns: [
                      const DataColumn(
                        label: Text(
                          'Прием',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...days.map(
                        (day) => DataColumn(
                          label: Text(
                            day,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    rows: List.generate(items.length, (rowIndex) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              items[rowIndex],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ...List.generate(days.length, (colIndex) {
                            return DataCell(
                              Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Checkbox(
                                    value: checks[rowIndex][colIndex],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (bool? val) {
                                      setState(() {
                                        checks[rowIndex][colIndex] =
                                            val ?? false;
                                      });
                                      _saveChecks();
                                    },
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 16),

              // Редактируемая рамка для примечаний
              TextField(
                controller: _notesController,
                onChanged: _saveNotes,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.35),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
