import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // NUEVO: flutter_foreground_task usa dart:isolate, que no existe cuando
  // la app corre en el navegador (web) -- por eso solo se inicializa en
  // Android/iOS real. En web, la app sigue funcionando normal, solo sin
  // el servicio en segundo plano (que ahi tampoco tendria sentido).
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
    _initForegroundTask();
  }
  runApp(const TaxiConductorApp());
}

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'bipy_conductor_channel',
      channelName: 'Bipy Conductor activo',
      channelDescription: 'Mantiene la app recibiendo viajes aunque la pantalla este bloqueada.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(60000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

class TaxiConductorApp extends StatelessWidget {
  const TaxiConductorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bipy Conductor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const _StartupGate(),
    );
  }
}

/// Decide si mostrar el mapa (si ya hay sesion guardada y valida) o el
/// login. NUEVO: ademas de revisar esto al abrir la app, ahora tambien
/// observa el ciclo de vida de la app (WidgetsBindingObserver) y
/// revalida la sesion contra el servidor cada vez que la app vuelve de
/// segundo plano -- si el token ya vencio, detiene el servicio en
/// segundo plano (si estaba activo) y manda al conductor de vuelta al
/// login, en vez de dejar que falle a medias al intentar conectarse.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSessionOnResume();
    }
  }

  /// Revision inicial al abrir la app: si hay un token guardado,
  /// confirma que siga siendo valido antes de dejar entrar directo al
  /// mapa.
  Future<void> _check() async {
    final loggedIn = await _authService.isLoggedIn();
    bool valid = loggedIn;
    if (loggedIn) {
      valid = await _authService.validateToken();
      if (!valid) {
        await _authService.logout();
      }
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = valid;
      _checking = false;
    });
  }

  /// Revalidacion cuando la app vuelve de segundo plano. Si el conductor
  /// ya esta en el login, no hay nada que revisar. Si estaba autenticado
  /// y el token ya no es valido, detenemos el servicio en segundo plano
  /// (si estaba corriendo) y lo regresamos al login limpiando cualquier
  /// pantalla en la que estuviera navegando.
  Future<void> _validateSessionOnResume() async {
    if (!_loggedIn) return;

    final valid = await _authService.validateToken();
    if (!valid) {
      if (!kIsWeb) {
        await FlutterForegroundTask.stopService();
      }
      await _authService.logout();
      if (!mounted) return;

      setState(() {
        _loggedIn = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión expiró. Inicia sesión de nuevo.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppTheme.navyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.yellow)),
      );
    }
    return _loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
