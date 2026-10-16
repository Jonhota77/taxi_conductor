import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema visual de Bipy para la app del conductor. Mismos colores que la app
/// del pasajero (salen del logo: azul marino y amarillo) para que las dos se
/// vean como una sola marca.
///
/// La app del conductor es oscura (se usa de noche y manejando): el fondo es
/// azul marino profundo, las tarjetas son un azul algo mas claro y el amarillo
/// marca la accion principal. Verdes y rojos son solo para estados.
///
/// Todos los pares texto/fondo usados aqui superan 4.5:1 de contraste.
class AppTheme {
  AppTheme._();

  // Marca (tomados del logo)
  static const Color navy = Color(0xFF00204F);
  static const Color navyDeep = Color(0xFF081733); // fondo de pantallas
  static const Color navySurface = Color(0xFF10264A); // tarjetas y campos
  static const Color yellow = Color(0xFFFFBB02);

  // Neutros
  static const Color textMuted = Color(0xFF5B6678); // sobre fondo claro
  static const Color textMutedOnDark = Color(0xFF9FB0C8); // sobre fondo oscuro
  static const Color line = Color(0xFFDDE2EC);

  // Estados
  static const Color success = Color(0xFF157A45); // botones y texto sobre claro
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFC62F2F);
  static const Color dangerOnDark = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF2F6FED); // boton de llamar

  static const String fontFamily = 'Barlow';

  /// Decoracion de los botones flotantes sobre el mapa.
  static BoxDecoration get floating => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
      );

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: navy).copyWith(
      primary: navy,
      onPrimary: Colors.white,
      secondary: yellow,
      onSecondary: navy,
      surface: Colors.white,
      onSurface: const Color(0xFF0F1B2E),
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: navyDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: navy,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      // Casillas y radios sobre fondo oscuro: sin esto, las opciones sin
      // marcar quedan casi invisibles.
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: textMutedOnDark, width: 2),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? yellow : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(navy),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? yellow : textMutedOnDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, color: Color(0xFFD5DEEC)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: yellow),
    );
  }
}
