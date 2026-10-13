class Usuario {
  final int id;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String dni;
  final String correo;
  final String estado; // activo | en_proceso | inactivo | rechazado
  final String rol; // admin | estudiante
  final DateTime? creadoEn;

  Usuario({
    required this.id,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.dni,
    required this.correo,
    required this.estado,
    required this.rol,
    this.creadoEn,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'] as int,
        nombres: j['nombres'] ?? '',
        apellidoPaterno: j['apellidoPaterno'] ?? '',
        apellidoMaterno: j['apellidoMaterno'] ?? '',
        dni: j['dni'] ?? '',
        correo: j['correo'] ?? '',
        estado: j['estado'] ?? 'activo',
        rol: j['rol'] ?? 'estudiante',
        creadoEn: j['creadoEn'] != null ? DateTime.tryParse(j['creadoEn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombres': nombres,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'dni': dni,
        'correo': correo,
        'estado': estado,
        'rol': rol,
        'creadoEn': creadoEn?.toIso8601String(),
      };

  String get nombreCorto => '$nombres $apellidoPaterno';
  String get nombreCompleto => '$nombres $apellidoPaterno $apellidoMaterno';
  bool get esAdmin => rol == 'admin';
  String get iniciales =>
      '${nombres.isNotEmpty ? nombres[0] : ''}${apellidoPaterno.isNotEmpty ? apellidoPaterno[0] : ''}'
          .toUpperCase();
}
