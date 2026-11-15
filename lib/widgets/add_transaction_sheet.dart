import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/budget_transaction.dart';
import 'emoji_picker_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<BudgetCategory> categories;
  final ValueChanged<BudgetTransaction> onSave;
  final ValueChanged<List<BudgetCategory>> onCategoriesChanged;

  const AddTransactionSheet({
    super.key,
    required this.categories,
    required this.onSave,
    required this.onCategoriesChanged,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  late List<BudgetCategory> _categories;
  String? _selectedCategoryId;

  List<BudgetCategory> get _filteredCategories =>
      _categories.where((c) => c.type == _type).toList();

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
    _selectedCategoryId = _filteredCategories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _selectedCategoryId = _filteredCategories.firstOrNull?.id;
    });
  }

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    var emoji = _type == TransactionType.expense ? '🛍️' : '💵';
    var color = 0xFF5856D6;

    const palette = [
      0xFF5856D6,
      0xFF34C759,
      0xFFFF9500,
      0xFF007AFF,
      0xFFFF3B30,
      0xFFAF52DE,
      0xFFFF2D55,
      0xFF00C7BE,
    ];

    final created = await showDialog<BudgetCategory>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            _type == TransactionType.expense
                ? 'Новая категория расхода'
                : 'Новая категория дохода',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => EmojiPickerSheet(
                          onSelected: (value) {
                            setDialogState(() => emoji = value);
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color(color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(hintText: 'Название'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: palette.map((c) {
                  final selected = c == color;
                  return GestureDetector(
                    onTap: () => setDialogState(() => color = c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      radius: selected ? 17 : 14,
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  BudgetCategory(
                    id: 'cat_${DateTime.now().microsecondsSinceEpoch}',
                    name: name,
                    emoji: emoji,
                    colorValue: color,
                    type: _type,
                  ),
                );
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    if (created == null) return;

    final updated = [..._categories, created];
    widget.onCategoriesChanged(updated);
    setState(() {
      _categories = updated;
      _selectedCategoryId = created.id;
    });
  }

  void _submit() {
    final cleaned = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) return;

    widget.onSave(
      BudgetTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        note: _noteController.text.trim(),
        date: _date,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isExpense = _type == TransactionType.expense;
    final accentColor = isExpense
        ? const Color(0xFFFF3B30)
        : const Color(0xFF34C759);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Переключатель Расход / Доход
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEF4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeTab(
                        title: 'Расход',
                        selected: isExpense,
                        activeColor: const Color(0xFFFF3B30),
                        onTap: () => _switchType(TransactionType.expense),
                      ),
                    ),
                    Expanded(
                      child: _TypeTab(
                        title: 'Доход',
                        selected: !isExpense,
                        activeColor: const Color(0xFF34C759),
                        onTap: () => _switchType(TransactionType.income),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ввод суммы
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
                decoration: InputDecoration(
                  hintText: '0 ₽',
                  hintStyle: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Категории
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Категория',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: _createCategory,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Своя'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredCategories.map((cat) {
                  final selected = cat.id == _selectedCategoryId;
                  final color = Color(cat.colorValue);
                  return ChoiceChip(
                    avatar: Text(cat.emoji),
                    label: Text(cat.name),
                    selected: selected,
                    selectedColor: color.withValues(alpha: 0.18),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      color: selected ? color : const Color(0xFF16161A),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = cat.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Дата и комментарий
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        locale: const Locale('ru'),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('d MMM', 'ru_RU').format(_date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Комментарий (необязательно)',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isExpense ? 'Добавить расход' : 'Добавить доход',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

class _TypeTab extends StatelessWidget {
  final String title;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.title,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? activeColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
