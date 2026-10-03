import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/map_theme.dart';

class ActiveOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const ActiveOrderScreen({super.key, required this.order});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  final _authService = AuthService();
  final _orderService = OrderService();
  late String _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order["status"] ?? "accepted";
  }

  LatLng? get _pickupPoint {
    final lat = widget.order["pickup_lat"];
    final lng = widget.order["pickup_lng"];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  LatLng? get _destinationPoint {
    final lat = widget.order["destination_lat"];
    final lng = widget.order["destination_lng"];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  String? get _customerPhone => widget.order["customer_phone"];

  /// NUEVO: abre el marcador de llamadas del celular con el numero del
  /// cliente, para poder coordinar la recogida/entrega.
  Future<void> _callCustomer() async {
    if (_customerPhone == null) return;
    final uri = Uri(scheme: 'tel', path: _customerPhone!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el marcador de llamadas")),
      );
    }
  }

  Future<void> _markPickedUp() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      await _orderService.markPickedUp(token!, widget.order["id"]);
      setState(() => _status = "picked_up");
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      await _orderService.completeOrder(token!, widget.order["id"]);
      setState(() => _status = "completed");
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _loading = true);
    final token = await _authService.getToken();
    try {
      await _orderService.cancelOrder(token!, widget.order["id"]);
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
    final pickup = _pickupPoint;
    final destination = _destinationPoint;
    final hasBothPoints = pickup != null && destination != null;
    final serviceType = widget.order["service_type"] ?? "piaggio";
    final serviceLabel = serviceType == "piaggio" ? "Piaggio (carga)" : "Domicilio";
    final price = widget.order["price"];

    final CameraFit cameraFit = hasBothPoints
        ? CameraFit.bounds(bounds: LatLngBounds(pickup, destination), padding: const EdgeInsets.all(40))
        : CameraFit.coordinates(coordinates: [pickup ?? const LatLng(0.8286, -77.6413)], padding: const EdgeInsets.all(40), maxZoom: 15);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      body: SafeArea(
        child: Column(
          children: [
            if (pickup != null)
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    FlutterMap(
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
                          Marker(point: pickup, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 34)),
                          if (destination != null)
                            Marker(point: destination, width: 36, height: 36, child: const Icon(Icons.location_on, color: Colors.red, size: 32)),
                        ]),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: MapTheme.isDark,
                        builder: (context, isDark, _) => Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18, color: const Color(0xFF0F1B2B)),
                            tooltip: isDark ? "Mapa claro" : "Mapa oscuro",
                            onPressed: MapTheme.toggle,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (pickup != null)
              Container(
                width: double.infinity,
                color: Colors.blue.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  "📍 Azul = recoger aqui   🔴 Rojo = entregar aqui",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(_status == "picked_up" ? Icons.navigation : Icons.local_shipping, color: Colors.amber, size: 32),
                        const SizedBox(width: 10),
                        Text(serviceLabel, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_labelFor(_status), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    // NUEVO: boton de llamada al cliente, visible mientras
                    // el pedido esta activo.
                    if ((_status == "accepted" || _status == "picked_up") && _customerPhone != null) ...[
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _callCustomer,
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text("Llamar al cliente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _infoCard(),
                    const SizedBox(height: 20),
                    if (_status == "accepted") ...[
                      ElevatedButton(
                        onPressed: _loading ? null : _markPickedUp,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Ya recogi el pedido", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loading ? null : _cancel,
                        child: const Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                    if (_status == "picked_up")
                      ElevatedButton(
                        onPressed: _loading ? null : _complete,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Marcar como entregado", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    if (_status == "completed") ...[
                      if (price != null)
                        Center(
                          child: Text("Total: \$${price.toString()} COP",
                              style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        child: const Text("Volver al mapa", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final o = widget.order;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (o["item_description"] != null) _row("Descripcion", o["item_description"]),
          if (o["pickup_address"] != null) _row("Recoger en", o["pickup_address"]),
          if (o["destination_address"] != null) _row("Entregar en", o["destination_address"]),
          if (o["recipient_name"] != null) _row("Destinatario", o["recipient_name"]),
          if (o["recipient_phone"] != null) _row("Telefono", o["recipient_phone"]),
          if (o["notes"] != null && o["notes"].toString().isNotEmpty) _row("Notas", o["notes"]),
          if (o["price"] != null) _row("Precio acordado", "\$${o["price"]} COP"),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.white),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(color: Colors.white54)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _labelFor(String status) {
    switch (status) {
      case "accepted":
        return "Dirigete al punto de recogida";
      case "picked_up":
        return "En camino a la entrega";
      case "completed":
        return "Pedido completado";
      default:
        return status;
    }
  }
}
