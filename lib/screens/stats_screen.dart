import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _authService = AuthService();
  final _statsService = StatsService();

  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final stats = await _statsService.getMyStats(token);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Mis estadisticas", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          "${(_stats?["rating_avg"] as num?)?.toStringAsFixed(1) ?? "5.0"}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text(" / 5.0", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _periodCard("Hoy", _stats?["today"]),
                  const SizedBox(height: 14),
                  _periodCard("Esta semana", _stats?["this_week"]),
                  const SizedBox(height: 14),
                  _periodCard("Desde siempre", _stats?["all_time"]),
                ],
              ),
            ),
    );
  }

  Widget _periodCard(String label, Map<String, dynamic>? data) {
    final trips = data?["trips"] ?? 0;
    final orders = data?["orders"] ?? 0;
    final earnings = (data?["earnings"] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(Icons.local_taxi, "$trips", "Viajes"),
              _statItem(Icons.local_shipping, "$orders", "Pedidos"),
              _statItem(Icons.payments, "\$${earnings.toStringAsFixed(0)}", "Cobrado"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
