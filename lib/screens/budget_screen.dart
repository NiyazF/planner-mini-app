import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_transaction.dart';
import '../services/budget_storage.dart';
import '../widgets/add_transaction_sheet.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetTransaction> _transactions = [];
  List<BudgetCategory> _categories = BudgetStorage.defaultCategories;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _filterCategoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait<dynamic>([
      BudgetStorage.loadTransactions(),
      BudgetStorage.loadCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _transactions = results[0] as List<BudgetTransaction>;
      _categories = results[1] as List<BudgetCategory>;
      _loading = false;
    });
  }

  BudgetCategory _categoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => const BudgetCategory(
        id: 'unknown',
        name: 'Категория',
        emoji: '💳',
        colorValue: 0xFF8E8E93,
        type: TransactionType.expense,
      ),
    );
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat('#,##0.##', 'ru_RU');
    return '${formatter.format(value)} ₽';
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _filterCategoryId = null;
    });
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F7FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTransactionSheet(
        categories: _categories,
        onCategoriesChanged: (updated) {
          setState(() => _categories = updated);
          BudgetStorage.saveCategories(updated);
        },
        onSave: (tx) {
          setState(() {
            _transactions.add(tx);
            _selectedMonth = DateTime(tx.date.year, tx.date.month);
          });
          BudgetStorage.saveTransactions(_transactions);
        },
      ),
    );
  }

  Future<void> _deleteTransaction(BudgetTransaction tx) async {
    setState(() {
      _transactions.removeWhere((item) => item.id == tx.id);
    });
    await BudgetStorage.saveTransactions(_transactions);
  }

  @override
  Widget build(BuildContext context) {
    final monthTransactions = _transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final totalExpense = monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final balance = totalIncome - totalExpense;
    final spentRatio = totalIncome > 0
        ? (totalExpense / totalIncome).clamp(0.0, 1.0)
        : 0.0;

    // Группировка расходов по категориям
    final Map<String, double> expenseByCategory = {};
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.expense) {
        expenseByCategory[tx.categoryId] =
            (expenseByCategory[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final visibleTransactions = _filterCategoryId == null
        ? monthTransactions
        : monthTransactions
              .where((tx) => tx.categoryId == _filterCategoryId)
              .toList();

    final monthTitle = DateFormat('LLLL yyyy', 'ru_RU').format(_selectedMonth);
    final capitalizedMonth =
        monthTitle[0].toUpperCase() + monthTitle.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бюджет'),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                capitalizedMonth,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Главная карточка баланса (в стиле MyLife)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Баланс за месяц',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMoney(balance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: balance < 0
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF16161A),
                          ),
                        ),
                        if (totalIncome > 0) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: spentRatio,
                              minHeight: 8,
                              backgroundColor: const Color(
                                0xFF34C759,
                              ).withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                spentRatio > 0.9
                                    ? const Color(0xFFFF3B30)
                                    : const Color(0xFF5856D6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Потрачено ${(spentRatio * 100).round()}% от дохода',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryBox(
                                label: 'Доходы',
                                amount: '+ ${_formatMoney(totalIncome)}',
                                color: const Color(0xFF34C759),
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryBox(
                                label: 'Расходы',
                                amount: '− ${_formatMoney(totalExpense)}',
                                color: const Color(0xFFFF3B30),
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Расходы по категориям
                if (sortedCategories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Расходы по категориям',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_filterCategoryId != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _filterCategoryId = null),
                          child: const Text('Сбросить'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: sortedCategories.map((entry) {
                          final cat = _categoryById(entry.key);
                          final share = totalExpense > 0
                              ? (entry.value / totalExpense)
                              : 0.0;
                          final isSelected = _filterCategoryId == cat.id;
                          final color = Color(cat.colorValue);

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _filterCategoryId = isSelected ? null : cat.id;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        cat.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(share * 100).round()}%',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _formatMoney(entry.value),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: share,
                                      minHeight: 6,
                                      backgroundColor: color.withValues(
                                        alpha: 0.14,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                // История операций
                const SizedBox(height: 20),
                const Text(
                  'Операции',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                if (visibleTransactions.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'Нет записей за этот период',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  )
                else
                  ...visibleTransactions.map((tx) {
                    final cat = _categoryById(tx.categoryId);
                    final isExpense = tx.type == TransactionType.expense;
                    final color = Color(cat.colorValue);

                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteTransaction(tx),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Text(
                              cat.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            tx.note.isNotEmpty
                                ? '${DateFormat('d MMM', 'ru_RU').format(tx.date)} • ${tx.note}'
                                : DateFormat('d MMMM', 'ru_RU').format(tx.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Text(
                            '${isExpense ? '−' : '+'} ${_formatMoney(tx.amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isExpense
                                  ? const Color(0xFF16161A)
                                  : const Color(0xFF34C759),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
