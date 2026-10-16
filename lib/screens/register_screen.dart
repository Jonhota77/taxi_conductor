import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;
  bool _success = false;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await _authService.register(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    setState(() {
      _loading = false;
      _error = error;
      _success = error == null;
    });

    if (_success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Registro de conductor",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                "Después de crear tu cuenta, deberás subir tus documentos y esperar aprobación antes de poder aceptar viajes.",
                style: TextStyle(color: AppTheme.textMutedOnDark, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildField(_nameController, "Nombre completo", TextInputType.name, Icons.person_outline),
              const SizedBox(height: 14),
              _buildField(_phoneController, "Número de teléfono", TextInputType.phone, Icons.phone_outlined),
              const SizedBox(height: 14),
              _buildField(_passwordController, "Contraseña", TextInputType.text, Icons.lock_outline, obscure: true),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppTheme.dangerOnDark)),
              if (_success)
                const Text("¡Cuenta creada! Ya puedes iniciar sesión.", style: TextStyle(color: AppTheme.successOnDark)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.navy))
                    : const Text("Registrarme"),
              ),
            ],
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
