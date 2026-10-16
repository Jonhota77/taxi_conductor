import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/services_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _authService = AuthService();
  final _servicesService = ServicesService();

  static const _labels = {
    "taxi": "Taxi",
    "delivery": "Domicilios",
    "intermunicipal": "Servicio especial",
    "piaggio": "Transporte de carga",
  };
  static const _descriptions = {
    "taxi": "Viajes de pasajero dentro de Ipiales",
    "delivery": "Domicilios y mandados",
    "intermunicipal": "Viajes a otras ciudades",
    "piaggio": "Carga, mudanzas, trasteos",
  };

  List<String> _allowed = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _vehicleType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final data = await _servicesService.getMyServices(token);
    if (mounted) {
      setState(() {
        if (data != null) {
          _allowed = List<String>.from(data["allowed_services"] ?? []);
          _selected.addAll(List<String>.from(data["enabled_services"] ?? []));
          _vehicleType = data["vehicle_type"];
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      setState(() => _error = "Selecciona al menos un servicio");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final token = await _authService.getToken();
      await _servicesService.setMyServices(token!, _selected.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Servicios actualizados")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Mis servicios", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_allowed.isEmpty)
                    const Text(
                      "Aun no tienes un vehiculo registrado, o no se pudo determinar su tipo. Registra tu vehiculo primero.",
                      style: TextStyle(color: Colors.white70),
                    )
                  else ...[
                    const Text(
                      "Puedes activar varios a la vez -- por ejemplo, Taxi y Domicilios juntos, para que nunca te falte trabajo. Cuando llegue una solicitud de cualquiera de tus servicios activos, te avisamos, y tu decides cual tomar.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ..._allowed.map((service) => _serviceTile(service)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.dangerOnDark, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  if (_allowed.isNotEmpty)
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.yellow,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: AppTheme.navy)
                          : const Text("Guardar", style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _serviceTile(String service) {
    final selected = _selected.contains(service);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppTheme.yellow.withOpacity(0.12) : AppTheme.navySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppTheme.yellow : Colors.transparent),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _selected.add(service);
            } else {
              _selected.remove(service);
            }
          });
        },
        activeColor: AppTheme.yellow,
        checkColor: AppTheme.navy,
        title: Text(_labels[service] ?? service, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(_descriptions[service] ?? "", style: const TextStyle(color: AppTheme.textMutedOnDark, fontSize: 12)),
      ),
    );
  }
}
