import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Ayudas para que la app se adapte a celulares pequeños, grandes y tablets.
class Responsive {
  /// Ancho a partir del cual consideramos "tablet"
  static const anchoTablet = 600.0;

  /// Ancho a partir del cual se usa la barra lateral en vez de la inferior
  static const anchoNavLateral = 840.0;

  static double ancho(BuildContext c) => MediaQuery.sizeOf(c).width;
  static double alto(BuildContext c) => MediaQuery.sizeOf(c).height;
  static bool esTablet(BuildContext c) => ancho(c) >= anchoTablet;
  static bool esAngosto(BuildContext c) => ancho(c) < 380;

  /// Padding que centra el contenido y limita su ancho máximo.
  /// En celular deja 20 px a los lados; en tablet centra una columna de [maxAncho].
  static EdgeInsets padding(
    BuildContext c, {
    double maxAncho = 600,
    double lateral = 20,
    double arriba = 20,
    double abajo = 20,
  }) {
    // Usa el ancho real disponible (descuenta la barra lateral en tablets grandes)
    final disponible = ancho(c) - (ancho(c) >= anchoNavLateral ? 80 : 0);
    final h = math.max(lateral, (disponible - maxAncho) / 2);
    // Espacio extra abajo para la barra de navegación de Android/iPhone
    // (en Android 15 la app se dibuja hasta el borde de la pantalla)
    final sistema = MediaQuery.paddingOf(c).bottom;
    return EdgeInsets.fromLTRB(h, arriba, h, abajo + sistema);
  }

  /// Tamaño del logo según la pantalla (nunca más del 70% del ancho)
  static double logo(BuildContext c, double ideal) => math.min(ideal, ancho(c) * 0.7);
}
