import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';

/// Maneja la sesión con el mismo login del panel admin de Triunfa Beca.
/// La sesión se guarda en el celular para no pedir login cada vez.
class AuthProvider extends ChangeNotifier {
  final ApiService api;
  AuthProvider(this.api);

  static const _kToken = 'token';
  static const _kUsuario = 'usuario';

  Usuario? usuario;
  bool cargando = false;

  bool get haySesion => usuario != null;
  bool get esAdmin => usuario?.esAdmin ?? false;

  /// Se llama en el Splash. Devuelve true si había sesión guardada y válida.
  Future<bool> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final guardado = prefs.getString(_kUsuario);
    if (token == null || guardado == null) return false;

    api.token = token;
    try {
      usuario = Usuario.fromJson(jsonDecode(guardado));
    } catch (_) {
      await cerrarSesion();
      return false;
    }
    try {
      usuario = await api.yo(); // refresca datos (y valida que el token siga vigente)
      await _guardar(token);
    } on ApiException catch (e) {
      if (e.codigo == 401 || e.codigo == 404) {
        await cerrarSesion();
        return false;
      }
      // Sin conexión: se queda con los datos guardados
    }
    notifyListeners();
    return true;
  }

  Future<void> login(String correo, String password) async {
    _setCargando(true);
    try {
      final (u, token) = await api.login(correo, password);
      usuario = u;
      api.token = token;
      await _guardar(token);
    } finally {
      _setCargando(false);
    }
  }

  /// El administrador crea un usuario nuevo (no cambia la sesión actual).
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String role,
  }) =>
      api.crearUsuario(nombre: nombre, correo: correo, password: password, role: role);

  /// Edita mis propios datos (nombre y correo)
  Future<Usuario> actualizarMisDatos(Map<String, dynamic> cambios) async {
    final u = await api.actualizarMiPerfil(cambios);
    usuario = u;
    await _guardar(api.token!);
    notifyListeners();
    return u;
  }

  /// Si se editó al usuario logueado desde otra pantalla, refresca aquí.
  void reemplazarSiEsYo(Usuario u) {
    if (usuario?.id == u.id) {
      usuario = u;
      if (api.token != null) _guardar(api.token!);
      notifyListeners();
    }
  }

  Future<void> cambiarPassword(String actual, String nueva) => api.cambiarPassword(actual, nueva);

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUsuario);
    api.token = null;
    usuario = null;
    notifyListeners();
  }

  Future<void> _guardar(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUsuario, jsonEncode(usuario!.toJson()));
  }

  void _setCargando(bool v) {
    cargando = v;
    notifyListeners();
  }
}
