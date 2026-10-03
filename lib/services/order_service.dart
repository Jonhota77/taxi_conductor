import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class OrderService {
  Future<Map<String, dynamic>> acceptOrder(String token, String orderId, {double? counterPrice}) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/orders/$orderId/accept").replace(
      queryParameters: counterPrice != null ? {"counter_price": counterPrice.toString()} : null,
    );
    final res = await http.post(uri, headers: {"Authorization": "Bearer $token"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo aceptar el pedido");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> markPickedUp(String token, String orderId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/orders/$orderId/picked-up"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo actualizar el pedido");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> completeOrder(String token, String orderId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/orders/$orderId/complete"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo completar el pedido");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> cancelOrder(String token, String orderId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/orders/$orderId/cancel"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo cancelar el pedido");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getOrder(String token, String orderId) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/orders/$orderId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("No se pudo consultar el pedido");
    }
    return jsonDecode(res.body);
  }

  /// NUEVO: recupera el pedido activo del conductor si existe.
  Future<Map<String, dynamic>?> getMyActiveOrder(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/orders/active/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
