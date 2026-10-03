import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// NUEVO: este archivo existe solo porque flutter_foreground_task EXIGE un
/// "manejador" para poder arrancar el servicio -- pero a propósito no
/// duplicamos aquí la lógica de enviar ubicación/websocket (eso ya lo hace
/// tracking_service.dart en el isolate principal). Este manejador no hace
/// nada por sí mismo: su único trabajo es que exista, para que Android
/// mantenga viva la notificación fija y no mate el proceso de la app.
class BipyBackgroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

@pragma('vm:entry-point')
void startBackgroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(BipyBackgroundTaskHandler());
}
