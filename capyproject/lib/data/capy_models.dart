import 'package:flutter/material.dart';

enum CapyTransactionType { expense, income, pocket }

CapyTransactionType transactionTypeFromName(String raw) {
  return CapyTransactionType.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => CapyTransactionType.expense,
  );
}

String formatMoney(double value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  final parts = absolute.toStringAsFixed(2).split('.');
  final digits = parts[0];
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$sign฿${buffer.toString()}.${parts[1]}';
}

String formatShortDate(DateTime value) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${monthNames[value.month - 1]} ${value.day}, ${value.year}';
}

String formatTimeLabel(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class CapyUser {
  const CapyUser({
    this.id,
    required this.email,
    required this.displayName,
    required this.monthlyIncome,
    required this.savingsGoal,
    required this.createdAt,
  });

  final String? id;
  final String email;
  final String displayName;
  final double monthlyIncome;
  final double savingsGoal;
  final DateTime createdAt;

  CapyUser copyWith({
    String? id,
    String? email,
    String? displayName,
    double? monthlyIncome,
    double? savingsGoal,
    DateTime? createdAt,
  }) {
    return CapyUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CapyTransaction {
  const CapyTransaction({
    this.id,
    required this.title,
    required this.category,
    required this.note,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.receiptImageUrl,
  });

  final String? id;
  final String title;
  final String category;
  final String note;
  final double amount;
  final CapyTransactionType type;
  final DateTime createdAt;
  final String? receiptImageUrl;

  bool get isPositive => type != CapyTransactionType.expense;

  String get signedAmountLabel {
    final prefix = isPositive ? '+' : '-';
    return '$prefix${formatMoney(amount).replaceFirst('฿', '฿')}';
  }

  String get typeLabel => switch (type) {
    CapyTransactionType.expense => 'Expense',
    CapyTransactionType.income => 'Income',
    CapyTransactionType.pocket => 'Pocket',
  };

  CapyTransaction copyWith({
    String? id,
    String? title,
    String? category,
    String? note,
    double? amount,
    CapyTransactionType? type,
    DateTime? createdAt,
    Object? receiptImageUrl = _unset,
  }) {
    return CapyTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      receiptImageUrl: receiptImageUrl == _unset
          ? this.receiptImageUrl
          : receiptImageUrl as String?,
    );
  }
}

const Object _unset = Object();

class CapyCategory {
  const CapyCategory({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String? id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  CapyCategory copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return CapyCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class CapyGoal {
  const CapyGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.createdAt,
  });

  final String? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime createdAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    final ratio = savedAmount / targetAmount;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  CapyGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? createdAt,
  }) {
    return CapyGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
