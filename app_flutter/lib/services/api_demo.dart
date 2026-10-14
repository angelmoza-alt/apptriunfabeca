import '../models/reporte.dart';
import '../models/usuario.dart';
import 'api_service.dart';

/// Modo demo: misma interfaz que ApiService pero con datos de ejemplo en memoria.
/// Sirve para revisar el diseño sin tener la API corriendo.
/// Se activa con ApiConfig.modoDemo = true. Cualquier correo/contraseña entra;
/// si el correo empieza con "staff" entras como Staff.
class ApiDemo extends ApiService {
  final _hoy = DateTime.now();
  late final List<Usuario> _usuarios = [
    _u('1', 'Ana Torres', 'ana@triunfabeca.com', 'ADMIN', true, 0),
    _u('2', 'Carlos Méndez', 'carlos@triunfabeca.com', 'staff', true, 1),
    _u('3', 'Lucía Rojas', 'lucia@triunfabeca.com', 'staff', true, 2),
    _u('4', 'Daniel Silva', 'daniel@triunfabeca.com', 'staff', false, 2),
    _u('5', 'María Quispe', 'maria@triunfabeca.com', 'ADMIN', true, 3),
    _u('6', 'Jorge Vargas', 'jorge@triunfabeca.com', 'staff', true, 4),
    _u('7', 'Rosa Chávez', 'rosa@triunfabeca.com', 'staff', true, 5),
    _u('8', 'Luis Ramos', 'luis@triunfabeca.com', 'staff', true, 3),
  ];
  String _yo = '1';

  Usuario _u(String id, String n, String c, String r, bool a, int mesesAtras) => Usuario(
      id: id, nombre: n, correo: c, role: r, esActivo: a,
      fechaCreacion: DateTime(_hoy.year, _hoy.month - mesesAtras, 5));

  Future<T> _demora<T>(T v) => Future.delayed(const Duration(milliseconds: 300), () => v);

  Usuario _buscar(String id) =>
      _usuarios.firstWhere((u) => u.id == id, orElse: () => throw ApiException('Usuario no encontrado', 404));

  void _reemplazar(Usuario u) => _usuarios[_usuarios.indexWhere((x) => x.id == u.id)] = u;

  Usuario _copiar(Usuario u, {String? nombre, String? correo, String? role, bool? esActivo}) => Usuario(
      id: u.id,
      nombre: nombre ?? u.nombre,
      correo: correo ?? u.correo,
      role: role ?? u.role,
      esActivo: esActivo ?? u.esActivo,
      fechaCreacion: u.fechaCreacion);

  @override
  Future<bool> enLinea() => _demora(true);

  @override
  Future<(Usuario, String)> login(String correo, String password) async {
    _yo = correo.toLowerCase().startsWith('staff') ? '2' : '1';
    return _demora((_buscar(_yo), 'token-demo'));
  }

  @override
  Future<Usuario> yo() => _demora(_buscar(_yo));

  @override
  Future<Usuario> actualizarMiPerfil(Map<String, dynamic> cambios) async {
    final u = _copiar(_buscar(_yo), nombre: cambios['nombre'], correo: cambios['correo']);
    _reemplazar(u);
    return _demora(u);
  }

  @override
  Future<void> cambiarPassword(String actual, String nueva) => _demora(null);

  @override
  Future<List<Usuario>> usuarios({String? busqueda, String? role, bool? activo}) {
    final q = (busqueda ?? '').toLowerCase();
    return _demora(_usuarios
        .where((u) => q.isEmpty || u.nombre.toLowerCase().contains(q) || u.correo.toLowerCase().contains(q))
        .where((u) => role == null || u.role == role)
        .where((u) => activo == null || u.esActivo == activo)
        .toList());
  }

  @override
  Future<Usuario> usuario(String id) => _demora(_buscar(id));

  @override
  Future<Usuario> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String role,
  }) async {
    if (_usuarios.any((u) => u.correo == correo.toLowerCase())) {
      throw ApiException('Ya existe un usuario con ese correo', 409);
    }
    final u = Usuario(
        id: '${_usuarios.length + 1}', nombre: nombre, correo: correo.toLowerCase(),
        role: role, esActivo: true, fechaCreacion: DateTime.now());
    _usuarios.insert(0, u);
    return _demora(u);
  }

  @override
  Future<Usuario> actualizarUsuario(String id, Map<String, dynamic> cambios) async {
    final u = _copiar(_buscar(id), nombre: cambios['nombre'], correo: cambios['correo'], role: cambios['role']);
    _reemplazar(u);
    return _demora(u);
  }

  @override
  Future<Usuario> cambiarEstado(String id, bool activo) async {
    final u = _copiar(_buscar(id), esActivo: activo);
    _reemplazar(u);
    return _demora(u);
  }

  @override
  Future<void> restablecerPassword(String id, String nueva) => _demora(null);

  @override
  Future<Reporte> reporte(DateTime desde, DateTime hasta) {
    final enRango = _usuarios.where((u) {
      final f = u.fechaCreacion!;
      return !f.isBefore(DateTime(desde.year, desde.month, desde.day)) && !f.isAfter(hasta);
    }).toList();
    final meses = <RegistroMes>[];
    var m = DateTime(desde.year, desde.month);
    while (!m.isAfter(DateTime(hasta.year, hasta.month))) {
      final total = enRango.where((u) => u.fechaCreacion!.year == m.year && u.fechaCreacion!.month == m.month).length;
      meses.add(RegistroMes('${m.year}-${m.month.toString().padLeft(2, '0')}', total));
      m = DateTime(m.year, m.month + 1);
    }
    return _demora(Reporte(
      total: enRango.length,
      activos: enRango.where((u) => u.esActivo).length,
      inactivos: enRango.where((u) => !u.esActivo).length,
      admins: enRango.where((u) => u.esAdmin).length,
      staff: enRango.where((u) => !u.esAdmin).length,
      porMes: meses,
    ));
  }
}
