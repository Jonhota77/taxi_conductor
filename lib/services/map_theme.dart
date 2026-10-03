import 'package:flutter/foundation.dart';

/// Controla si los mapas de la app se ven en modo claro u oscuro.
///
/// No depende de ningun proveedor de mapas externo -- invierte los colores
/// del mismo mapa que ya usamos (OpenStreetMap), el mismo truco que usan
/// muchas apps para simular un mapa oscuro sin depender de otro servidor
/// (evita el problema de "API key required" que tuvo CartoDB).
class MapTheme {
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static void toggle() {
    isDark.value = !isDark.value;
  }
}
