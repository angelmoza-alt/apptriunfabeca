import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Preferencias del usuario: tema, notificaciones e idioma.
/// Se guardan en el servidor (por usuario) y una copia local para que el
/// tema se aplique al instante al abrir la app.
class ConfigProvider extends ChangeNotifier {
  final ApiService api;
  ConfigProvider(this.api);

  bool notificaciones = true;
  String idioma = 'es';
  String tema = 'claro';

  ThemeMode get themeMode => tema == 'oscuro' ? ThemeMode.dark : ThemeMode.light;

  Future<void> cargarLocal() async {
    final p = await SharedPreferences.getInstance();
    tema = p.getString('tema') ?? 'claro';
    notificaciones = p.getBool('notificaciones') ?? true;
    idioma = p.getString('idioma') ?? 'es';
    notifyListeners();
  }

  Future<void> cargarDelServidor() async {
    try {
      _aplicar(await api.configuracion());
    } catch (_) {
      // Sin conexión: se mantiene lo local
    }
  }

  Future<void> cambiar({bool? notificaciones, String? idioma, String? tema}) async {
    // Cambio optimista: se ve al instante y luego se guarda
    _aplicar({
      'notificaciones': notificaciones ?? this.notificaciones,
      'idioma': idioma ?? this.idioma,
      'tema': tema ?? this.tema,
    });
    final cambios = <String, dynamic>{
      if (notificaciones != null) 'notificaciones': notificaciones,
      if (idioma != null) 'idioma': idioma,
      if (tema != null) 'tema': tema,
    };
    _aplicar(await api.guardarConfiguracion(cambios));
  }

  void _aplicar(Map<String, dynamic> c) {
    notificaciones = c['notificaciones'] ?? notificaciones;
    idioma = c['idioma'] ?? idioma;
    tema = c['tema'] ?? tema;
    SharedPreferences.getInstance().then((p) {
      p.setString('tema', tema);
      p.setBool('notificaciones', notificaciones);
      p.setString('idioma', idioma);
    });
    notifyListeners();
  }

  void reiniciar() {
    _aplicar({'notificaciones': true, 'idioma': 'es', 'tema': 'claro'});
  }
}
