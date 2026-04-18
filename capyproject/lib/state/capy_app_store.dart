import 'package:flutter/foundation.dart';

import '../data/capy_models.dart';
import '../services/firebase_service.dart';

class CapyAppStore extends ChangeNotifier {
  CapyAppStore({FirebaseService? service})
    : _service = service ?? FirebaseService.instance;

  final FirebaseService _service;

  bool _isReady = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  CapyUser? _currentUser;

  List<CapyTransaction> _transactions = const [];
  List<CapyCategory> _categories = const [];
  List<CapyGoal> _goals = const [];

  bool get isReady => _isReady;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUsername => _currentUser?.email;
  CapyUser? get currentUser => _currentUser;
  String get currentDisplayName =>
      _currentUser?.displayName.isNotEmpty == true
          ? _currentUser!.displayName
          : _currentUser?.email ?? 'User';
  double get currentPocketSaved => totalPocketSaved;
  double get currentCashBalance => availableBalance;
  double get currentSavingsGoal => _currentUser?.savingsGoal ?? 0;
  double get currentMonthlyIncome => _currentUser?.monthlyIncome ?? 0;

  List<CapyTransaction> get transactions => List.unmodifiable(_transactions);
  List<CapyCategory> get categories => List.unmodifiable(_categories);
  List<CapyGoal> get goals => List.unmodifiable(_goals);

  Future<void> initialize() async {
    try {
      final user = await _service.currentUser();
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _refreshData();
      }
    } catch (error) {
      _errorMessage = error.toString();
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      _errorMessage = null;
      if (_isLoggedIn) {
        _currentUser = await _service.currentUser();
        if (_currentUser != null) {
          await _refreshData();
        }
      }
    } catch (error) {
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> _refreshData() async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    _categories = await _service.fetchCategories(uid);
    _transactions = await _service.fetchTransactions(uid);
    _goals = await _service.fetchGoals(uid);
    _sortTransactions();
    _sortGoals();
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
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
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

  void loginUser(CapyUser user) {
    _isLoggedIn = true;
    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
    _refreshData().then((_) {
      notifyListeners();
    }).catchError((Object error) {
      _errorMessage = error.toString();
      notifyListeners();
    });
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _transactions = const [];
    _categories = const [];
    _goals = const [];
    _errorMessage = null;
    _service.signOut().catchError((_) {});
    notifyListeners();
  }

  Future<void> addTransaction({
    required String title,
    required String category,
    required String note,
    required double amount,
    required CapyTransactionType type,
    DateTime? createdAt,
    String? receiptImageUrl,
  }) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      final saved = await _service.insertTransaction(
        uid,
        CapyTransaction(
          title: title,
          category: category,
          note: note,
          amount: amount,
          type: type,
          createdAt: createdAt ?? DateTime.now(),
          receiptImageUrl: receiptImageUrl,
        ),
      );
      _transactions = [saved, ..._transactions];
      _sortTransactions();
    });
  }

  Future<void> updateTransaction(CapyTransaction transaction) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      await _service.updateTransaction(uid, transaction);
      _transactions = _transactions
          .map((item) => item.id == transaction.id ? transaction : item)
          .toList();
      _sortTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      await _service.deleteTransaction(uid, id);
      _transactions = _transactions.where((item) => item.id != id).toList();
    });
  }

  Future<void> addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      final saved = await _service.insertCategory(
        uid,
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
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      final saved = await _service.insertGoal(
        uid,
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
    final uid = _currentUser?.id;
    if (uid == null) return;
    await _performWrite(() async {
      await _service.updateGoal(uid, goal);
      _goals = _goals
          .map((item) => item.id == goal.id ? goal : item)
          .toList();
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
