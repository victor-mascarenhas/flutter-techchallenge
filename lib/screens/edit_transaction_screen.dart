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
      _amountController.text = widget.transaction!.amount.toString();
      _selectedDate = widget.transaction!.date;
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
        amount: double.parse(_amountController.text),
        date: _selectedDate!,
        fileUrl: fileUrl,
        fileName: fileName,
        userId:
            Provider.of<AuthProvider>(context, listen: false).currentUser!.uid,
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
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? 'Insira um título' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty) return 'Insira um valor';
                    if (double.tryParse(value) == null) return 'Valor inválido';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data da transação',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text(
                              _selectedDate == null
                                  ? 'Nenhuma data selecionada'
                                  : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate!),
                            ),
                            Spacer(),
                            TextButton.icon(
                              onPressed: _selectDate,
                              icon: Icon(Icons.date_range),
                              label: Text('Selecionar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprovante',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap:
                              _pickedFile != null ||
                                      widget.transaction?.fileUrl != null ||
                                      _uploadedFileUrl != null
                                  ? _viewAttachedFile
                                  : _pickFile,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _pickedFile != null ||
                                          widget.transaction?.fileUrl != null ||
                                          _uploadedFileUrl != null
                                      ? _getFileIcon()
                                      : Icons.attach_file,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pickedFile?.name ??
                                            widget.transaction?.fileName ??
                                            'Nenhum arquivo selecionado',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_pickedFile != null)
                                        Text(
                                          '${(_pickedFile!.size / 1024).toStringAsFixed(2)} KB',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed: _pickFile,
                                  tooltip: 'Alterar arquivo',
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isUploading)
                          Column(
                            children: [
                              SizedBox(height: 12),
                              LinearProgressIndicator(value: _uploadProgress),
                              SizedBox(height: 4),
                              Text(
                                'Enviando arquivo: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _saveForm,
                  icon: Icon(Icons.save),
                  label: Text('Salvar Transação'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
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
