import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la app (tema, notificaciones, idioma).
/// Se guardan en el celular: la API de Triunfa Beca no maneja preferencias.
class ConfigProvider extends ChangeNotifier {
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

  Future<void> cambiar({bool? notificaciones, String? idioma, String? tema}) async {
    if (notificaciones != null) this.notificaciones = notificaciones;
    if (idioma != null) this.idioma = idioma;
    if (tema != null) this.tema = tema;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('tema', this.tema);
    await p.setBool('notificaciones', this.notificaciones);
    await p.setString('idioma', this.idioma);
  }
}
