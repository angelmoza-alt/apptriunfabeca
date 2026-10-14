import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/reporte.dart';
import '../models/usuario.dart';

class ApiException implements Exception {
  final String mensaje;
  final int? codigo;
  ApiException(this.mensaje, [this.codigo]);
  @override
  String toString() => mensaje;
}

/// Única clase que habla con la API de Triunfa Beca (triunfa-beca-api).
/// Todas las respuestas vienen como { success, message, data }.
class ApiService {
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String ruta, [Map<String, String>? params]) =>
      Uri.parse('${ApiConfig.baseUrl}$ruta').replace(queryParameters: params);

  /// Envía la petición y devuelve el campo "data" (o lanza ApiException con "message")
  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    http.Response r;
    try {
      r = await peticion().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ApiException('El servidor no responde. ¿Está corriendo la API de Triunfa Beca?');
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. ¿Está corriendo la API de Triunfa Beca?');
    }
    dynamic cuerpo;
    try {
      cuerpo = r.body.isNotEmpty ? jsonDecode(utf8.decode(r.bodyBytes)) : null;
    } catch (_) {
      cuerpo = null;
    }
    final ok = r.statusCode >= 200 && r.statusCode < 300 && (cuerpo is! Map || cuerpo['success'] != false);
    if (ok) return cuerpo is Map ? cuerpo['data'] : cuerpo;

    String mensaje = 'Error ${r.statusCode}';
    if (cuerpo is Map) {
      if (cuerpo['message'] != null) {
        mensaje = cuerpo['message'].toString();
      } else if (cuerpo['errors'] is List && (cuerpo['errors'] as List).isNotEmpty) {
        mensaje = (cuerpo['errors'] as List).first['msg']?.toString() ?? mensaje;
      }
    }
    throw ApiException(mensaje, r.statusCode);
  }

  Future<dynamic> _get(String ruta, [Map<String, String>? p]) =>
      _enviar(() => http.get(_uri(ruta, p), headers: _headers));
  Future<dynamic> _post(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.post(_uri(ruta), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> _put(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.put(_uri(ruta), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> _patch(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.patch(_uri(ruta), headers: _headers, body: jsonEncode(body)));

  // ---------- Sistema ----------
  /// La API no tiene /health: usamos una ruta pública liviana para saber si responde.
  Future<bool> enLinea() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConfig.host}/api/v1/public/navegacion'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // ---------- Auth (mismo login que el panel admin) ----------
  Future<(Usuario, String)> login(String correo, String password) async {
    final d = await _post('/auth/login', {'correo': correo, 'password': password});
    return (Usuario.fromJson(Map<String, dynamic>.from(d['usuario'])), d['token'] as String);
  }

  Future<Usuario> yo() async => Usuario.fromJson(Map<String, dynamic>.from(await _get('/auth/me')));

  // ---------- Mi cuenta (cualquier usuario) ----------
  Future<Usuario> actualizarMiPerfil(Map<String, dynamic> cambios) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await _put('/usuarios/me', cambios)));

  Future<void> cambiarPassword(String actual, String nueva) =>
      _put('/usuarios/me/password', {'actual': actual, 'nueva': nueva});

  // ---------- Usuarios (solo ADMIN) ----------
  Future<List<Usuario>> usuarios({String? busqueda, String? role, bool? activo}) async {
    final p = <String, String>{
      if (busqueda != null && busqueda.isNotEmpty) 'q': busqueda,
      if (role != null) 'role': role,
      if (activo != null) 'activo': '$activo',
    };
    final d = await _get('/usuarios', p.isEmpty ? null : p);
    return (d as List).map((e) => Usuario.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Usuario> usuario(String id) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await _get('/usuarios/$id')));

  /// Crea el usuario en la tabla compartida: podrá entrar a Gestión y Respuestas Rápidas.
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String role,
  }) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await _post('/usuarios', {
        'nombre': nombre,
        'correo': correo,
        'password': password,
        'role': role,
      })));

  Future<Usuario> actualizarUsuario(String id, Map<String, dynamic> cambios) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await _put('/usuarios/$id', cambios)));

  Future<Usuario> cambiarEstado(String id, bool activo) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await _patch('/usuarios/$id/estado', {'es_activo': activo})));

  Future<void> restablecerPassword(String id, String nueva) => _put('/usuarios/$id/password', {'nueva': nueva});

  // ---------- Reportes (solo ADMIN) ----------
  Future<Reporte> reporte(DateTime desde, DateTime hasta) async {
    String f(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final d = await _get('/usuarios/resumen', {'desde': f(desde), 'hasta': f(hasta)});
    return Reporte.fromJson(Map<String, dynamic>.from(d));
  }
}
