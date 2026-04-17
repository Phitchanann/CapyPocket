import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'capy_models.dart';

class CapyDatabase {
  CapyDatabase._();

  static final CapyDatabase instance = CapyDatabase._();
  static const Duration _mysqlConnectTimeout = Duration(seconds: 3);
  static const Duration _mysqlHealthTimeout = Duration(seconds: 2);

  bool get _useMySql => _envBool(
    'CAPY_USE_MYSQL',
    const String.fromEnvironment('CAPY_USE_MYSQL', defaultValue: 'false'),
  );
  String get _mysqlHost => _envText(
    'CAPY_MYSQL_HOST',
    const String.fromEnvironment('CAPY_MYSQL_HOST', defaultValue: '127.0.0.1'),
  );
  int get _mysqlPort => _envInt(
    'CAPY_MYSQL_PORT',
    const String.fromEnvironment('CAPY_MYSQL_PORT', defaultValue: '3306'),
  );
  String get _mysqlUser => _envText(
    'CAPY_MYSQL_USER',
    const String.fromEnvironment('CAPY_MYSQL_USER', defaultValue: 'root'),
  );
  String get _mysqlPassword => _envText(
    'CAPY_MYSQL_PASSWORD',
    const String.fromEnvironment('CAPY_MYSQL_PASSWORD', defaultValue: ''),
  );
  String get _mysqlDatabase => _envText(
    'CAPY_MYSQL_DATABASE',
    const String.fromEnvironment(
      'CAPY_MYSQL_DATABASE',
      defaultValue: 'capypocket',
    ),
  );
  bool get _mysqlSecure => _envBool(
    'CAPY_MYSQL_SECURE',
    const String.fromEnvironment('CAPY_MYSQL_SECURE', defaultValue: 'true'),
  );

  Database? _database;
  MySQLConnection? _mysql;
  bool _mysqlUnavailable = false;
  static const int _defaultUserId = 1;
  int _activeUserId = _defaultUserId;

  bool get _activeMySql => _useMySql && !_mysqlUnavailable;

  void setActiveUserId(int? userId) {
    _activeUserId = userId ?? _defaultUserId;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<MySQLConnection> get mysql async {
    if (!_activeMySql) {
      throw StateError('MySQL is disabled or unavailable.');
    }

    if (_mysql != null) {
      return _mysql!;
    }

    try {
      final connection = await MySQLConnection.createConnection(
        host: _mysqlHost,
        port: _mysqlPort,
        userName: _mysqlUser,
        password: _mysqlPassword,
        databaseName: _mysqlDatabase,
        secure: _mysqlSecure,
      );
      await connection.connect().timeout(_mysqlConnectTimeout);
      await _ensureMySqlSchema(connection);
      await _seedDefaultUsersMySql(connection);
      await _seedDefaultCategoriesMySql(connection);
      _mysql = connection;
      return _mysql!;
    } catch (_) {
      _mysqlUnavailable = true;
      rethrow;
    }
  }

  Future<CapyDatabaseHealth> checkHealth() async {
    final startedAt = DateTime.now();
    try {
      if (_activeMySql) {
        try {
          await _probeMySqlHealth();
          final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
          return CapyDatabaseHealth(
            mode: 'MySQL',
            connected: true,
            detail: '$_mysqlUser@$_mysqlHost:$_mysqlPort/$_mysqlDatabase',
            checkedAt: DateTime.now(),
            latencyMs: elapsed,
          );
        } catch (_) {
          _mysqlUnavailable = true;
        }
      }

      final db = await database;
      await db.rawQuery('SELECT 1 AS health');
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      return CapyDatabaseHealth(
        mode: _useMySql ? 'SQLite (fallback)' : 'SQLite',
        connected: true,
        detail: _useMySql
            ? 'MySQL unavailable, using local device database'
            : 'Local device database',
        checkedAt: DateTime.now(),
        latencyMs: elapsed,
      );
    } catch (error) {
      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      return CapyDatabaseHealth(
        mode: _activeMySql ? 'MySQL' : 'SQLite',
        connected: false,
        detail: error.toString(),
        checkedAt: DateTime.now(),
        latencyMs: elapsed,
      );
    }
  }

  Future<void> _probeMySqlHealth() async {
    if (_mysql != null) {
      await _mysql!.execute('SELECT 1 AS health').timeout(_mysqlHealthTimeout);
      return;
    }

    final probe = await MySQLConnection.createConnection(
      host: _mysqlHost,
      port: _mysqlPort,
      userName: _mysqlUser,
      password: _mysqlPassword,
      databaseName: _mysqlDatabase,
      secure: _mysqlSecure,
    );

    try {
      await probe.connect().timeout(_mysqlConnectTimeout);
      await probe.execute('SELECT 1 AS health').timeout(_mysqlHealthTimeout);
    } finally {
      await probe.close();
    }
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'capypocket.db');

    return openDatabase(
      fullPath,
      version: 4,
      onCreate: (db, version) async {
        await _ensureSchema(db);
        await _seedDefaultUsers(db);
        await _seedDefaultCategories(db);
      },
      onOpen: (db) async {
        await _ensureSchema(db);
        await _seedDefaultUsers(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeToMultiUserSchema(db);
          await _seedDefaultUsers(db);
        }
        if (oldVersion < 3) {
          await _upgradeToLoginSchema(db);
          await _seedDefaultUsers(db);
        }
        if (oldVersion < 4) {
          await _upgradeToReceiptSchema(db);
        }
      },
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        monthly_income REAL NOT NULL,
        cash_balance REAL NOT NULL,
        pocket_saved REAL NOT NULL,
        savings_goal REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        receipt_image_url TEXT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE(user_id, name),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_created_at '
      'ON transactions (user_id, created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_type '
      'ON transactions (user_id, type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_category '
      'ON transactions (user_id, category)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS uk_categories_user_name '
      'ON categories (user_id, name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_goals_user_created_at '
      'ON goals (user_id, created_at DESC)',
    );
  }

  Future<void> _upgradeToMultiUserSchema(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'transactions',
      columnName: 'user_id',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'transactions',
      columnName: 'deleted_at',
      columnDefinition: 'TEXT NULL',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'categories',
      columnName: 'user_id',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'categories',
      columnName: 'deleted_at',
      columnDefinition: 'TEXT NULL',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'goals',
      columnName: 'user_id',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 1',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'goals',
      columnName: 'deleted_at',
      columnDefinition: 'TEXT NULL',
    );
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'password_hash',
      columnDefinition: 'TEXT NOT NULL DEFAULT ""',
    );

    await db.execute(
      'UPDATE transactions SET user_id = 1 WHERE user_id IS NULL',
    );
    await db.execute('UPDATE categories SET user_id = 1 WHERE user_id IS NULL');
    await db.execute('UPDATE goals SET user_id = 1 WHERE user_id IS NULL');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS uk_categories_user_name '
      'ON categories (user_id, name)',
    );
  }

  Future<void> _upgradeToLoginSchema(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'users',
      columnName: 'password_hash',
      columnDefinition: 'TEXT NOT NULL DEFAULT ""',
    );
    await db.update(
      'users',
      {'password_hash': _hashPassword('capy123')},
      where: 'username = ? AND (password_hash = "" OR password_hash IS NULL)',
      whereArgs: ['mint.capy'],
    );
  }

  Future<void> _upgradeToReceiptSchema(Database db) async {
    await _addColumnIfMissing(
      db,
      tableName: 'transactions',
      columnName: 'receipt_image_url',
      columnDefinition: 'TEXT NULL',
    );
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }

  Future<void> _seedDefaultUsers(Database db) async {
    await db.insert(
      'users',
      CapyUser(
        id: _defaultUserId,
        username: 'mint.capy',
        passwordHash: _hashPassword('capy123'),
        displayName: 'Mint Capy',
        monthlyIncome: 32000,
        cashBalance: 11850,
        pocketSaved: 2450,
        savingsGoal: 15000,
        createdAt: DateTime.parse('2026-04-15T00:00:00.000'),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _ensureMySqlSchema(MySQLConnection connection) async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        username VARCHAR(100) NOT NULL UNIQUE,
        password_hash VARCHAR(64) NOT NULL,
        display_name VARCHAR(150) NOT NULL,
        monthly_income DECIMAL(12,2) NOT NULL,
        cash_balance DECIMAL(12,2) NOT NULL,
        pocket_saved DECIMAL(12,2) NOT NULL,
        savings_goal DECIMAL(12,2) NOT NULL,
        created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
        updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT UNSIGNED NOT NULL DEFAULT 1,
        title VARCHAR(255) NOT NULL,
        category VARCHAR(100) NOT NULL,
        note TEXT NOT NULL,
        amount DECIMAL(12,2) NOT NULL,
        type ENUM('expense','income','pocket') NOT NULL,
        created_at DATETIME(3) NOT NULL,
        updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
        deleted_at DATETIME(3) NULL,
        CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT UNSIGNED NOT NULL DEFAULT 1,
        name VARCHAR(100) NOT NULL,
        icon_code INT UNSIGNED NOT NULL,
        color_value INT UNSIGNED NOT NULL,
        updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
        deleted_at DATETIME(3) NULL,
        CONSTRAINT uk_categories_user_name UNIQUE (user_id, name),
        CONSTRAINT fk_categories_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');

    await connection.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
        user_id BIGINT UNSIGNED NOT NULL DEFAULT 1,
        name VARCHAR(150) NOT NULL,
        target_amount DECIMAL(12,2) NOT NULL,
        saved_amount DECIMAL(12,2) NOT NULL,
        created_at DATETIME(3) NOT NULL,
        updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
        deleted_at DATETIME(3) NULL,
        CONSTRAINT fk_goals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        CONSTRAINT chk_goals_target_positive CHECK (target_amount > 0),
        CONSTRAINT chk_goals_saved_non_negative CHECK (saved_amount >= 0)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ''');

    await connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_created_at '
      'ON transactions (user_id, created_at)',
    );
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_type '
      'ON transactions (user_id, type)',
    );
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_category '
      'ON transactions (user_id, category)',
    );
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_user_name '
      'ON categories (user_id, name)',
    );
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS idx_goals_user_created_at '
      'ON goals (user_id, created_at)',
    );
  }

  Future<void> _seedDefaultUsersMySql(MySQLConnection connection) async {
    await connection.execute(
      'INSERT INTO users '
      '(id, username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at) '
      'VALUES (:id, :username, :passwordHash, :displayName, :monthlyIncome, :cashBalance, :pocketSaved, :savingsGoal, :createdAt) '
      'ON DUPLICATE KEY UPDATE '
      'username = VALUES(username), display_name = VALUES(display_name), '
      'password_hash = VALUES(password_hash), '
      'monthly_income = VALUES(monthly_income), cash_balance = VALUES(cash_balance), '
      'pocket_saved = VALUES(pocket_saved), savings_goal = VALUES(savings_goal)',
      {
        'id': _defaultUserId,
        'username': 'mint.capy',
        'passwordHash': _hashPassword('capy123'),
        'displayName': 'Mint Capy',
        'monthlyIncome': 32000,
        'cashBalance': 11850,
        'pocketSaved': 2450,
        'savingsGoal': 15000,
        'createdAt': _formatDateTimeForSql(
          DateTime.parse('2026-04-15T00:00:00.000'),
        ),
      },
    );
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final existingRows = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories WHERE user_id = ?', [
        _defaultUserId,
      ]),
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
      batch.insert('categories', {
        ...category.toMap(),
        'user_id': _defaultUserId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedDefaultCategoriesMySql(MySQLConnection connection) async {
    final existingRows = await connection.execute(
      'SELECT COUNT(*) AS total FROM categories WHERE user_id = :userId',
      {'userId': _defaultUserId},
    );
    final total =
        int.tryParse(existingRows.rows.first.assoc()['total'] ?? '0') ?? 0;
    if (total > 0) {
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

    for (final category in defaults) {
      await connection.execute(
        'INSERT INTO categories (user_id, name, icon_code, color_value) VALUES (:userId, :name, :iconCode, :colorValue) '
        'ON DUPLICATE KEY UPDATE icon_code = VALUES(icon_code), color_value = VALUES(color_value)',
        {
          'userId': _defaultUserId,
          'name': category.name,
          'iconCode': category.iconCodePoint,
          'colorValue': category.colorValue,
        },
      );
    }
  }

  Future<CapyUser?> fetchUserById(int userId) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at '
          'FROM users WHERE id = :id',
          {'id': userId},
        );
        if (result.rows.isEmpty) {
          return null;
        }
        return _userFromMySqlMap(result.rows.first.assoc());
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) {
      return null;
    }
    return CapyUser.fromMap(rows.first);
  }

  Future<CapyUser?> fetchUserByUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at '
          'FROM users WHERE username = :username',
          {'username': normalized},
        );
        if (result.rows.isEmpty) {
          return null;
        }
        return _userFromMySqlMap(result.rows.first.assoc());
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return CapyUser.fromMap(rows.first);
  }

  Future<List<CapyUser>> fetchUsers() async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at '
          'FROM users ORDER BY id ASC',
        );
        return result.rows
            .map((row) => _userFromMySqlMap(row.assoc()))
            .toList();
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query('users', orderBy: 'id ASC');
    return rows.map(CapyUser.fromMap).toList();
  }

  Future<CapyUser?> authenticateUser({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return null;
    }

    final passwordHash = _hashPassword(password);

    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at '
          'FROM users WHERE username = :username AND password_hash = :passwordHash LIMIT 1',
          {'username': normalizedUsername, 'passwordHash': passwordHash},
        );
        if (result.rows.isEmpty) {
          return null;
        }
        return _userFromMySqlMap(result.rows.first.assoc());
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [normalizedUsername, passwordHash],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return CapyUser.fromMap(rows.first);
  }

  Future<CapyUser?> createUser({
    required String username,
    required String password,
    String? displayName,
    double monthlyIncome = 0,
    double cashBalance = 0,
    double pocketSaved = 0,
    double savingsGoal = 0,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw ArgumentError('Username and password are required.');
    }

    final user = CapyUser(
      username: normalizedUsername,
      passwordHash: _hashPassword(password),
      displayName: (displayName?.trim().isNotEmpty ?? false)
          ? displayName!.trim()
          : normalizedUsername,
      monthlyIncome: monthlyIncome,
      cashBalance: cashBalance,
      pocketSaved: pocketSaved,
      savingsGoal: savingsGoal,
      createdAt: DateTime.now(),
    );

    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'INSERT INTO users (username, password_hash, display_name, monthly_income, cash_balance, pocket_saved, savings_goal, created_at) '
          'VALUES (:username, :passwordHash, :displayName, :monthlyIncome, :cashBalance, :pocketSaved, :savingsGoal, :createdAt)',
          {
            'username': user.username,
            'passwordHash': user.passwordHash,
            'displayName': user.displayName,
            'monthlyIncome': user.monthlyIncome,
            'cashBalance': user.cashBalance,
            'pocketSaved': user.pocketSaved,
            'savingsGoal': user.savingsGoal,
            'createdAt': _formatDateTimeForSql(user.createdAt),
          },
        );
        return fetchUserByUsername(user.username);
      } catch (_) {
        _mysqlUnavailable = true;
        rethrow;
      }
    }

    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<List<CapyTransaction>> fetchTransactions() async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, title, category, note, amount, type, receipt_image_url, created_at '
          'FROM transactions '
          'WHERE user_id = :userId AND deleted_at IS NULL '
          'ORDER BY created_at DESC',
          {'userId': _activeUserId},
        );
        return result.rows
            .map((row) => _transactionFromMySqlMap(row.assoc()))
            .toList();
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [_activeUserId],
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(CapyTransaction.fromMap).toList();
  }

  Future<CapyTransaction> insertTransaction(CapyTransaction transaction) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'INSERT INTO transactions (user_id, title, category, note, amount, type, created_at, receipt_image_url) '
          'VALUES (:userId, :title, :category, :note, :amount, :type, :createdAt, :receiptImageUrl)',
          {
            'userId': _activeUserId,
            'title': transaction.title,
            'category': transaction.category,
            'note': transaction.note,
            'amount': transaction.amount,
            'type': transaction.type.name,
            'createdAt': _formatDateTimeForSql(transaction.createdAt),
            'receiptImageUrl': transaction.receiptImageUrl,
          },
        );

        final idResult = await connection.execute(
          'SELECT LAST_INSERT_ID() AS id',
        );
        final id = int.tryParse(idResult.rows.first.assoc()['id'] ?? '0');
        return transaction.copyWith(id: id == 0 ? null : id);
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final id = await db.insert('transactions', {
      ...transaction.toMap(),
      'user_id': _activeUserId,
    });
    return transaction.copyWith(id: id);
  }

  Future<void> updateTransaction(CapyTransaction transaction) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'UPDATE transactions '
          'SET title = :title, category = :category, note = :note, amount = :amount, type = :type, created_at = :createdAt, receipt_image_url = :receiptImageUrl '
          'WHERE id = :id AND user_id = :userId',
          {
            'id': transaction.id,
            'userId': _activeUserId,
            'title': transaction.title,
            'category': transaction.category,
            'note': transaction.note,
            'amount': transaction.amount,
            'type': transaction.type.name,
            'createdAt': _formatDateTimeForSql(transaction.createdAt),
            'receiptImageUrl': transaction.receiptImageUrl,
          },
        );
        return;
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [transaction.id, _activeUserId],
    );
  }

  Future<void> deleteTransaction(int id) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'UPDATE transactions SET deleted_at = NOW(3) WHERE id = :id AND user_id = :userId AND deleted_at IS NULL',
          {'id': id, 'userId': _activeUserId},
        );
        return;
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    await db.update(
      'transactions',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [id, _activeUserId],
    );
  }

  Future<List<CapyCategory>> fetchCategories() async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, name, icon_code, color_value FROM categories '
          'WHERE user_id = :userId AND deleted_at IS NULL '
          'ORDER BY name ASC',
          {'userId': _activeUserId},
        );
        return result.rows
            .map((row) => _categoryFromMySqlMap(row.assoc()))
            .toList();
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [_activeUserId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(CapyCategory.fromMap).toList();
  }

  Future<CapyCategory> insertCategory(CapyCategory category) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'INSERT INTO categories (user_id, name, icon_code, color_value) VALUES (:userId, :name, :iconCode, :colorValue)',
          {
            'userId': _activeUserId,
            'name': category.name,
            'iconCode': category.iconCodePoint,
            'colorValue': category.colorValue,
          },
        );
        final idResult = await connection.execute(
          'SELECT LAST_INSERT_ID() AS id',
        );
        final id = int.tryParse(idResult.rows.first.assoc()['id'] ?? '0');
        return category.copyWith(id: id == 0 ? null : id);
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final id = await db.insert('categories', {
      ...category.toMap(),
      'user_id': _activeUserId,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
    return category.copyWith(id: id);
  }

  Future<List<CapyGoal>> fetchGoals() async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        final result = await connection.execute(
          'SELECT id, name, target_amount, saved_amount, created_at FROM goals '
          'WHERE user_id = :userId AND deleted_at IS NULL '
          'ORDER BY created_at DESC',
          {'userId': _activeUserId},
        );
        return result.rows
            .map((row) => _goalFromMySqlMap(row.assoc()))
            .toList();
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final rows = await db.query(
      'goals',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [_activeUserId],
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(CapyGoal.fromMap).toList();
  }

  Future<CapyGoal> insertGoal(CapyGoal goal) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'INSERT INTO goals (user_id, name, target_amount, saved_amount, created_at) '
          'VALUES (:userId, :name, :targetAmount, :savedAmount, :createdAt)',
          {
            'userId': _activeUserId,
            'name': goal.name,
            'targetAmount': goal.targetAmount,
            'savedAmount': goal.savedAmount,
            'createdAt': _formatDateTimeForSql(goal.createdAt),
          },
        );
        final idResult = await connection.execute(
          'SELECT LAST_INSERT_ID() AS id',
        );
        final id = int.tryParse(idResult.rows.first.assoc()['id'] ?? '0');
        return goal.copyWith(id: id == 0 ? null : id);
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    final id = await db.insert('goals', {
      ...goal.toMap(),
      'user_id': _activeUserId,
    });
    return goal.copyWith(id: id);
  }

  Future<void> updateGoal(CapyGoal goal) async {
    if (_activeMySql) {
      try {
        final connection = await mysql;
        await connection.execute(
          'UPDATE goals SET name = :name, target_amount = :targetAmount, saved_amount = :savedAmount, created_at = :createdAt '
          'WHERE id = :id AND user_id = :userId',
          {
            'id': goal.id,
            'userId': _activeUserId,
            'name': goal.name,
            'targetAmount': goal.targetAmount,
            'savedAmount': goal.savedAmount,
            'createdAt': _formatDateTimeForSql(goal.createdAt),
          },
        );
        return;
      } catch (_) {
        _mysqlUnavailable = true;
      }
    }

    final db = await database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ? AND user_id = ? AND deleted_at IS NULL',
      whereArgs: [goal.id, _activeUserId],
    );
  }

  Future<CapyUser?> currentUser() {
    return fetchUserById(_activeUserId);
  }

  CapyTransaction _transactionFromMySqlMap(Map<String, String?> map) {
    return CapyTransaction(
      id: int.tryParse(map['id'] ?? ''),
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      note: map['note'] ?? '',
      amount: double.tryParse(map['amount'] ?? '0') ?? 0,
      type: transactionTypeFromName(map['type'] ?? 'expense'),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      receiptImageUrl: map['receipt_image_url'],
    );
  }

  CapyCategory _categoryFromMySqlMap(Map<String, String?> map) {
    return CapyCategory(
      id: int.tryParse(map['id'] ?? ''),
      name: map['name'] ?? 'Category',
      iconCodePoint:
          int.tryParse(map['icon_code'] ?? '') ?? Icons.category.codePoint,
      colorValue:
          int.tryParse(map['color_value'] ?? '') ??
          const Color(0xFFC38B55).toARGB32(),
    );
  }

  CapyGoal _goalFromMySqlMap(Map<String, String?> map) {
    return CapyGoal(
      id: int.tryParse(map['id'] ?? ''),
      name: map['name'] ?? 'First Pocket',
      targetAmount: double.tryParse(map['target_amount'] ?? '0') ?? 0,
      savedAmount: double.tryParse(map['saved_amount'] ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  CapyUser _userFromMySqlMap(Map<String, String?> map) {
    return CapyUser(
      id: int.tryParse(map['id'] ?? ''),
      username: map['username'] ?? 'mint.capy',
      passwordHash: map['password_hash'] ?? '',
      displayName: map['display_name'] ?? 'Mint Capy',
      monthlyIncome: double.tryParse(map['monthly_income'] ?? '0') ?? 0,
      cashBalance: double.tryParse(map['cash_balance'] ?? '0') ?? 0,
      pocketSaved: double.tryParse(map['pocket_saved'] ?? '0') ?? 0,
      savingsGoal: double.tryParse(map['savings_goal'] ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String _formatDateTimeForSql(DateTime value) {
    final iso = value.toIso8601String();
    return iso.length > 23 ? iso.substring(0, 23) : iso;
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String _envText(String key, String fallback) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      return fallback;
    }
    return value;
  }

  int _envInt(String key, String fallback) {
    final value = _envText(key, fallback);
    return int.tryParse(value) ?? int.tryParse(fallback) ?? 0;
  }

  bool _envBool(String key, String fallback) {
    final value = _envText(key, fallback).toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }
}

class CapyDatabaseHealth {
  const CapyDatabaseHealth({
    required this.mode,
    required this.connected,
    required this.detail,
    required this.checkedAt,
    required this.latencyMs,
  });

  final String mode;
  final bool connected;
  final String detail;
  final DateTime checkedAt;
  final int latencyMs;
}
