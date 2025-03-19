import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'edit_transaction_screen.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _titleFilterController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    transactionProvider.loadTransactions();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !transactionProvider.isLoading &&
          transactionProvider.hasMore) {
        transactionProvider.loadTransactions(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleFilterController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? _startDate ?? DateTime.now()
              : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    transactionProvider.setFilters(
      titleFilter: _titleFilterController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );

    transactionProvider.loadTransactions();
  }

  void _clearFilters() {
    setState(() {
      _titleFilterController.clear();
      _startDate = null;
      _endDate = null;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    transactionProvider.clearFilters();
    transactionProvider.loadTransactions();
  }

  Widget _buildFilterPanel() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isFilterExpanded ? 200 : 0,
      child: Card(
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleFilterController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Inicial',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : 'Selecione',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Final',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : 'Selecione',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _clearFilters, child: Text('LIMPAR')),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text('APLICAR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    int index,
    List transactions,
  ) {
    final transaction = transactions[index];
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        title: Text(
          transaction.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(transaction.formattedDate),
        trailing: Text(
          'R\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.green, fontSize: 16),
        ),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (ctx) => EditTransactionScreen(transaction: transaction),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (ctx, transactionProvider, _) {
        final transactions = transactionProvider.transactions;
        return Scaffold(
          appBar: AppBar(
            title: Text('Transações'),
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  setState(() {
                    _isFilterExpanded = !_isFilterExpanded;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed:
                    () =>
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).signOut(),
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
          body: Column(
            children: [
              _buildFilterPanel(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    transactionProvider.update(transactionProvider.userId);
                  },
                  child:
                      transactions.isEmpty
                          ? Center(
                            child: Text(
                              transactionProvider.isLoading
                                  ? 'Carregando...'
                                  : 'Nenhuma transação encontrada',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                          : ListView.builder(
                            controller: _scrollController,
                            itemCount: transactions.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i < transactions.length) {
                                return _buildTransactionItem(
                                  context,
                                  i,
                                  transactions,
                                );
                              } else {
                                return transactionProvider.hasMore
                                    ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                    : SizedBox.shrink();
                              }
                            },
                          ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
