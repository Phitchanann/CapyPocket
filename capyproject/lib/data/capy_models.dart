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

class CapyUser {
  const CapyUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.displayName,
    required this.monthlyIncome,
    required this.cashBalance,
    required this.pocketSaved,
    required this.savingsGoal,
    required this.createdAt,
  });

  final int? id;
  final String username;
  final String passwordHash;
  final String displayName;
  final double monthlyIncome;
  final double cashBalance;
  final double pocketSaved;
  final double savingsGoal;
  final DateTime createdAt;

  double get netWorth => cashBalance + pocketSaved;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'display_name': displayName,
      'monthly_income': monthlyIncome,
      'cash_balance': cashBalance,
      'pocket_saved': pocketSaved,
      'savings_goal': savingsGoal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CapyUser.fromMap(Map<String, Object?> map) {
    return CapyUser(
      id: map['id'] as int?,
      username: map['username'] as String? ?? 'mint.capy',
      passwordHash: map['password_hash'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Mint Capy',
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 0,
      cashBalance: (map['cash_balance'] as num?)?.toDouble() ?? 0,
      pocketSaved: (map['pocket_saved'] as num?)?.toDouble() ?? 0,
      savingsGoal: (map['savings_goal'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  CapyUser copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? displayName,
    double? monthlyIncome,
    double? cashBalance,
    double? pocketSaved,
    double? savingsGoal,
    DateTime? createdAt,
  }) {
    return CapyUser(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      cashBalance: cashBalance ?? this.cashBalance,
      pocketSaved: pocketSaved ?? this.pocketSaved,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String formatShortDate(DateTime value) {
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${monthNames[value.month - 1]} ${value.day}, ${value.year}';
}

String formatTimeLabel(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
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

  final int? id;
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

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'note': note,
      'amount': amount,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'receipt_image_url': receiptImageUrl,
    };
  }

  factory CapyTransaction.fromMap(Map<String, Object?> map) {
    return CapyTransaction(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      note: map['note'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: transactionTypeFromName(map['type'] as String? ?? 'expense'),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      receiptImageUrl: map['receipt_image_url'] as String?,
    );
  }

  CapyTransaction copyWith({
    int? id,
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

  final int? id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCodePoint,
      'color_value': colorValue,
    };
  }

  factory CapyCategory.fromMap(Map<String, Object?> map) {
    return CapyCategory(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Category',
      iconCodePoint: map['icon_code'] as int? ?? Icons.category.codePoint,
      colorValue:
          map['color_value'] as int? ?? const Color(0xFFC38B55).toARGB32(),
    );
  }

  CapyCategory copyWith({
    int? id,
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

  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime createdAt;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }

    final ratio = savedAmount / targetAmount;
    if (ratio < 0) {
      return 0;
    }
    if (ratio > 1) {
      return 1;
    }
    return ratio;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CapyGoal.fromMap(Map<String, Object?> map) {
    return CapyGoal(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'First Pocket',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0,
      savedAmount: (map['saved_amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  CapyGoal copyWith({
    int? id,
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
