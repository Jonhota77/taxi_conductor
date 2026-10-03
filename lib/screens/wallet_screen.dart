import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _authService = AuthService();
  final _walletService = WalletService();

  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final wallet = await _walletService.getMyWallet(token);
    final txs = await _walletService.getMyTransactions(token);
    if (mounted) {
      setState(() {
        _wallet = wallet;
        _transactions = txs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1B2B),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final balance = (_wallet?["balance"] as num?)?.toDouble() ?? 0;
    final fee = (_wallet?["urban_trip_fee"] as num?)?.toDouble() ?? 1500;
    final lowBalance = _wallet?["low_balance"] == true;
    final nequi = _wallet?["company_nequi_number"];
    final daviplata = _wallet?["company_daviplata_number"];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Mi saldo", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lowBalance ? Colors.red.withOpacity(0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: lowBalance ? Border.all(color: Colors.redAccent) : null,
              ),
              child: Column(
                children: [
                  const Text("Saldo disponible", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    "\$${balance.toStringAsFixed(0)} COP",
                    style: TextStyle(
                      color: lowBalance ? Colors.redAccent : Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cada carrera de taxi urbano descuenta \$${fee.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  if (lowBalance) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "⚠️ Saldo insuficiente. No podras aceptar carreras de taxi hasta recargar.",
                      style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Como recargar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text(
                    "Transfiere a cualquiera de estas cuentas de la empresa, y muestrale el comprobante a la secretaria para que se refleje en tu saldo.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  if (nequi != null && nequi.toString().isNotEmpty) _accountRow("Nequi", nequi.toString(), Colors.pinkAccent),
                  if (daviplata != null && daviplata.toString().isNotEmpty) _accountRow("Daviplata", daviplata.toString(), Colors.redAccent),
                  if ((nequi == null || nequi.toString().isEmpty) && (daviplata == null || daviplata.toString().isEmpty))
                    const Text(
                      "La empresa aun no ha configurado sus cuentas de recarga. Contacta a la secretaria.",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // NUEVO: montos sugeridos, para que el conductor sepa cuanto
            // recargar segun cuantas carreras quiere tener cubiertas.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Montos sugeridos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _suggestedRow(fee * 10, 10),
                  _suggestedRow(fee * 20, 20),
                  _suggestedRow(fee * 40, 40),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Movimientos recientes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("Aun no hay movimientos.", style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ..._transactions.map((t) {
              final isRecharge = t["type"] == "recharge";
              final amount = (t["amount"] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isRecharge ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: isRecharge ? Colors.greenAccent : Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isRecharge ? "Recarga" : "Carrera de taxi",
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    Text(
                      "${amount >= 0 ? '+' : ''}\$${amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: isRecharge ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _suggestedRow(double amount, int trips) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("\$${amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
          Text("alcanza para $trips carreras", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _accountRow(String method, String number, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text("$method: ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(number, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
