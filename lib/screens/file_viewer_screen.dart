import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class FileViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const FileViewerScreen({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  _FileViewerScreenState createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool _isLoading = true;
  File? _localFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${widget.fileName}';
      final filePath = '${dir.path}/$fileName';

      final fileUrl = widget.fileUrl.trim();
      if (fileUrl.isEmpty) {
        throw Exception('URL de arquivo inválida');
      }

      final response = await http
          .get(Uri.parse(fileUrl))
          .timeout(const Duration(seconds: 30));

      final file = File(filePath);

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localFile = file;
          _isLoading = false;
        });
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      setState(() {
        _errorMessage = 'Tempo limite excedido para download do arquivo';
        _isLoading = false;
      });
    } on SocketException catch (_) {
      setState(() {
        _errorMessage =
            'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao baixar arquivo: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildFileViewer() {
    if (_localFile == null) return Container();

    final fileExtension =
        path.extension(widget.fileName).replaceAll('.', '').toLowerCase();

    switch (fileExtension) {
      case 'pdf':
        return PDFView(
          filePath: _localFile!.path,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: true,
          onError:
              (error) => setState(
                () => _errorMessage = 'Erro ao carregar PDF: $error',
              ),
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
        return PhotoView(
          imageProvider: FileImage(_localFile!),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: BoxDecoration(color: Colors.black),
          errorBuilder:
              (_, __, ___) => Center(child: Text('Erro ao carregar imagem')),
        );
      default:
        return Center(child: Text('Formato não suportado: $fileExtension'));
    }
  }

  Future<void> _shareFile() async {
    if (_localFile != null) {
      await Share.shareXFiles([
        XFile(_localFile!.path),
      ], subject: 'Compartilhar ${widget.fileName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _localFile != null ? _shareFile : null,
            tooltip: 'Compartilhar arquivo',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _downloadFile,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : (_errorMessage != null
                  ? ErrorWidgetSection(
                    errorMessage: _errorMessage!,
                    onRetry: _downloadFile,
                  )
                  : _buildFileViewer()),
    );
  }
}

class ErrorWidgetSection extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorWidgetSection({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh),
            label: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
