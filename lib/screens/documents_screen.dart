import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _authService = AuthService();
  final _documentService = DocumentService();
  final _picker = ImagePicker();

  final Map<String, String> _docLabels = {
    "license": "Licencia de conducción",
    "soat": "SOAT",
    "tecnomecanica": "Tecnomecánica",
    "photo_id": "Foto de cédula",
  };

  final Set<String> _uploading = {};
  final Set<String> _uploaded = {};

  Future<void> _pickAndUpload(String docType) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading.add(docType));

    final token = await _authService.getToken();
    final error = await _documentService.uploadDocument(
      token: token!,
      docType: docType,
      file: File(picked.path),
    );

    setState(() {
      _uploading.remove(docType);
      if (error == null) _uploaded.add(docType);
    });

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${_docLabels[docType]} subido correctamente")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Documentos", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Sube estos 4 documentos. Un administrador revisará y aprobará tu cuenta antes de que puedas aceptar viajes.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ..._docLabels.entries.map((entry) {
              final docType = entry.key;
              final label = entry.value;
              final isUploading = _uploading.contains(docType);
              final isDone = _uploaded.contains(docType);

              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(label, style: const TextStyle(color: Colors.white)),
                  trailing: isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                      : isDone
                          ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                          : IconButton(
                              icon: const Icon(Icons.upload_file, color: Colors.amber),
                              onPressed: () => _pickAndUpload(docType),
                            ),
                  onTap: isUploading ? null : () => _pickAndUpload(docType),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
