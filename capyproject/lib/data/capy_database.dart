import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'capy_models.dart';

class CapyDatabase {
  CapyDatabase._();

  static final CapyDatabase instance = CapyDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'capypocket.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await _ensureSchema(db);
        await _seedDefaultCategories(db);
      },
      onOpen: (db) async {
        await _ensureSchema(db);
        await _seedDefaultCategories(db);
      },
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final existingRows = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if ((existingRows ?? 0) > 0) {
      return;
    }

    final defaults = [
      CapyCategory(
        name: 'Food',
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        colorValue: const Color(0xFFE0A066).toARGB32(),
      ),
      CapyCategory(
        name: 'Bills',
        iconCodePoint: Icons.receipt_long_rounded.codePoint,
        colorValue: const Color(0xFFBF6B59).toARGB32(),
      ),
      CapyCategory(
        name: 'Travel',
        iconCodePoint: Icons.directions_car_filled_rounded.codePoint,
        colorValue: const Color(0xFF4F8D69).toARGB32(),
      ),
      CapyCategory(
        name: 'Pocket',
        iconCodePoint: Icons.savings_rounded.codePoint,
        colorValue: const Color(0xFFC38B55).toARGB32(),
      ),
      CapyCategory(
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag_rounded.codePoint,
        colorValue: const Color(0xFF9B6ACD).toARGB32(),
      ),
    ];

    final batch = db.batch();
    for (final category in defaults) {
      batch.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CapyTransaction>> fetchTransactions() async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(CapyTransaction.fromMap).toList();
  }

  Future<CapyTransaction> insertTransaction(CapyTransaction transaction) async {
    final db = await database;
    final id = await db.insert('transactions', transaction.toMap());
    return transaction.copyWith(id: id);
  }

  Future<void> updateTransaction(CapyTransaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CapyCategory>> fetchCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(CapyCategory.fromMap).toList();
  }

  Future<CapyCategory> insertCategory(CapyCategory category) async {
    final db = await database;
    final id = await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return category.copyWith(id: id);
  }

  Future<List<CapyGoal>> fetchGoals() async {
    final db = await database;
    final rows = await db.query(
      'goals',
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(CapyGoal.fromMap).toList();
  }

  Future<CapyGoal> insertGoal(CapyGoal goal) async {
    final db = await database;
    final id = await db.insert('goals', goal.toMap());
    return goal.copyWith(id: id);
  }

  Future<void> updateGoal(CapyGoal goal) async {
    final db = await database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }
}
