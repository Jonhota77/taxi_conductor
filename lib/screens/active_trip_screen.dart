import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../services/map_theme.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final _authService = AuthService();
  final _tripService = TripService();
  late String _status;
  bool _loading = false;
  double? _finalPrice;

  // NUEVO: controla si el panel de abajo esta desplegado o solo la franja
  // pequena -- para dejarle todo el espacio posible al mapa.
  bool _panelExpanded = false;

  @override
  void initState() {
    super.initState();
    _status = widget.trip["status"] ?? "accepted";
  }

  LatLng? get _originPoint {
    final lat = widget.trip["origin_lat"];
    final lng = widget.trip["origin_lng"];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  LatLng? get _destinationPoint {
    final lat = widget.trip["destination_lat"];
    final lng = widget.trip["destination_lng"];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  String? get _passengerPhone => widget.trip["passenger_phone"];

  /// Abre el marcador de llamadas del celular con el numero del pasajero.
  Future<void> _callPassenger() async {
    if (_passengerPhone == null) return;
    final uri = Uri(scheme: 'tel', path: _passengerPhone!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el marcador de llamadas")),
      );
    }
  }

  Future<void> _startTrip() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      await _tripService.startTrip(token!, widget.trip["id"]);
      setState(() => _status = "in_progress");
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _completeTrip() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      final result = await _tripService.completeTrip(token!, widget.trip["id"]);
      setState(() {
        _status = "completed";
        _finalPrice = (result["final_price"] as num?)?.toDouble();
        _panelExpanded = true; // al terminar, se muestra todo (calificacion/precio)
      });
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelTrip() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      await _tripService.cancelTrip(token!, widget.trip["id"]);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = _originPoint;
    final destination = _destinationPoint;
    final hasMap = origin != null;
    final hasBothPoints = origin != null && destination != null;
    final screenHeight = MediaQuery.of(context).size.height;

    final CameraFit cameraFit = hasBothPoints
        ? CameraFit.bounds(
            bounds: LatLngBounds(origin, destination),
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
          )
        : CameraFit.coordinates(
            coordinates: [origin ?? const LatLng(0.8286, -77.6413)],
            padding: const EdgeInsets.all(40),
            maxZoom: 15,
          );

    // Cuando el viaje ya termino, el panel se queda desplegado siempre
    // (para poder ver el total y calificar), sin importar el toque.
    final forceExpanded = _status == "completed";
    final isExpanded = _panelExpanded || forceExpanded;

    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      body: Stack(
        children: [
          // El mapa ocupa TODA la pantalla de fondo (~80%+ visible, ya que
          // el panel de abajo por defecto es solo una franja pequena).
          if (hasMap)
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(initialCameraFit: cameraFit),
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
                  MarkerLayer(markers: [
                    if (origin != null)
                      Marker(
                        point: origin,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.person_pin_circle, color: AppTheme.navy, size: 40),
                      ),
                    if (destination != null)
                      Marker(
                        point: destination,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: AppTheme.danger, size: 40),
                      ),
                  ]),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppTheme.yellow)),

          // Botón de modo oscuro del mapa, flotando arriba a la izquierda.
          if (hasMap)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: ValueListenableBuilder<bool>(
                  valueListenable: MapTheme.isDark,
                  builder: (context, isDark, _) => Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20, color: AppTheme.navyDeep),
                      tooltip: isDark ? "Mapa claro" : "Mapa oscuro",
                      onPressed: MapTheme.toggle,
                    ),
                  ),
                ),
              ),
            ),

          // Leyenda del mapa, flotando arriba (antes iba fija debajo del mapa).
          if (hasMap)
            Positioned(
              top: 16,
              left: 64,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: const Text(
                    "📍 Azul = recoger  🔴 Rojo = destino",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.navyDeep, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // Panel inferior: franja pequena por defecto, se despliega al tocarlo.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: isExpanded ? screenHeight * 0.42 : 100,
              decoration: const BoxDecoration(
                color: AppTheme.navyDeep,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
              ),
              child: Column(
                children: [
                  // Barra/manija: tocarla despliega o recoge el panel.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: forceExpanded ? null : () => setState(() => _panelExpanded = !_panelExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_iconFor(_status), color: AppTheme.yellow, size: 20),
                              const SizedBox(width: 8),
                              Text(_labelFor(_status), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              if (!forceExpanded) ...[
                                const SizedBox(width: 6),
                                Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: AppTheme.textMutedOnDark, size: 20),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          children: [
                            if ((_status == "accepted" || _status == "in_progress") && _passengerPhone != null) ...[
                              ElevatedButton.icon(
                                onPressed: _callPassenger,
                                icon: const Icon(Icons.call, color: Colors.white),
                                label: const Text("Llamar al pasajero", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.info,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_status == "accepted") ...[
                              ElevatedButton(
                                onPressed: _loading ? null : _startTrip,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, minimumSize: const Size.fromHeight(48)),
                                child: const Text("Iniciar viaje", style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _loading ? null : _cancelTrip,
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                child: const Text("Cancelar viaje", style: TextStyle(color: AppTheme.dangerOnDark)),
                              ),
                            ],
                            if (_status == "in_progress")
                              ElevatedButton(
                                onPressed: _loading ? null : _completeTrip,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, minimumSize: const Size.fromHeight(48)),
                                child: const Text("Completar viaje", style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
                              ),
                            if (_status == "completed") ...[
                              if (_finalPrice != null)
                                Text("Total cobrado: \$${_finalPrice!.toStringAsFixed(0)} COP",
                                    style: const TextStyle(color: AppTheme.yellow, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, minimumSize: const Size.fromHeight(48)),
                                child: const Text("Volver al mapa", style: TextStyle(color: AppTheme.navy)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case "in_progress":
        return Icons.navigation;
      case "completed":
        return Icons.check_circle;
      default:
        return Icons.directions_car;
    }
  }

  String _labelFor(String status) {
    switch (status) {
      case "accepted":
        return "Viaje aceptado";
      case "in_progress":
        return "Viaje en curso";
      case "completed":
        return "Viaje completado";
      default:
        return status;
    }
  }
}
