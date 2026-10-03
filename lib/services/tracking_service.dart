import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class DriverTrackingService {
  WebSocketChannel? _channel;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionSub;

  /// Abre el WebSocket del conductor y empieza a enviar ubicación cada 4 segundos.
  /// El backend exige el token como query param (ver auditoría: WebSockets ahora
  /// verifican identidad).
  Future<WebSocketChannel> connect(String driverId, String token) async {
    final uri = Uri.parse("${AppConfig.wsBaseUrl}/ws/driver/$driverId?token=$token");
    _channel = WebSocketChannel.connect(uri);

    // Enviar ubicación periódicamente mientras esté "en línea"
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        _channel?.sink.add(jsonEncode({"lat": pos.latitude, "lng": pos.longitude}));
      } catch (_) {
        // Si falla obtener ubicación (ej. sin GPS en escritorio), no rompe la app
      }
    });

    return _channel!;
  }

  void disconnect() {
    _locationTimer?.cancel();
    _positionSub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
