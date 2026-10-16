import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.navyDeep,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo real de Bipy sobre tarjeta blanca para que el azul
                // marino del logo se lea bien sobre el fondo oscuro.
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset("assets/images/logo_bipy.png", height: 84),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Muévete fácil, llega seguro",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMutedOnDark, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.yellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "CONDUCTOR",
                      style: TextStyle(color: AppTheme.navy, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Ingresa a tu cuenta",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                _buildField(_phoneController, "Número de teléfono", TextInputType.phone, Icons.phone_outlined),
                const SizedBox(height: 14),
                _buildField(_passwordController, "Contraseña", TextInputType.text, Icons.lock_outline, obscure: true),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.dangerOnDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.dangerOnDark, fontSize: 14))),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.navy))
                      : const Text("Ingresar"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text("¿No tienes cuenta? Regístrate como conductor"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, TextInputType type, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMutedOnDark),
        floatingLabelStyle: const TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: AppTheme.textMutedOnDark),
        filled: true,
        fillColor: AppTheme.navySurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF223B66))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.yellow, width: 2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
