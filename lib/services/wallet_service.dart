import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class WalletService {
  Future<Map<String, dynamic>?> getMyWallet(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/wallet/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getMyTransactions(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/wallet/me/transactions"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body);
  }
}
