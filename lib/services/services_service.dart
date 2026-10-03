import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ServicesService {
  Future<Map<String, dynamic>?> getMyServices(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/me/services"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }

  Future<void> setMyServices(String token, List<String> services) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/drivers/me/services")
        .replace(queryParameters: {"services": services.join(",")});
    final res = await http.post(uri, headers: {"Authorization": "Bearer $token"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudieron guardar los servicios");
    }
  }
}
