class RegistroMes {
  final String mes; // "2026-08"
  final int total;
  RegistroMes(this.mes, this.total);

  static const _nombres = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  String get etiqueta {
    final m = int.tryParse(mes.split('-').last) ?? 1;
    return _nombres[(m - 1).clamp(0, 11)];
  }
}

class Reporte {
  final int total, activos, enProceso, inactivos, rechazados;
  final List<RegistroMes> porMes;

  Reporte({
    required this.total,
    required this.activos,
    required this.enProceso,
    required this.inactivos,
    required this.rechazados,
    required this.porMes,
  });

  factory Reporte.fromJson(Map<String, dynamic> j) => Reporte(
        total: j['total'] ?? 0,
        activos: j['activos'] ?? 0,
        enProceso: j['enProceso'] ?? 0,
        inactivos: j['inactivos'] ?? 0,
        rechazados: j['rechazados'] ?? 0,
        porMes: ((j['porMes'] ?? []) as List)
            .map((e) => RegistroMes(e['mes'] as String, e['total'] as int))
            .toList(),
      );
}
