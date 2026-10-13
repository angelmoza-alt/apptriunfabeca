import 'package:flutter/material.dart';

/// Paleta tomada del logo de Triunfa Beca (azul + rojo).
class AppColors {
  static const azul = Color(0xFF1446B8);
  static const azulOscuro = Color(0xFF0A2A78);
  static const azulClaro = Color(0xFFE8EFFF);
  static const rojo = Color(0xFFD7141A);
  static const rojoClaro = Color(0xFFFDE8E8);
  static const verde = Color(0xFF22A45D);
  static const verdeClaro = Color(0xFFE6F6EC);
  static const naranja = Color(0xFFF29A12);
  static const naranjaClaro = Color(0xFFFFF4DE);
  static const morado = Color(0xFF7B3FE4);
  static const moradoClaro = Color(0xFFF0E8FD);
  static const gris = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData _base(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      brightness: brillo,
      primary: oscuro ? const Color(0xFF8FB0FF) : AppColors.azul,
      secondary: AppColors.rojo,
      surface: oscuro ? const Color(0xFF17213F) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: oscuro ? const Color(0xFF0F1630) : const Color(0xFFF6F8FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulOscuro,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oscuro ? const Color(0xFF1B2547) : const Color(0xFFF1F4FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: oscuro ? const Color(0xFF2A3663) : const Color(0xFFE0E6F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: esquema.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData get claro => _base(Brightness.light);
  static ThemeData get oscuro => _base(Brightness.dark);
}
