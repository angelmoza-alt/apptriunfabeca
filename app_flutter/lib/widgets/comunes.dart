import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Mensaje rápido abajo de la pantalla
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.rojo : AppColors.verde,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Ondas decorativas azul/rojo del diseño (abajo o arriba de la pantalla)
class Ondas extends StatelessWidget {
  final double alto;
  final bool arriba;
  const Ondas({super.key, this.alto = 120, this.arriba = false});

  @override
  Widget build(BuildContext context) {
    // En pantallas bajas (celular horizontal) las ondas se achican
    final altoReal = math.min(alto, Responsive.alto(context) * 0.14);
    return IgnorePointer(
      child: SizedBox(
        height: altoReal,
        width: double.infinity,
        child: Transform.flip(
          flipY: arriba,
          flipX: arriba,
          child: CustomPaint(painter: _OndasPainter()),
        ),
      ),
    );
  }
}

class _OndasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rojo = Path()
      ..moveTo(0, s.height * 0.55)
      ..quadraticBezierTo(s.width * 0.35, s.height * 0.15, s.width, s.height * 0.35)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(rojo, Paint()..color = AppColors.rojo.withOpacity(0.85));

    final azul = Path()
      ..moveTo(0, s.height * 0.75)
      ..quadraticBezierTo(s.width * 0.45, s.height * 0.35, s.width, s.height * 0.6)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
      azul,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.azulOscuro, AppColors.azul])
            .createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo con fondo transparente
class Logo extends StatelessWidget {
  final double ancho;
  final bool soloIcono;
  const Logo({super.key, this.ancho = 220, this.soloIcono = false});

  @override
  Widget build(BuildContext context) => Image.asset(
        soloIcono ? 'assets/images/logo_icono.png' : 'assets/images/logo.png',
        width: Responsive.logo(context, ancho),
        fit: BoxFit.contain,
      );
}

/// Círculo con iniciales del usuario
class AvatarUsuario extends StatelessWidget {
  final Usuario usuario;
  final double radio;
  const AvatarUsuario({super.key, required this.usuario, this.radio = 24});

  static const _colores = [AppColors.azul, AppColors.rojo, AppColors.verde, AppColors.morado, AppColors.naranja];

  @override
  Widget build(BuildContext context) {
    final color = _colores[usuario.id % _colores.length];
    return CircleAvatar(
      radius: radio,
      backgroundColor: color.withOpacity(0.15),
      child: Text(
        usuario.iniciales,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: radio * 0.7),
      ),
    );
  }
}

/// Etiqueta de estado: Activo / En proceso / Inactivo / Rechazado
class EstadoBadge extends StatelessWidget {
  final String estado;
  const EstadoBadge(this.estado, {super.key});

  static String texto(String e) => const {
        'activo': 'Activo',
        'en_proceso': 'En proceso',
        'inactivo': 'Inactivo',
        'rechazado': 'Rechazado',
      }[e] ??
      e;

  static (Color, Color) colores(String e) => switch (e) {
        'activo' => (AppColors.verde, AppColors.verdeClaro),
        'en_proceso' => (AppColors.naranja, AppColors.naranjaClaro),
        'rechazado' => (AppColors.rojo, AppColors.rojoClaro),
        _ => (AppColors.rojo, AppColors.rojoClaro),
      };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = colores(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(texto(estado), style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Campo de texto con etiqueta arriba e ícono, como en el diseño
class CampoTexto extends StatelessWidget {
  final String etiqueta;
  final String? pista;
  final IconData icono;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? teclado;
  final bool oculto;
  final Widget? sufijo;
  final bool habilitado;
  final int? maxLength;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.controller,
    this.pista,
    this.validator,
    this.teclado,
    this.oculto = false,
    this.sufijo,
    this.habilitado = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: teclado,
            obscureText: oculto,
            enabled: habilitado,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: pista,
              counterText: '',
              prefixIcon: Icon(icono, size: 20, color: AppColors.azul),
              suffixIcon: sufijo,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de menú con ícono de color, título, subtítulo y flecha
class OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color fondo;
  final VoidCallback onTap;
  final Widget? trailing;

  const OpcionMenu({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.color = AppColors.azul,
    this.fondo = AppColors.azulClaro,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: oscuro ? color.withOpacity(0.15) : fondo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icono, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitulo,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                    ],
                  ),
                ),
                trailing ?? Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila "etiqueta: valor" para la pantalla de detalle
class FilaDato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  const FilaDato({super.key, required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.azul),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(etiqueta, style: const TextStyle(color: AppColors.gris, fontSize: 13))),
          Expanded(flex: 3, child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
