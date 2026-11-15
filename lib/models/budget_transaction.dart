enum TransactionType { expense, income }

class BudgetCategory {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final TransactionType type;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.type,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💰',
      colorValue: json['colorValue'] as int? ?? 0xFF5856D6,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'colorValue': colorValue,
    'type': type.name,
  };
}

class BudgetTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String note;
  final DateTime date;

  const BudgetTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    required this.date,
  });

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.name,
    'categoryId': categoryId,
    'note': note,
    'date': date.toIso8601String(),
  };
}
