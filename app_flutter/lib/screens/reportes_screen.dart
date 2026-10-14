import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/reporte.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 7. Reportes: resumen por estado y evolución de registros por mes,
/// calculados en el servidor a partir de los usuarios reales.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late DateTimeRange _rango;
  Reporte? _reporte;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _rango = DateTimeRange(start: DateTime(hoy.year, hoy.month - 5, 1), end: hoy);
    _cargar();
  }

  String _f(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await context.read<AuthProvider>().api.reporte(_rango.start, _rango.end);
      if (mounted) setState(() => _reporte = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirRango() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
      helpText: 'Rango de fechas',
    );
    if (r != null) {
      setState(() => _rango = r);
      _cargar();
    }
  }

  void _generar() {
    final r = _reporte;
    if (r == null) return;
    final texto = StringBuffer()
      ..writeln('REPORTE TRIUNFA BECA')
      ..writeln('Rango: ${_f(_rango.start)} - ${_f(_rango.end)}')
      ..writeln('')
      ..writeln('Total usuarios: ${r.total}')
      ..writeln('Activos: ${r.activos}')
      ..writeln('Inactivos: ${r.inactivos}')
      ..writeln('Administradores: ${r.admins}')
      ..writeln('Staff: ${r.staff}')
      ..writeln('')
      ..writeln('Registros por mes:');
    for (final m in r.porMes) {
      texto.writeln('  ${m.etiqueta} ${m.mes.split('-').first}: ${m.total}');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reporte generado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.azulClaro.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(texto.toString(), style: const TextStyle(fontFamily: 'monospace')),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: texto.toString()));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) mostrarMensaje(context, 'Reporte copiado al portapapeles');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _reporte;
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: Responsive.padding(context, maxAncho: 900),
          children: [
            const Row(children: [
              Icon(Icons.date_range, size: 20, color: AppColors.azul),
              SizedBox(width: 6),
              Text('Rango de fechas', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _elegirRango,
              icon: const Icon(Icons.calendar_month),
              label: FittedBox(child: Text('${_f(_rango.start)}  →  ${_f(_rango.end)}')),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
            const SizedBox(height: 20),
            const Text('Resumen general', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            if (_cargando && r == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ]),
              )
            else if (r != null) ...[
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisExtent: 105,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                children: [
                  _Indicador('Total usuarios', r.total, Icons.people, AppColors.azul, AppColors.azulClaro),
                  _Indicador('Activos', r.activos, Icons.check_circle, AppColors.verde, AppColors.verdeClaro),
                  _Indicador('Inactivos', r.inactivos, Icons.block, AppColors.rojo, AppColors.rojoClaro),
                  _Indicador('Administradores', r.admins, Icons.admin_panel_settings, AppColors.morado, AppColors.moradoClaro),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Evolución de registros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _GraficoBarras(r.porMes),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _generar,
                icon: const Icon(Icons.download),
                label: const Text('Generar reporte'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color, fondo;
  const _Indicador(this.titulo, this.valor, this.icono, this.color, this.fondo);

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: oscuro ? color.withOpacity(0.15) : fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          FittedBox(child: Text('$valor', style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

/// Gráfico de barras simple (sin librerías externas).
/// Las barras usan una fracción del espacio disponible, así nunca se desbordan
/// aunque el celular tenga letra grande.
class _GraficoBarras extends StatelessWidget {
  final List<RegistroMes> datos;
  const _GraficoBarras(this.datos);

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const Text('Sin datos en este rango');
    final maximo = datos.map((d) => d.total).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final d in datos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Barra + número encima, ocupando todo el alto que sobra
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            child: Text('${d.total}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 500),
                              alignment: Alignment.bottomCenter,
                              widthFactor: 1,
                              heightFactor: maximo == 0 ? 0.02 : (d.total / maximo).clamp(0.02, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [AppColors.azul, Color(0xFF5B8DEF)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 18,
                      child: FittedBox(
                        child: Text(d.etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
