import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _authService = AuthService();
  final _vehicleService = VehicleService();

  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _capacityController = TextEditingController(text: "4");
  final _nequiController = TextEditingController();
  final _daviplataController = TextEditingController();

  String _vehicleType = "sedan";
  bool _loading = false;
  bool _loadingExisting = true;
  String? _error;
  String? _success;

  final Map<String, String> _typeLabels = {
    "sedan": "Automóvil",
    "camioneta": "Camioneta, vans, buses",
    "piaggio": "Piaggios, camiones, turbo",
    "moto": "Moto, Automóvil, Camioneta (domicilios)",
  };

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final vehicle = await _vehicleService.getMyVehicle(token);
    if (vehicle != null && mounted) {
      setState(() {
        _plateController.text = vehicle["plate"] ?? "";
        _brandController.text = vehicle["brand"] ?? "";
        _modelController.text = vehicle["model"] ?? "";
        _yearController.text = (vehicle["year"] ?? "").toString();
        _capacityController.text = (vehicle["capacity"] ?? 4).toString();
        _vehicleType = vehicle["vehicle_type"] ?? "sedan";
        _nequiController.text = vehicle["nequi_number"] ?? "";
        _daviplataController.text = vehicle["daviplata_number"] ?? "";
      });
    }
    setState(() => _loadingExisting = false);
  }

  Future<void> _save() async {
    if (_plateController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty ||
        _yearController.text.trim().isEmpty) {
      setState(() => _error = "Completa todos los campos obligatorios");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final token = await _authService.getToken();
    final error = await _vehicleService.registerVehicle(
      token: token!,
      plate: _plateController.text.trim().toUpperCase(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.tryParse(_yearController.text.trim()) ?? 0,
      capacity: int.tryParse(_capacityController.text.trim()) ?? 4,
      vehicleType: _vehicleType,
      nequiNumber: _nequiController.text.trim().isEmpty ? null : _nequiController.text.trim(),
      daviplataNumber: _daviplataController.text.trim().isEmpty ? null : _daviplataController.text.trim(),
    );

    setState(() {
      _loading = false;
      _error = error;
      _success = error == null ? "Vehículo guardado correctamente" : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return const Scaffold(
        backgroundColor: AppTheme.navyDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.yellow)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Mi vehículo", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Registra tu vehículo. El tipo determina qué servicios puedes atender.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _field(_plateController, "Placa"),
            const SizedBox(height: 12),
            _field(_brandController, "Marca (ej: Chevrolet)"),
            const SizedBox(height: 12),
            _field(_modelController, "Modelo (ej: Spark)"),
            const SizedBox(height: 12),
            _field(_yearController, "Año", type: TextInputType.number),
            const SizedBox(height: 12),
            _field(_capacityController, "Capacidad de pasajeros/carga", type: TextInputType.number),
            const SizedBox(height: 16),
            const Text("Tipo de vehículo", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            ..._typeLabels.entries.map((e) => RadioListTile<String>(
                  value: e.key,
                  groupValue: _vehicleType,
                  onChanged: (v) => setState(() => _vehicleType = v!),
                  title: Text(e.value, style: const TextStyle(color: Colors.white)),
                  activeColor: AppTheme.yellow,
                  dense: true,
                )),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text("Pagos digitales (opcional)", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Si los dejas vacíos, el pasajero solo verá la opción de pagar en efectivo.",
              style: TextStyle(color: AppTheme.textMutedOnDark, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _field(_nequiController, "Número de Nequi (opcional)", type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_daviplataController, "Número de Daviplata (opcional)", type: TextInputType.phone),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppTheme.dangerOnDark)),
            if (_success != null) Text(_success!, style: const TextStyle(color: AppTheme.successOnDark)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.yellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: AppTheme.navy)
                  : const Text("Guardar vehículo", style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMutedOnDark),
        filled: true,
        fillColor: AppTheme.navySurface,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF223B66))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.yellow, width: 2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
