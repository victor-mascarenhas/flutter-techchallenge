import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TransactionModel> _transactions = [];
  String? _userId;

  List<TransactionModel> get transactions => _transactions;

  void update(String? userId) {
    _userId = userId;
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_userId == null) return;

    final snapshot =
        await _firestore
            .collection('transactions')
            .where('userId', isEqualTo: _userId)
            .get();

    _transactions =
        snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toMap());
    loadTransactions();
  }

  Future<void> editTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
    loadTransactions();
  }
}
