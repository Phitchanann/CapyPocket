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
  });

  final int? id;
  final String title;
  final String category;
  final String note;
  final double amount;
  final CapyTransactionType type;
  final DateTime createdAt;

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
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
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
  }) {
    return CapyTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

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
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
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
