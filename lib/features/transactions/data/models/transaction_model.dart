// lib/features/transactions/data/models/transaction_model.dart

enum TransactionType {
  income,
  expense,
}

enum TransactionCategory {
  // Income categories
  salary,
  freelance,
  investment,
  other,

  // Expense categories
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  education,
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // From JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TransactionCategory.other,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Copy with
  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Category helpers
extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      // Income
      case TransactionCategory.salary:
        return 'Maaş';
      case TransactionCategory.freelance:
        return 'Serbest Çalışma';
      case TransactionCategory.investment:
        return 'Yatırım';
      case TransactionCategory.other:
        return 'Diğer';
      // Expense
      case TransactionCategory.food:
        return 'Yemek & İçecek';
      case TransactionCategory.transport:
        return 'Ulaşım';
      case TransactionCategory.shopping:
        return 'Alışveriş';
      case TransactionCategory.bills:
        return 'Faturalar';
      case TransactionCategory.entertainment:
        return 'Eğlence';
      case TransactionCategory.health:
        return 'Sağlık';
      case TransactionCategory.education:
        return 'Eğitim';
    }
  }

  String get icon {
    switch (this) {
      // Income
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.other:
        return '💰';
      // Expense
      case TransactionCategory.food:
        return '🍔';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛒';
      case TransactionCategory.bills:
        return '📄';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
    }
  }

  static List<TransactionCategory> getIncomeCategories() {
    return [
      TransactionCategory.salary,
      TransactionCategory.freelance,
      TransactionCategory.investment,
      TransactionCategory.other,
    ];
  }

  static List<TransactionCategory> getExpenseCategories() {
    return [
      TransactionCategory.food,
      TransactionCategory.transport,
      TransactionCategory.shopping,
      TransactionCategory.bills,
      TransactionCategory.entertainment,
      TransactionCategory.health,
      TransactionCategory.education,
    ];
  }
}
