import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_transaction.dart';

class BudgetStorage {
  static const _transactionsKey = 'budget_transactions_v1';
  static const _categoriesKey = 'budget_categories_v1';

  static const List<BudgetCategory> defaultCategories = [
    // Расходы
    BudgetCategory(
      id: 'exp_food',
      name: 'Продукты',
      emoji: '🛒',
      colorValue: 0xFF34C759,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_cafe',
      name: 'Кафе',
      emoji: '☕',
      colorValue: 0xFFFF9500,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_transport',
      name: 'Транспорт',
      emoji: '🚕',
      colorValue: 0xFF007AFF,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_home',
      name: 'Дом и ЖКХ',
      emoji: '🏠',
      colorValue: 0xFF5856D6,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_health',
      name: 'Здоровье',
      emoji: '💊',
      colorValue: 0xFFFF3B30,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_fun',
      name: 'Отдых',
      emoji: '🎮',
      colorValue: 0xFFAF52DE,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_clothes',
      name: 'Одежда',
      emoji: '👕',
      colorValue: 0xFFFF2D55,
      type: TransactionType.expense,
    ),
    BudgetCategory(
      id: 'exp_other',
      name: 'Другое',
      emoji: '📦',
      colorValue: 0xFF8E8E93,
      type: TransactionType.expense,
    ),

    // Доходы
    BudgetCategory(
      id: 'inc_salary',
      name: 'Зарплата',
      emoji: '💼',
      colorValue: 0xFF34C759,
      type: TransactionType.income,
    ),
    BudgetCategory(
      id: 'inc_freelance',
      name: 'Подработка',
      emoji: '💻',
      colorValue: 0xFF007AFF,
      type: TransactionType.income,
    ),
    BudgetCategory(
      id: 'inc_gift',
      name: 'Подарки',
      emoji: '🎁',
      colorValue: 0xFFFF9500,
      type: TransactionType.income,
    ),
    BudgetCategory(
      id: 'inc_other',
      name: 'Другое',
      emoji: '💰',
      colorValue: 0xFF5856D6,
      type: TransactionType.income,
    ),
  ];

  static Future<List<BudgetTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded
        .map((e) => BudgetTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveTransactions(List<BudgetTransaction> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _transactionsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<BudgetCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoriesKey);
    if (raw == null) return List.of(defaultCategories);
    final List decoded = jsonDecode(raw);
    return decoded
        .map((e) => BudgetCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveCategories(List<BudgetCategory> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _categoriesKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
