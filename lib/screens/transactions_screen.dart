import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
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
  TransactionType? _typeFilter;
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
      typeFilter: _typeFilter,
    );

    transactionProvider.loadTransactions();
  }

  void _clearFilters() {
    setState(() {
      _titleFilterController.clear();
      _startDate = null;
      _endDate = null;
      _typeFilter = null;
    });

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    transactionProvider.clearFilters();
    transactionProvider.loadTransactions();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleFilterController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _startDate != null
                              ? DateFormat('dd/MM/yy').format(_startDate!)
                              : 'Início',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _selectDate(context, true),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _endDate != null
                              ? DateFormat('dd/MM/yy').format(_endDate!)
                              : 'Fim',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<TransactionType?>(
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  value: _typeFilter,
                  items: [
                    DropdownMenuItem<TransactionType?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<TransactionType?>(
                      value: TransactionType.transfer,
                      child: Text('Transferência'),
                    ),
                    DropdownMenuItem<TransactionType?>(
                      value: TransactionType.deposit,
                      child: Text('Depósito'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _typeFilter = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: Text('Limpar', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton(
                      child: Text('Aplicar', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(minimumSize: Size(0, 30)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    int index,
    List transactions,
  ) {
    final transaction = transactions[index];
    final bool isDeposit = transaction.type == TransactionType.deposit;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => EditTransactionScreen(transaction: transaction),
            ),
          );
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDeposit ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.add : Icons.remove,
            size: 18,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          transaction.formattedDate,
          style: TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'R\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: isDeposit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Chip(
              label: Text(
                transaction.typeDisplay,
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: isDeposit ? Colors.green : Colors.red,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
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
                onPressed: _showFilterModal,
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
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[200],
                child:
                    transactions.isNotEmpty
                        ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  'Transferências',
                                  transactions
                                      .where(
                                        (t) =>
                                            t.type == TransactionType.transfer,
                                      )
                                      .length
                                      .toString(),
                                  Colors.red,
                                ),
                                _buildSummaryItem(
                                  'Depósitos',
                                  transactions
                                      .where(
                                        (t) =>
                                            t.type == TransactionType.deposit,
                                      )
                                      .length
                                      .toString(),
                                  Colors.green,
                                ),
                                _buildSummaryItem(
                                  'Total',
                                  'R\$${transactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                                  Colors.blue,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        )
                        : SizedBox.shrink(),
              ),
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

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: compact ? 10 : 12, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
