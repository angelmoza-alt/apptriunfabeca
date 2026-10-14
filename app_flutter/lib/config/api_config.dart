import 'package:flutter/foundation.dart';

/// Dirección de la API de Triunfa Beca (repo triunfa-beca-api).
/// Es la MISMA API que usan las páginas de Gestión y Respuestas Rápidas,
/// así que los usuarios creados en la app sirven para iniciar sesión en ellas.
///
/// - Celular por USB: deja ipManual = '127.0.0.1' y ejecuta
///   `adb reverse tcp:3000 tcp:3000` (también funciona en el emulador).
/// - Emulador sin adb reverse: ipManual = null (usa 10.0.2.2).
/// - Chrome / Windows: ipManual = null (usa localhost).
/// - Celular por WiFi: pon la IP de tu PC, ej. '192.168.1.20'.
class ApiConfig {
  /// true = datos de ejemplo, sin API (para revisar el diseño).
  /// false = conecta con triunfa-beca-api.
  static const bool modoDemo = true;

  static const String? ipManual = '127.0.0.1';
  static const int puerto = 3000;

  static String get host {
    if (ipManual != null) return 'http://$ipManual:$puerto';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$puerto';
    }
    return 'http://localhost:$puerto';
  }

  /// Rutas de administración: /auth, /usuarios
  static String get baseUrl => '$host/api/v1/admin';
}
