import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class StatsService {
  Future<Map<String, dynamic>?> getMyStats(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/me/stats"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
