import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String? fileUrl;
  final String? fileName;
  String? id;
  final String title;
  final double amount;
  final DateTime date;
  final String userId;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.userId,
    this.fileUrl,
    this.fileName,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return TransactionModel(
      id: doc.id,
      title: data['title'],
      amount: data['amount'],
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
}
