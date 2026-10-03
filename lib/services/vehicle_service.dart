import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class VehicleService {
  Future<String?> registerVehicle({
    required String token,
    required String plate,
    required String brand,
    required String model,
    required int year,
    required int capacity,
    required String vehicleType,
    String? nequiNumber,
    String? daviplataNumber,
  }) async {
    final res = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/vehicle"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "plate": plate,
        "brand": brand,
        "model": model,
        "year": year,
        "capacity": capacity,
        "vehicle_type": vehicleType,
        "nequi_number": nequiNumber,
        "daviplata_number": daviplataNumber,
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      return body["detail"]?.toString() ?? "No se pudo registrar el vehículo";
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMyVehicle(String token) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}/drivers/vehicle/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
