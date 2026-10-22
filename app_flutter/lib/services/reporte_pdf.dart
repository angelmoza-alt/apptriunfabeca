import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reporte.dart';

final _azul = PdfColor.fromInt(0xFF1446B8);
final _azulOscuro = PdfColor.fromInt(0xFF0A2A78);
final _azulClaro = PdfColor.fromInt(0xFFE8EFFF);
final _rojo = PdfColor.fromInt(0xFFD7141A);
final _verde = PdfColor.fromInt(0xFF22A45D);
final _morado = PdfColor.fromInt(0xFF7B3FE4);
final _gris = PdfColor.fromInt(0xFF6B7280);

String _f(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Arma el reporte de usuarios en PDF (tamaño A4) con encabezado, indicadores,
/// tabla de métricas y gráfico de barras por mes.
Future<Uint8List> crearReportePdf({
  required Reporte reporte,
  required DateTime desde,
  required DateTime hasta,
  required String sede,
  required String generadoPor,
  String? logoPath,
}) async {
  // Logo: el personalizado (si existe) o el de la app
  Uint8List logoBytes;
  if (logoPath != null && !kIsWeb && File(logoPath).existsSync()) {
    logoBytes = await File(logoPath).readAsBytes();
  } else {
    logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
  }
  final logo = pw.MemoryImage(logoBytes);
  final r = reporte;
  final ahora = DateTime.now();
  String pct(int v) => r.total == 0 ? '0 %' : '${(v * 100 / r.total).toStringAsFixed(1)} %';

  pw.Widget indicador(String titulo, int valor, PdfColor color) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 4),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 1.2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(titulo, style: pw.TextStyle(fontSize: 9, color: color)),
            pw.SizedBox(height: 4),
            pw.Text('$valor', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
          ]),
        ),
      );

  final maximo = r.porMes.fold<int>(0, (a, m) => m.total > a ? m.total : a);

  final doc = pw.Document(title: 'Reporte Triunfa Beca', author: generadoPor);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 26, 36, 22),
      header: (ctx) => pw.Column(children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, height: 46),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Reporte de usuarios',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _azulOscuro)),
                pw.Text('Triunfa Beca - $sede', style: pw.TextStyle(fontSize: 10, color: _gris)),
              ]),
            ),
            pw.Text('Generado: ${_f(ahora)}', style: pw.TextStyle(fontSize: 9, color: _gris)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 3, color: _azul),
        pw.Container(height: 2, color: _rojo),
        pw.SizedBox(height: 14),
      ]),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Triunfa Beca - Tu esfuerzo, nuestro apoyo', style: pw.TextStyle(fontSize: 8, color: _gris)),
          pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _gris)),
        ],
      ),
      build: (ctx) => [
        // Datos del reporte
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: _azulClaro, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Rango: ${_f(desde)} al ${_f(hasta)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Generado por: $generadoPor', style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 10),

        // Indicadores
        pw.Text('Resumen general', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          indicador('Total usuarios', r.total, _azul),
          indicador('Activos', r.activos, _verde),
          indicador('Inactivos', r.inactivos, _rojo),
          indicador('Administradores', r.admins, _morado),
        ]),
        pw.SizedBox(height: 12),

        // Tabla de métricas
        pw.Text('Detalle de métricas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Indicador', 'Cantidad', 'Porcentaje'],
          data: [
            ['Usuarios registrados', '${r.total}', r.total == 0 ? '0 %' : '100 %'],
            ['Cuentas activas', '${r.activos}', pct(r.activos)],
            ['Cuentas inactivas', '${r.inactivos}', pct(r.inactivos)],
            ['Administradores', '${r.admins}', pct(r.admins)],
            ['Staff', '${r.staff}', pct(r.staff)],
          ],
          headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          headerDecoration: pw.BoxDecoration(color: _azul),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center},
          oddRowDecoration: pw.BoxDecoration(color: _azulClaro),
          border: null,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        pw.SizedBox(height: 12),

        // Gráfico de barras
        pw.Text('Evolución de registros por mes',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        if (r.porMes.isEmpty)
          pw.Text('Sin registros en este rango.', style: pw.TextStyle(color: _gris))
        else
          pw.Container(
            height: 120,
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _gris, width: 0.6))),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final m in r.porMes)
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('${m.total}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          height: maximo == 0 ? 2 : 2 + (m.total / maximo) * 90,
                          margin: const pw.EdgeInsets.symmetric(horizontal: 6),
                          decoration: pw.BoxDecoration(
                            color: _azul,
                            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (r.porMes.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Row(children: [
            for (final m in r.porMes)
              pw.Expanded(
                child: pw.Text('${m.etiqueta} ${m.mes.split('-').first.substring(2)}',
                    textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, color: _gris)),
              ),
          ]),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Mes', 'Registros'],
            data: [
              for (final m in r.porMes) ['${m.etiqueta} ${m.mes.split('-').first}', '${m.total}'],
            ],
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: pw.BoxDecoration(color: _azulOscuro),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center},
            oddRowDecoration: pw.BoxDecoration(color: _azulClaro),
            border: null,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}
