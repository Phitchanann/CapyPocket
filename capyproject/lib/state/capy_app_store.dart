import 'package:flutter/foundation.dart';

import '../data/capy_database.dart';
import '../data/capy_models.dart';

class CapyAppStore extends ChangeNotifier {
  CapyAppStore({CapyDatabase? database})
    : _database = database ?? CapyDatabase.instance;

  final CapyDatabase _database;

  bool _isReady = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  String? _currentUsername;
  CapyUser? _currentUser;

  List<CapyTransaction> _transactions = const [];
  List<CapyCategory> _categories = const [];
  List<CapyGoal> _goals = const [];

  bool get isReady => _isReady;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUsername => _currentUsername;
  CapyUser? get currentUser => _currentUser;
  String get currentDisplayName =>
      _currentUser?.displayName ?? _currentUsername ?? 'User';
  double get currentPocketSaved =>
      _currentUser?.pocketSaved ?? totalPocketSaved;
  double get currentCashBalance =>
      _currentUser?.cashBalance ?? availableBalance;
  double get currentSavingsGoal => _currentUser?.savingsGoal ?? 0;

  List<CapyTransaction> get transactions => List.unmodifiable(_transactions);
  List<CapyCategory> get categories => List.unmodifiable(_categories);
  List<CapyGoal> get goals => List.unmodifiable(_goals);

  Future<void> initialize() async {
    await refresh();
    _isReady = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _errorMessage = null;
      _currentUser = await _database.currentUser();
      _categories = await _database.fetchCategories();
      _transactions = await _database.fetchTransactions();
      _goals = await _database.fetchGoals();
      _sortTransactions();
      _sortGoals();
    } catch (error) {
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  double get totalIncome => _transactions
      .where((item) => item.type == CapyTransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((item) => item.type == CapyTransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalPocketSaved => _transactions
      .where((item) => item.type == CapyTransactionType.pocket)
      .fold(0, (sum, item) => sum + item.amount);

  double get availableBalance => totalIncome - totalExpense;
  double get totalNetWorth => availableBalance + totalPocketSaved;
  int get transactionCount => _transactions.length;
  int get activeGoalCount => _goals.length;

  CapyGoal? get primaryGoal => _goals.isEmpty ? null : _goals.first;

  List<CapyTransaction> recentTransactions({int limit = 4}) {
    return _transactions.take(limit).toList();
  }

  List<double> get weeklyExpensePoints {
    final now = DateTime.now();
    return List<double>.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      return _transactions
          .where(
            (item) =>
                item.type == CapyTransactionType.expense &&
                item.createdAt.year == day.year &&
                item.createdAt.month == day.month &&
                item.createdAt.day == day.day,
          )
          .fold(0, (sum, item) => sum + item.amount);
    });
  }

  Map<String, double> get expenseByCategory {
    final result = <String, double>{};
    for (final item in _transactions.where(
      (entry) => entry.type == CapyTransactionType.expense,
    )) {
      result.update(
        item.category,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    return result;
  }

  void login(String username) {
    _isLoggedIn = true;
    _currentUsername = username;
    notifyListeners();
  }

  void loginUser(CapyUser user) {
    _isLoggedIn = true;
    _currentUsername = user.username;
    _currentUser = user;
    _database.setActiveUserId(user.id);
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _currentUsername = null;
    _currentUser = null;
    _database.setActiveUserId(null);
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required String note,
    required double amount,
    required CapyTransactionType type,
    DateTime? createdAt,
  }) async {
    await _performWrite(() async {
      final saved = await _database.insertTransaction(
        CapyTransaction(
          title: title,
          category: category,
          note: note,
          amount: amount,
          type: type,
          createdAt: createdAt ?? DateTime.now(),
        ),
      );
      _transactions = [saved, ..._transactions];
      _sortTransactions();
    });
  }

  Future<void> updateTransaction(CapyTransaction transaction) async {
    await _performWrite(() async {
      await _database.updateTransaction(transaction);
      _transactions = _transactions
          .map((item) => item.id == transaction.id ? transaction : item)
          .toList();
      _sortTransactions();
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _performWrite(() async {
      await _database.deleteTransaction(id);
      _transactions = _transactions.where((item) => item.id != id).toList();
    });
  }

  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    await _performWrite(() async {
      final saved = await _database.insertCategory(
        CapyCategory(
          name: name.trim(),
          iconCodePoint: iconCodePoint,
          colorValue: colorValue,
        ),
      );
      _categories = [..._categories, saved]
        ..sort((left, right) => left.name.compareTo(right.name));
    });
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required double savedAmount,
  }) async {
    await _performWrite(() async {
      final saved = await _database.insertGoal(
        CapyGoal(
          name: name.trim(),
          targetAmount: targetAmount,
          savedAmount: savedAmount,
          createdAt: DateTime.now(),
        ),
      );
      _goals = [saved, ..._goals];
      _sortGoals();
    });
  }

  Future<void> updateGoal(CapyGoal goal) async {
    await _performWrite(() async {
      await _database.updateGoal(goal);
      _goals = _goals.map((item) => item.id == goal.id ? goal : item).toList();
      _sortGoals();
    });
  }

  Future<void> _performWrite(Future<void> Function() action) async {
    try {
      _errorMessage = null;
      _isSaving = true;
      notifyListeners();
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _sortTransactions() {
    _transactions = [..._transactions]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  void _sortGoals() {
    _goals = [..._goals]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }
}
