// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Кнопка-иконка, которую вы можете вставить в AppBar или любое место экрана
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

/// Содержимое выезжающего окна с таблицей и чекбоксами
class SupplementTrackerSheet extends StatefulWidget {
  const SupplementTrackerSheet({super.key});

  @override
  State<SupplementTrackerSheet> createState() => _SupplementTrackerSheetState();
}

class _SupplementTrackerSheetState extends State<SupplementTrackerSheet> {
  // Дни недели (сокращены для мобильного экрана, чтобы таблица была компактной)
  final List<String> days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  // Строки приема
  final List<String> items = [
    'Утро AAKG',
    'Обед AAKG',
    'Протеин Креатин',
    'Вечер ААКG',
  ];

  // Матрица состояний чекбоксов (4 строки на 7 дней)
  late List<List<bool>> checks;

  @override
  void initState() {
    super.initState();
    _initChecks();
  }

  void _initChecks() {
    checks = List.generate(
      items.length,
      (_) => List.generate(days.length, (_) => false),
    );
  }

  void _resetAll() {
    setState(() {
      _initChecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                  color: Colors.grey.withOpacity(0.4),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetAll,
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

            // Прокручиваемая таблица с чекбоксами
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 14,
                horizontalMargin: 8,
                headingRowHeight: 44,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 48,
                border: TableBorder.all(
                  color: Colors.grey.withOpacity(0.25),
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
                      // Название добавки / времени приема
                      DataCell(
                        Text(
                          items[rowIndex],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      // 7 чекбоксов по дням недели
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
                                    checks[rowIndex][colIndex] = val ?? false;
                                  });
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

            // Блок с вашими примечаниями из строк 8-10
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• В случае приема таблеток сделать перерыв на AAKG на сутки. След прием 1000 мг (2 капс)',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• Если курс 2 недели пропит, пампинг не увеличился, вес и силовые стоят, увеличить AAKG в обед до 1000 мг (2 капс)',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Дата начала: 14.11.2026',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
