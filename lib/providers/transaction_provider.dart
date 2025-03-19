import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TransactionModel> _transactions = [];
  String? _userId;

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  final int _limit = 10;

  String? _titleFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  List<TransactionModel> get transactions => _transactions;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  String? get userId => _userId;

  void update(String? userId) {
    _userId = userId;
    _lastDocument = null;
    _hasMore = true;
    clearFilters();
    loadTransactions();
  }

  void setFilters({
    String? titleFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _titleFilter =
        titleFilter != null && titleFilter.isNotEmpty ? titleFilter : null;
    _startDate = startDate;
    _endDate = endDate;

    _lastDocument = null;
    _hasMore = true;

    notifyListeners();
  }

  void clearFilters() {
    _titleFilter = null;
    _startDate = null;
    _endDate = null;

    _lastDocument = null;
    _hasMore = true;

    notifyListeners();
  }

  Future<void> loadTransactions({bool loadMore = false}) async {
    if (_userId == null || _isLoading || (!_hasMore && loadMore)) return;

    _isLoading = true;
    notifyListeners();

    Query query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true);

    if (_startDate != null) {
      final startTimestamp = Timestamp.fromDate(
        DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
      );
      query = query.where('date', isGreaterThanOrEqualTo: startTimestamp);
    }

    if (_endDate != null) {
      final endTimestamp = Timestamp.fromDate(
        DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59),
      );
      query = query.where('date', isLessThanOrEqualTo: endTimestamp);
    }

    query = query.limit(_limit);

    if (loadMore && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;

      var newTransactions =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();

      if (_titleFilter != null && _titleFilter!.isNotEmpty) {
        final lowerCaseFilter = _titleFilter!.toLowerCase();
        newTransactions =
            newTransactions
                .where(
                  (transaction) =>
                      transaction.title.toLowerCase().contains(lowerCaseFilter),
                )
                .toList();
      }

      if (loadMore) {
        _transactions.addAll(newTransactions);
      } else {
        _transactions = newTransactions;
      }

      if (newTransactions.length < _limit) {
        _hasMore = false;
      }
    } else {
      if (!loadMore) {
        _transactions = [];
      }
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _firestore.collection('transactions').add(transaction.toMap());
    _lastDocument = null;
    _hasMore = true;
    loadTransactions();
  }

  Future<void> editTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
    _lastDocument = null;
    _hasMore = true;
    loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
    _lastDocument = null;
    _hasMore = true;
    loadTransactions();
  }
}
