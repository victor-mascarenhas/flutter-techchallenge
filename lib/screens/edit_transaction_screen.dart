import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import './file_viewer_screen.dart';

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
  TransactionType _selectedType = TransactionType.deposit;
  PlatformFile? _pickedFile;
  UploadTask? _uploadTask;
  String? _uploadedFileUrl;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text =
          widget.transaction!.amount.abs().toString(); // Use valor absoluto
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
    }
  }

  void _viewAttachedFile() async {
    if (widget.transaction?.fileUrl != null &&
        widget.transaction!.fileUrl!.isNotEmpty) {
      _navigateToFileViewer(
        widget.transaction!.fileUrl!,
        widget.transaction!.fileName ?? 'arquivo',
      );
      return;
    }

    if (_uploadedFileUrl != null && _uploadedFileUrl!.isNotEmpty) {
      _navigateToFileViewer(_uploadedFileUrl!, _pickedFile!.name);
      return;
    }

    if (_uploadTask != null) {
      if (_uploadTask!.snapshot.state == TaskState.success) {
        final url = await _uploadTask!.snapshot.ref.getDownloadURL();
        _uploadedFileUrl = url;
        _navigateToFileViewer(url, _pickedFile!.name);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aguarde o upload do arquivo ser concluído')),
        );
      }
      return;
    }

    if (_pickedFile == null) {
      _pickFile();
    }
  }

  void _navigateToFileViewer(String url, String fileName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FileViewerScreen(fileUrl: url, fileName: fileName),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() => _pickedFile = result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar arquivo: $e')));
    }
  }

  Future<String?> _uploadFile() async {
    if (_pickedFile == null || _pickedFile!.path == null) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storage = FirebaseStorage.instance;
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser!.uid;

      final safeFileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          _pickedFile!.name.replaceAll(' ', '_');

      final ref = storage.ref().child('user_files/$userId/$safeFileName');

      final file = File(_pickedFile!.path!);
      _uploadTask = ref.putFile(file);

      _uploadTask!.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await _uploadTask!;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedFileUrl = downloadUrl;
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer upload do arquivo: $e')),
      );
      return null;
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

  void _changeType(TransactionType type) {
    setState(() {
      _selectedType = type;
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Por favor, selecione uma data')));
      return;
    }

    // Pega o valor absoluto do campo e ajusta conforme o tipo
    double absAmount = double.parse(_amountController.text);
    double finalAmount =
        _selectedType == TransactionType.deposit
            ? absAmount
            : -absAmount; // Valor negativo para transferência

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Salvando'),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Salvando transação...'),
              ],
            ),
          ),
    );

    try {
      String? fileUrl;
      String? fileName;

      if (widget.transaction?.fileUrl != null && _pickedFile == null) {
        fileUrl = widget.transaction!.fileUrl;
        fileName = widget.transaction!.fileName;
      } else if (_pickedFile != null) {
        fileUrl = await _uploadFile();
        fileName = _pickedFile!.name;
      }

      final transaction = TransactionModel(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: finalAmount, // Usa o valor ajustado conforme o tipo
        date: _selectedDate!,
        fileUrl: fileUrl,
        fileName: fileName,
        userId:
            Provider.of<AuthProvider>(context, listen: false).currentUser!.uid,
        type: _selectedType,
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (widget.transaction == null) {
        await provider.addTransaction(transaction);
      } else {
        await provider.editTransaction(transaction);
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  IconData _getFileIcon() {
    final fileName = _pickedFile?.name ?? widget.transaction?.fileName ?? '';
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Transação' : 'Nova Transação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  validator:
                      (value) => value!.isEmpty ? 'Insira um título' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return 'Insira um valor';
                    if (double.tryParse(value) == null) return 'Valor inválido';
                    if (double.parse(value) <= 0)
                      return 'Valor deve ser positivo';
                    return null;
                  },
                ),
                SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('Tipo:', style: TextStyle(fontSize: 14)),
                        ),
                        RadioListTile<TransactionType>(
                          title: Text(
                            'Depósito',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: TransactionType.deposit,
                          groupValue: _selectedType,
                          dense: true,
                          onChanged: (value) => _changeType(value!),
                        ),
                        RadioListTile<TransactionType>(
                          title: Text(
                            'Transferência',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: TransactionType.transfer,
                          groupValue: _selectedType,
                          dense: true,
                          onChanged: (value) => _changeType(value!),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, size: 20),
                      title: Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yy').format(_selectedDate!)
                            : 'Selecione a data',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: _selectDate,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_getFileIcon(), size: 20),
                      title: Text(
                        _pickedFile?.name ??
                            widget.transaction?.fileName ??
                            'Nenhum arquivo',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_pickedFile != null ||
                              widget.transaction?.fileUrl != null)
                            IconButton(
                              icon: Icon(Icons.visibility, size: 20),
                              onPressed: _viewAttachedFile,
                            ),
                          IconButton(
                            icon: Icon(Icons.attach_file, size: 20),
                            onPressed: _pickFile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveForm,
                    child: Text('Salvar', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 40),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
