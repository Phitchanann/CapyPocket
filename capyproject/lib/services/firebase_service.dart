import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/capy_models.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<CapyUser?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return null;
    return _loadUserProfile(cred.user!.uid);
  }

  Future<CapyUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final name = displayName.isEmpty ? email.split('@').first : displayName;
    final now = DateTime.now();

    await _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': name,
      'monthlyIncome': 0.0,
      'savingsGoal': 0.0,
      'createdAt': Timestamp.fromDate(now),
    });

    await _seedDefaultCategories(uid);

    return CapyUser(
      id: uid,
      email: email,
      displayName: name,
      monthlyIncome: 0,
      savingsGoal: 0,
      createdAt: now,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<CapyUser?> currentUser() async {
    final fireUser = _auth.currentUser;
    if (fireUser == null) return null;
    return _loadUserProfile(fireUser.uid);
  }

  Future<CapyUser?> _loadUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    final ts = data['createdAt'];
    return CapyUser(
      id: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      monthlyIncome: (data['monthlyIncome'] as num?)?.toDouble() ?? 0,
      savingsGoal: (data['savingsGoal'] as num?)?.toDouble() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<List<CapyTransaction>> fetchTransactions(String uid) async {
    final snap = await _db
        .collection('users/$uid/transactions')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => _txFromDoc(d.id, d.data())).toList();
  }

  Future<CapyTransaction> insertTransaction(
    String uid,
    CapyTransaction tx,
  ) async {
    final ref = await _db
        .collection('users/$uid/transactions')
        .add(_txToMap(tx));
    return tx.copyWith(id: ref.id);
  }

  Future<void> updateTransaction(String uid, CapyTransaction tx) async {
    if (tx.id == null) return;
    await _db
        .collection('users/$uid/transactions')
        .doc(tx.id)
        .update(_txToMap(tx));
  }

  Future<void> deleteTransaction(String uid, String txId) async {
    await _db.collection('users/$uid/transactions').doc(txId).delete();
  }

  Map<String, dynamic> _txToMap(CapyTransaction tx) => {
    'title': tx.title,
    'amount': tx.amount,
    'category': tx.category,
    'type': tx.type.name,
    'note': tx.note,
    'receiptImageUrl': tx.receiptImageUrl,
    'createdAt': Timestamp.fromDate(tx.createdAt),
  };

  CapyTransaction _txFromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return CapyTransaction(
      id: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      category: data['category'] as String? ?? 'General',
      type: transactionTypeFromName(data['type'] as String? ?? 'expense'),
      note: data['note'] as String? ?? '',
      receiptImageUrl: data['receiptImageUrl'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Future<List<CapyCategory>> fetchCategories(String uid) async {
    final snap = await _db.collection('users/$uid/categories').get();
    return snap.docs.map((d) => _catFromDoc(d.id, d.data())).toList();
  }

  Future<CapyCategory> insertCategory(String uid, CapyCategory cat) async {
    final ref = await _db.collection('users/$uid/categories').add({
      'name': cat.name,
      'iconCode': cat.iconCodePoint,
      'colorValue': cat.colorValue,
    });
    return cat.copyWith(id: ref.id);
  }

  CapyCategory _catFromDoc(String id, Map<String, dynamic> data) {
    return CapyCategory(
      id: id,
      name: data['name'] as String? ?? 'Category',
      iconCodePoint: data['iconCode'] as int? ?? 0xe59c,
      colorValue: data['colorValue'] as int? ?? 0xFFC38B55,
    );
  }

  // ─── Goals ────────────────────────────────────────────────────────────────

  Future<List<CapyGoal>> fetchGoals(String uid) async {
    final snap = await _db.collection('users/$uid/goals').get();
    return snap.docs.map((d) => _goalFromDoc(d.id, d.data())).toList();
  }

  Future<CapyGoal> insertGoal(String uid, CapyGoal goal) async {
    final ref = await _db
        .collection('users/$uid/goals')
        .add(_goalToMap(goal));
    return goal.copyWith(id: ref.id);
  }

  Future<void> updateGoal(String uid, CapyGoal goal) async {
    if (goal.id == null) return;
    await _db
        .collection('users/$uid/goals')
        .doc(goal.id)
        .update(_goalToMap(goal));
  }

  Map<String, dynamic> _goalToMap(CapyGoal goal) => {
    'name': goal.name,
    'targetAmount': goal.targetAmount,
    'savedAmount': goal.savedAmount,
    'createdAt': Timestamp.fromDate(goal.createdAt),
  };

  CapyGoal _goalFromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return CapyGoal(
      id: id,
      name: data['name'] as String? ?? 'Goal',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  // ─── Storage ──────────────────────────────────────────────────────────────

  Future<String> uploadReceipt(String uid, String localPath) async {
    final file = File(localPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('receipts/$uid/$timestamp.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Web-safe upload: accepts raw bytes instead of a file path.
  Future<String> uploadReceiptBytes(String uid, Uint8List bytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('receipts/$uid/$timestamp.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  // ─── Seed defaults ────────────────────────────────────────────────────────

  Future<void> _seedDefaultCategories(String uid) async {
    const defaults = [
      {'name': 'Food', 'iconCode': 0xe25a, 'colorValue': 0xFFC38B55},
      {'name': 'Transport', 'iconCode': 0xe531, 'colorValue': 0xFF7ABFCF},
      {'name': 'Shopping', 'iconCode': 0xe59c, 'colorValue': 0xFFE67D7D},
      {'name': 'Health', 'iconCode': 0xe3f3, 'colorValue': 0xFF6BBF8F},
      {'name': 'Entertainment', 'iconCode': 0xe40d, 'colorValue': 0xFFB087D4},
      {'name': 'Salary', 'iconCode': 0xe227, 'colorValue': 0xFF5DA65D},
      {'name': 'Pocket', 'iconCode': 0xe586, 'colorValue': 0xFF5AA5C8},
    ];
    final batch = _db.batch();
    for (final data in defaults) {
      batch.set(_db.collection('users/$uid/categories').doc(), data);
    }
    await batch.commit();
  }
}
