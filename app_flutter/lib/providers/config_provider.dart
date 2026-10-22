import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la app (equivale a AppSettings de la versión Swift):
/// tema, notificaciones, idioma, nombre de la sede y logo de la academia.
/// Todo se guarda en el celular. El logo se copia a la carpeta de documentos
/// de la app (path_provider) y su ruta se guarda en shared_preferences, así
/// se actualiza al instante en el menú lateral, el login y el registro.
class ConfigProvider extends ChangeNotifier {
  bool notificaciones = true;
  String idioma = 'es';
  String tema = 'claro';
  String sede = 'Sede principal';
  String? logoPath; // null = logo por defecto (assets)

  ThemeMode get themeMode => tema == 'oscuro' ? ThemeMode.dark : ThemeMode.light;
  bool get tieneLogoPersonalizado => logoPath != null;

  Future<void> cargarLocal() async {
    final p = await SharedPreferences.getInstance();
    tema = p.getString('tema') ?? 'claro';
    notificaciones = p.getBool('notificaciones') ?? true;
    idioma = p.getString('idioma') ?? 'es';
    sede = p.getString('sede') ?? 'Sede principal';
    final ruta = p.getString('logoPath');
    // Si el archivo ya no existe (app reinstalada), vuelve al logo por defecto
    logoPath = (ruta != null && !kIsWeb && File(ruta).existsSync()) ? ruta : null;
    notifyListeners();
  }

  Future<void> cambiar({bool? notificaciones, String? idioma, String? tema, String? sede}) async {
    if (notificaciones != null) this.notificaciones = notificaciones;
    if (idioma != null) this.idioma = idioma;
    if (tema != null) this.tema = tema;
    if (sede != null && sede.trim().isNotEmpty) this.sede = sede.trim();
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('tema', this.tema);
    await p.setBool('notificaciones', this.notificaciones);
    await p.setString('idioma', this.idioma);
    await p.setString('sede', this.sede);
  }

  /// Abre la galería, guarda la imagen elegida en el almacenamiento interno
  /// y la usa como logo. Devuelve false si el usuario canceló.
  Future<bool> elegirLogo() async {
    if (kIsWeb) throw Exception('Cambiar el logo solo está disponible en el celular');
    final imagen = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 90);
    if (imagen == null) return false;

    final carpeta = await getApplicationDocumentsDirectory();
    final extension = imagen.path.contains('.') ? imagen.path.split('.').last : 'png';
    // Nombre nuevo cada vez para que Flutter no muestre la imagen anterior en caché
    final destino = '${carpeta.path}/logo_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await File(imagen.path).copy(destino);

    await _borrarLogoAnterior();
    logoPath = destino;
    final p = await SharedPreferences.getInstance();
    await p.setString('logoPath', destino);
    notifyListeners();
    return true;
  }

  /// Vuelve al logo original de Triunfa Beca
  Future<void> restablecerLogo() async {
    await _borrarLogoAnterior();
    logoPath = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('logoPath');
    notifyListeners();
  }

  Future<void> _borrarLogoAnterior() async {
    if (logoPath == null || kIsWeb) return;
    try {
      final f = File(logoPath!);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
