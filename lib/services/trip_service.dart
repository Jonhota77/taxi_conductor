import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class TripService {
  Future<Map<String, dynamic>> acceptTrip(String token, String tripId, {double? counterPrice}) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/trips/$tripId/accept").replace(
      queryParameters: counterPrice != null ? {"counter_price": counterPrice.toString()} : null,
    );
    final res = await http.post(uri, headers: {"Authorization": "Bearer $token"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo aceptar el viaje");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> startTrip(String token, String tripId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/trips/$tripId/start"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo iniciar el viaje");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> completeTrip(String token, String tripId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/trips/$tripId/complete"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo completar el viaje");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> cancelTrip(String token, String tripId) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/trips/$tripId/cancel"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "No se pudo cancelar el viaje");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getTrip(String token, String tripId) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/trips/$tripId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("No se pudo consultar el viaje");
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>?> getMyActiveTrip(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/trips/active/mine"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
