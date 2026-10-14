/// Usuario de la tabla "usuarios" de la API de Triunfa Beca.
/// El mismo usuario inicia sesión en la app, en Gestión y en Respuestas Rápidas.
class Usuario {
  final String id; // UUID
  final String nombre;
  final String correo;
  final String role; // 'ADMIN' | 'staff'
  final bool esActivo;
  final DateTime? fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.role,
    this.esActivo = true,
    this.fechaCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'].toString(),
        nombre: j['nombre'] ?? '',
        correo: j['correo'] ?? '',
        role: j['role'] ?? 'staff',
        esActivo: j['es_activo'] ?? true,
        fechaCreacion: j['fecha_creacion'] != null ? DateTime.tryParse(j['fecha_creacion'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'correo': correo,
        'role': role,
        'es_activo': esActivo,
        'fecha_creacion': fechaCreacion?.toIso8601String(),
      };

  bool get esAdmin => role.toUpperCase() == 'ADMIN';
  String get rolTexto => esAdmin ? 'Administrador' : 'Staff';

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  String get fechaTexto {
    final f = fechaCreacion?.toLocal();
    if (f == null) return '-';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }
}
