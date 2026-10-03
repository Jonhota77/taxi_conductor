import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class DocumentService {
  /// Sube un documento del conductor (license, soat, tecnomecanica, photo_id).
  /// Necesario para que un admin lo verifique (ver backend: CRIT-3 de la auditoría).
  Future<String?> uploadDocument({
    required String token,
    required String docType,
    required File file,
  }) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/drivers/documents");
    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["doc_type"] = docType
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      return body["detail"]?.toString() ?? "Error al subir el documento";
    }
    return null; // éxito
  }

  Future<List<dynamic>> myDocuments(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/me/documents"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body);
  }
}
