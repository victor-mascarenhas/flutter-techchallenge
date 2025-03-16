import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const EditTransactionScreen({super.key, this.transaction});

  @override
  _EditTransactionScreenState createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedDate = widget.transaction!.date;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    final transaction = TransactionModel(
      id: widget.transaction?.id,
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate!,
      userId:
          Provider.of<AuthProvider>(context, listen: false).currentUser!.uid,
    );

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    if (widget.transaction == null) {
      await provider.addTransaction(transaction);
    } else {
      await provider.editTransaction(transaction);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nova Transação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Título'),
                validator:
                    (value) => value!.isEmpty ? 'Insira um título' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value!.isEmpty ? 'Insira um valor' : null,
              ),
              Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? 'Nenhuma data selecionada'
                        : 'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  ),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text('Selecionar Data'),
                  ),
                ],
              ),
              ElevatedButton(onPressed: _saveForm, child: Text('Salvar')),
            ],
          ),
        ),
      ),
    );
  }
}
