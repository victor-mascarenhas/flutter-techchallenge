import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transações'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed:
                () =>
                    Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => EditTransactionScreen()),
            ),
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder:
            (ctx, i) => ListTile(
              title: Text(transactions[i].title),
              subtitle: Text(transactions[i].formattedDate),
              trailing: Text('R\$${transactions[i].amount.toStringAsFixed(2)}'),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (ctx) => EditTransactionScreen(
                            transaction: transactions[i],
                          ),
                    ),
                  ),
            ),
      ),
    );
  }
}
