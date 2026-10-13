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

/// Única clase que habla con el backend. Cuando conecten con la web,
/// solo cambian aquí la URL o los endpoints; las pantallas no se tocan.
class ApiService {
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String ruta, [Map<String, String>? params]) =>
      Uri.parse('${ApiConfig.baseUrl}$ruta').replace(queryParameters: params);

  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    http.Response r;
    try {
      r = await peticion().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ApiException('El servidor no responde. ¿Está corriendo Docker?');
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. ¿Está corriendo Docker?');
    }
    final cuerpo = r.body.isNotEmpty ? jsonDecode(utf8.decode(r.bodyBytes)) : null;
    if (r.statusCode >= 200 && r.statusCode < 300) return cuerpo;
    final mensaje = (cuerpo is Map && cuerpo['mensaje'] != null) ? cuerpo['mensaje'] : 'Error ${r.statusCode}';
    throw ApiException(mensaje, r.statusCode);
  }

  Future<dynamic> _get(String ruta, [Map<String, String>? p]) =>
      _enviar(() => http.get(_uri(ruta, p), headers: _headers));
  Future<dynamic> _post(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.post(_uri(ruta), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> _put(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.put(_uri(ruta), headers: _headers, body: jsonEncode(body)));

  // ---------- Sistema ----------
  Future<bool> enLinea() async {
    try {
      final r = await _get('/health');
      return r['estado'] == 'en_linea';
    } catch (_) {
      return false;
    }
  }

  // ---------- Auth ----------
  Future<(Usuario, String)> login(String correo, String password) async {
    final r = await _post('/auth/login', {'correo': correo, 'password': password});
    return (Usuario.fromJson(r['usuario']), r['token'] as String);
  }

  Future<(Usuario, String)> registrar(Map<String, dynamic> datos) async {
    final r = await _post('/auth/registro', datos);
    return (Usuario.fromJson(r['usuario']), r['token'] as String);
  }

  Future<Usuario> yo() async => Usuario.fromJson(await _get('/auth/yo'));

  Future<void> cambiarPassword(String actual, String nueva) =>
      _put('/auth/password', {'actual': actual, 'nueva': nueva});

  // ---------- Usuarios ----------
  Future<List<Usuario>> usuarios({String? busqueda, String? estado}) async {
    final p = <String, String>{
      if (busqueda != null && busqueda.isNotEmpty) 'q': busqueda,
      if (estado != null) 'estado': estado,
    };
    final r = await _get('/usuarios', p.isEmpty ? null : p);
    return (r as List).map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario> usuario(int id) async => Usuario.fromJson(await _get('/usuarios/$id'));

  Future<Usuario> actualizarUsuario(int id, Map<String, dynamic> cambios) async =>
      Usuario.fromJson(await _put('/usuarios/$id', cambios));

  // ---------- Reportes ----------
  Future<Reporte> reporte(DateTime desde, DateTime hasta) async {
    String f(DateTime d) => d.toIso8601String().substring(0, 10);
    return Reporte.fromJson(await _get('/reportes', {'desde': f(desde), 'hasta': f(hasta)}));
  }

  // ---------- Configuración ----------
  Future<Map<String, dynamic>> configuracion() async =>
      Map<String, dynamic>.from(await _get('/configuracion'));

  Future<Map<String, dynamic>> guardarConfiguracion(Map<String, dynamic> cambios) async =>
      Map<String, dynamic>.from(await _put('/configuracion', cambios));
}
