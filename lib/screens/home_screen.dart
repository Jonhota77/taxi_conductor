import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/tracking_service.dart';
import '../services/trip_service.dart';
import '../services/order_service.dart';
import '../services/map_theme.dart';
import '../services/wallet_service.dart';
import '../services/background_task_handler.dart';
import '../services/alert_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'documents_screen.dart';
import 'vehicle_screen.dart';
import 'stats_screen.dart';
import 'wallet_screen.dart';
import 'services_screen.dart';
import 'active_trip_screen.dart';
import 'active_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _trackingService = DriverTrackingService();
  final _tripService = TripService();
  final _orderService = OrderService();
  final _mapController = MapController();

  static const _defaultCenter = LatLng(0.8286, -77.6413); // Ipiales, Nariño

  final _walletService = WalletService();

  LatLng? _currentPosition;
  bool _isOnline = false;
  bool _connecting = false;
  String? _driverName;
  Map<String, dynamic>? _wallet;

  // NUEVO: ahora es una LISTA, no un solo elemento -- asi, si llega un taxi
  // y un domicilio casi al mismo tiempo, el conductor ve los dos y elige
  // cual tomar, en vez de que el segundo tape al primero.
  final List<Map<String, dynamic>> _incomingRequests = [];
  final Map<String, TextEditingController> _counterControllers = {};

  Map<String, dynamic>? _activeTrip;
  Map<String, dynamic>? _activeOrder;
  bool _checkingActive = true;

  // Esperando que el cliente decida sobre una contraoferta. "type" indica
  // si es de un viaje (trip) o un pedido (order).
  Map<String, dynamic>? _pendingConfirmation;
  String? _pendingConfirmationType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
    _checkActiveWork();
    _loadWallet();
    _checkLocationEnabled();
    _checkForAppUpdate();
    AlertService.instance.init();
  }

  /// Le recuerda al conductor activar el GPS del celular apenas abre la
  /// app -- fundamental para su trabajo.
  Future<void> _checkLocationEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.navySurface,
          title: const Text("Activa tu ubicacion", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Necesitas tener el GPS activado para poder conectarte y recibir carreras.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Ahora no", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text("Activar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  // Revisa si hay una version mas nueva de la app disponible y, si la
  // hay, le muestra al conductor el dialogo para descargarla e
  // instalarla. No bloquea el inicio de la app si falla (ej. sin
  // internet en ese momento) -- se intenta de nuevo la proxima vez que
  // se abra la app.
  Future<void> _checkForAppUpdate() async {
    final info = await UpdateService().checkForUpdate();
    if (info != null && mounted) {
      showUpdateDialog(context, info);
    }
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    setState(() => _driverName = name);
  }

  Future<void> _loadWallet() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final wallet = await _walletService.getMyWallet(token);
    if (mounted) setState(() => _wallet = wallet);
  }

  Future<void> _checkActiveWork() async {
    final token = await _authService.getToken();
    if (token == null) {
      setState(() => _checkingActive = false);
      return;
    }
    final trip = await _tripService.getMyActiveTrip(token);
    final order = await _orderService.getMyActiveOrder(token);
    setState(() {
      _activeTrip = trip;
      _activeOrder = order;
      _checkingActive = false;
    });
    _loadWallet();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = here);
      // initialCenter del mapa solo se usa al construirlo: hay que mover la
      // camara cuando llega el GPS real.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(here, 15);
      });
    } catch (_) {
      setState(() => _currentPosition = _defaultCenter);
    }
  }

  Future<void> _toggleOnline() async {
    if (_isOnline) {
      _trackingService.disconnect();
      if (!kIsWeb) await FlutterForegroundTask.stopService();
      setState(() => _isOnline = false);
      return;
    }

    setState(() => _connecting = true);

    if (!kIsWeb) {
      final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    }
    await Geolocator.requestPermission();

    final userId = await _authService.getUserId();
    final token = await _authService.getToken();
    if (userId == null || token == null) return;

    final channel = await _trackingService.connect(userId, token);
    channel.stream.listen(
      (raw) => _handleEvent(jsonDecode(raw)),
      onError: (_) => setState(() => _isOnline = false),
      onDone: () => setState(() => _isOnline = false),
    );

    if (!kIsWeb) {
      await FlutterForegroundTask.startService(
        notificationTitle: "Bipy Conductor conectado",
        notificationText: "Recibiendo viajes y enviando tu ubicacion...",
        callback: startBackgroundTaskCallback,
      );
    }

    setState(() {
      _isOnline = true;
      _connecting = false;
    });
  }

  /// Identificador unico de cada solicitud (trip_id u order_id), para poder
  /// tener varias en pantalla a la vez sin que se confundan entre si.
  String _requestId(Map<String, dynamic> req) {
    return req["event"] == "new_order_request" ? req["order_id"] : req["trip_id"];
  }

  void _handleEvent(Map<String, dynamic> data) {
    final event = data["event"];

    if (event == "new_trip_request" || event == "new_order_request") {
      // NUEVO: se agrega a la lista en vez de reemplazar la solicitud
      // anterior -- asi el conductor ve ambas si llegan casi juntas.
      _playAlertSound(
        title: event == "new_order_request" ? "Nuevo pedido" : "Nueva solicitud de viaje",
        body: "Abre la app para verla y responder.",
      );
      setState(() => _incomingRequests.add(data));
      return;
    }

    if (event == "order_confirmed" && _pendingConfirmationType == "order") {
      _goToConfirmedOrder(data["order_id"]);
      return;
    }
    if (event == "trip_confirmed" && _pendingConfirmationType == "trip") {
      _goToConfirmedTrip(data["trip_id"]);
      return;
    }
    if ((event == "order_price_rejected" && _pendingConfirmationType == "order") ||
        (event == "trip_price_rejected" && _pendingConfirmationType == "trip")) {
      setState(() {
        _pendingConfirmation = null;
        _pendingConfirmationType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El cliente no aceptó tu precio propuesto")),
      );
      return;
    }

    // Aviso enviado por la secretaría desde el panel de administración.
    if (event == "admin_broadcast") {
      _playAlertSound(title: "Aviso de Secretaría", body: (data["message"] ?? "").toString());
      _showAdminBroadcastDialog(data["message"] ?? "");
      return;
    }

    if (event == "wallet_updated") {
      setState(() {
        _wallet = {
          ...(_wallet ?? {}),
          "balance": data["balance"],
          "low_balance": data["low_balance"],
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("💰 Saldo actualizado: \$${(data["balance"] as num).toStringAsFixed(0)}")),
      );
      return;
    }
  }

  /// NUEVO: reproduce el sonido de notificacion/alarma que ya trae el
  /// celular -- no necesita ningun archivo de audio propio, y suena fuerte
  /// para que el conductor se de cuenta aunque este distraido.
  void _playAlertSound({String title = "Bipy Conductor", String body = "Tienes un aviso nuevo."}) {
    // SystemSoundType.alert no suena en Android, por eso se usa una notificacion
    // local de alta importancia (sonido + vibracion + aviso en pantalla).
    AlertService.instance.notify(title: title, body: body);
    HapticFeedback.heavyImpact();
  }

  void _showAdminBroadcastDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navySurface,
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.yellow),
            SizedBox(width: 10),
            Text("Aviso de Secretaría", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido", style: TextStyle(color: AppTheme.yellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _goToConfirmedOrder(String orderId) async {
    final token = await _authService.getToken();
    if (token == null) return;
    try {
      final order = await _orderService.getOrder(token, orderId);
      setState(() {
        _pendingConfirmation = null;
        _pendingConfirmationType = null;
      });
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActiveOrderScreen(order: order)),
      );
      _checkActiveWork();
    } catch (_) {
      setState(() {
        _pendingConfirmation = null;
        _pendingConfirmationType = null;
      });
    }
  }

  Future<void> _goToConfirmedTrip(String tripId) async {
    final token = await _authService.getToken();
    if (token == null) return;
    try {
      final trip = await _tripService.getTrip(token, tripId);
      setState(() {
        _pendingConfirmation = null;
        _pendingConfirmationType = null;
      });
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: trip)),
      );
      _checkActiveWork();
    } catch (_) {
      setState(() {
        _pendingConfirmation = null;
        _pendingConfirmationType = null;
      });
    }
  }

  bool _isOrderRequest(Map<String, dynamic> req) => req["event"] == "new_order_request";

  LatLng? _pickupPointFor(Map<String, dynamic> req) {
    final lat = _isOrderRequest(req) ? req["pickup_lat"] : req["origin_lat"];
    final lng = _isOrderRequest(req) ? req["pickup_lng"] : req["origin_lng"];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  TextEditingController _controllerFor(String id) {
    return _counterControllers.putIfAbsent(id, () => TextEditingController());
  }

  Future<void> _acceptRequest(Map<String, dynamic> req) async {
    final id = _requestId(req);
    final token = await _authService.getToken();
    final counterText = _controllerFor(id).text.trim();
    final counterPrice = counterText.isEmpty ? null : double.tryParse(counterText.replaceAll(RegExp(r'[^\d]'), ''));

    try {
      if (_isOrderRequest(req)) {
        final order = await _orderService.acceptOrder(token!, id, counterPrice: counterPrice);
        _removeRequest(id);

        if (order["status"] == "pending_confirmation") {
          setState(() {
            _pendingConfirmation = order;
            _pendingConfirmationType = "order";
          });
          return;
        }

        if (!mounted) return;
        setState(() => _incomingRequests.clear());
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActiveOrderScreen(order: order)),
        );
        _checkActiveWork();
      } else {
        final trip = await _tripService.acceptTrip(token!, id, counterPrice: counterPrice);
        _removeRequest(id);

        if (trip["status"] == "pending_confirmation") {
          setState(() {
            _pendingConfirmation = trip;
            _pendingConfirmationType = "trip";
          });
          return;
        }

        if (!mounted) return;
        setState(() => _incomingRequests.clear());
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: trip)),
        );
        _checkActiveWork();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
      _removeRequest(id);
    }
  }

  void _declineRequest(Map<String, dynamic> req) {
    _removeRequest(_requestId(req));
  }

  void _removeRequest(String id) {
    setState(() {
      _incomingRequests.removeWhere((r) => _requestId(r) == id);
    });
    _counterControllers.remove(id)?.dispose();
  }

  Future<void> _resumeActiveTrip() async {
    if (_activeTrip == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActiveTripScreen(trip: _activeTrip!)),
    );
    _checkActiveWork();
  }

  Future<void> _resumeActiveOrder() async {
    if (_activeOrder == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActiveOrderScreen(order: _activeOrder!)),
    );
    _checkActiveWork();
  }

  @override
  void dispose() {
    _trackingService.disconnect();
    for (final c in _counterControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasActiveWork => _activeTrip != null || _activeOrder != null;

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: MapTheme.isDark,
                builder: (context, isDark, _) {
                  final tileLayer = TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.jonhjota.taxi_conductor',
                  );
                  if (!isDark) return tileLayer;
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileLayer,
                  );
                },
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 34,
                      height: 50,
                      // Conectado: carro azul (encendido). Desconectado: gris (estacionado).
                      child: Image.asset(
                        _isOnline ? 'assets/marcadores/carro_encendido.png' : 'assets/marcadores/carro_estacionado.png',
                        width: 22,
                        height: 44,
                      ),
                    ),
                  // NUEVO: un punto naranja por cada solicitud pendiente
                  // (puede haber mas de una a la vez).
                  ..._incomingRequests.map((req) {
                    final point = _pickupPointFor(req);
                    if (point == null) return null;
                    return Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.yellow,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: AppTheme.navy, width: 3)),
                          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.person, color: AppTheme.navy, size: 24),
                      ),
                    );
                  }).whereType<Marker>(),
                ],
              ),
            ],
          ),
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shadowColor: Colors.black45,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                        _loadWallet();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _driverName != null ? "Hola, $_driverName" : "Cargando...",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (_wallet != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _wallet!["low_balance"] == true ? AppTheme.danger.withOpacity(0.15) : AppTheme.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "\$${(_wallet!["balance"] as num).toStringAsFixed(0)}",
                                  style: TextStyle(
                                    color: _wallet!["low_balance"] == true ? AppTheme.danger : AppTheme.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: AppTheme.floating,
                  child: IconButton(
                    icon: const Icon(Icons.description_outlined, color: AppTheme.navy),
                    tooltip: "Mis documentos",
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                    ),
                  ),
                ),
                Container(
                  decoration: AppTheme.floating,
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.directions_car, color: AppTheme.navy),
                    tooltip: "Mi vehículo",
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VehicleScreen()),
                    ),
                  ),
                ),
                Container(
                  decoration: AppTheme.floating,
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: AppTheme.navy),
                    tooltip: "Mis servicios",
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ServicesScreen()),
                    ),
                  ),
                ),
                Container(
                  decoration: AppTheme.floating,
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.bar_chart, color: AppTheme.navy),
                    tooltip: "Mis estadisticas",
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                  ),
                ),
                Container(
                  decoration: AppTheme.floating,
                  margin: const EdgeInsets.only(left: 8),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: MapTheme.isDark,
                    builder: (context, isDark, _) => IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.navy),
                      tooltip: isDark ? "Mapa claro" : "Mapa oscuro",
                      onPressed: MapTheme.toggle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_checkingActive && _activeTrip != null && _incomingRequests.isEmpty && _pendingConfirmation == null)
            Positioned(
              top: 108,
              left: 16,
              right: 16,
              child: _resumeBanner("Tienes un viaje en curso — toca para verlo/cancelarlo", _resumeActiveTrip),
            ),
          if (!_checkingActive && _activeOrder != null && _incomingRequests.isEmpty && _pendingConfirmation == null)
            Positioned(
              top: 108,
              left: 16,
              right: 16,
              child: _resumeBanner("Tienes un pedido en curso — toca para verlo/cancelarlo", _resumeActiveOrder),
            ),
          if (_pendingConfirmation != null) _buildWaitingForClientCard(),
          if (_incomingRequests.isNotEmpty) _buildIncomingRequestsList(),
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: (_connecting || _hasActiveWork) ? null : _toggleOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline ? AppTheme.danger : AppTheme.success,
                disabledBackgroundColor: AppTheme.navySurface,
                disabledForegroundColor: AppTheme.textMutedOnDark,
                minimumSize: const Size.fromHeight(60),
                elevation: 6,
              ),
              child: Text(
                _hasActiveWork
                    ? "Termina tu trabajo activo primero"
                    : (_connecting ? "Conectando..." : (_isOnline ? "Desconectarme" : "Conectarme (quedar disponible)")),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeBanner(String text, VoidCallback onTap) {
    return Material(
      color: AppTheme.yellow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.directions_car, color: AppTheme.navy),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13))),
              const Icon(Icons.chevron_right, color: AppTheme.navy),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingForClientCard() {
    final proposed = _pendingConfirmation!["proposed_price"];
    return Positioned(
      bottom: 110,
      left: 20,
      right: 20,
      child: Card(
        elevation: 8,
        color: AppTheme.navySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.yellow)),
                  SizedBox(width: 10),
                  Text("Esperando respuesta del cliente...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              if (proposed != null)
                Text("Le propusiste: \$${proposed.toString()} COP", style: const TextStyle(color: AppTheme.yellow)),
              const SizedBox(height: 4),
              const Text(
                "Si acepta, este viaje/pedido pasa a ser tuyo automáticamente.",
                style: TextStyle(color: AppTheme.textMutedOnDark, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// NUEVO: en vez de una sola tarjeta fija, ahora es una lista desplazable
  /// -- si llegan un taxi y un domicilio a la vez, aparecen las dos, y el
  /// conductor elige cual aceptar (la otra se le queda disponible para
  /// otro conductor si este no la toma).
  Widget _buildIncomingRequestsList() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Positioned(
      bottom: 110,
      left: 20,
      right: 20,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _incomingRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _buildIncomingRequestCard(_incomingRequests[index]),
        ),
      ),
    );
  }

  Widget _buildIncomingRequestCard(Map<String, dynamic> req) {
    final offeredPrice = req["requested_price"];
    final isOrder = _isOrderRequest(req);
    final id = _requestId(req);

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isOrder
                  ? "Nuevo pedido (${req["service_type"] == "piaggio" ? "Piaggio" : "Domicilio"})"
                  : (req["category"] == "intermunicipal"
                      ? "Nuevo viaje intermunicipal 🚐"
                      : "Nueva solicitud de viaje 🚕"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text("📍 El punto amarillo en el mapa es donde recoger",
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            if (isOrder) ...[
              if (req["item_description"] != null) Text("Descripción: ${req["item_description"]}"),
              if (req["pickup_address"] != null) Text("Recoger en: ${req["pickup_address"]}"),
              if (req["destination_address"] != null) Text("Entregar en: ${req["destination_address"]}"),
            ] else ...[
              if (req["origin_address"] != null) Text("Origen: ${req["origin_address"]}"),
              if (req["destination_address"] != null) Text("Destino: ${req["destination_address"]}"),
            ],
            const SizedBox(height: 8),
            if (offeredPrice != null)
              Text(
                "💰 El cliente ofrece: \$${offeredPrice.toString()} COP",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
              )
            else
              const Text("El cliente no propuso un precio", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: _controllerFor(id),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "¿No estás de acuerdo? Pon tu precio aquí",
                hintText: "Déjalo vacío para aceptar el precio ofrecido",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(req),
                    child: const Text("Rechazar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    onPressed: () => _acceptRequest(req),
                    child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
