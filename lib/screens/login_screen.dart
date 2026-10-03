import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await _authService.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NUEVO: logo real de Bipy, con tarjeta blanca detrás para
              // que el texto azul marino del logo resalte sobre el fondo
              // oscuro de la app.
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Image.asset("assets/images/logo_bipy.png", height: 90),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Muévete fácil, llega seguro",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              const Text(
                "CONDUCTOR",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 28),
              _buildField(_phoneController, "Número de teléfono", TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(_passwordController, "Contraseña", TextInputType.text, obscure: true),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Ingresar", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text("¿No tienes cuenta? Regístrate como conductor", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, TextInputType type, {bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
