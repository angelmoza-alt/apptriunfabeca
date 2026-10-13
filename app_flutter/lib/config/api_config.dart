import 'package:flutter/foundation.dart';

/// Dirección del backend (Docker).
/// - Emulador Android: 10.0.2.2 apunta a tu PC.
/// - Web / Windows / iOS simulator: localhost.
/// - Celular físico: cambia [ipManual] por la IP de tu PC (ej. 192.168.1.20)
///   y asegúrate de estar en la misma red WiFi.
class ApiConfig {
  static const String? ipManual = '127.0.0.1'; // celular por USB (adb reverse). Emulador o Chrome: null
  static const int puerto = 3000;

  static String get baseUrl {
    if (ipManual != null) return 'http://$ipManual:$puerto/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$puerto/api';
    }
    return 'http://localhost:$puerto/api';
  }
}
