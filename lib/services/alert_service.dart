import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Muestra una notificacion local de alta importancia cuando llega una
/// solicitud al conductor: suena, vibra y aparece en pantalla (tambien con
/// la pantalla bloqueada). Nunca lanza errores hacia afuera: si algo falla,
/// la app sigue funcionando igual que antes, solo sin la notificacion.
class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  // Canal NUEVO a proposito: Android no deja cambiar el sonido/importancia
  // de un canal ya creado, por eso no se reutiliza el del servicio fijo.
  static const String _channelId = 'bipy_solicitudes';
  static const String _channelName = 'Solicitudes de viaje';
  static const String _channelDescription = 'Avisa con sonido cuando llega una solicitud de viaje o pedido.';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _counter = 0;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('AlertService.init fallo: $e');
    }
  }

  Future<void> notify({required String title, required String body}) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      // IDs rotativos para que dos solicitudes seguidas no se tapen entre si.
      final id = 1000 + (_counter++ % 50);
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
    } catch (e) {
      debugPrint('AlertService.notify fallo: $e');
    }
  }
}
