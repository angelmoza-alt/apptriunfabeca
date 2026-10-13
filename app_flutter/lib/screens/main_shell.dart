import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'cambiar_password_screen.dart';
import 'configuracion_screen.dart';
import 'dashboard_screen.dart';
import 'menu_lateral.dart';
import 'mis_datos_screen.dart';

/// Contenedor principal con la barra inferior (Inicio, Datos, Seguridad, Perfil)
/// y el menú lateral. Cada pestaña es una pantalla completa.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Permite cambiar de pestaña desde cualquier pantalla hija (ej. el menú lateral)
  static void irAPestana(BuildContext context, int indice) {
    context.findAncestorStateOfType<_MainShellState>()?._cambiar(indice);
  }

  static void abrirMenu(BuildContext context) {
    context.findAncestorStateOfType<_MainShellState>()?._scaffoldKey.currentState?.openDrawer();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _indice = 0;

  void _cambiar(int i) => setState(() => _indice = i);

  static const _destinos = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.person_outline, Icons.person, 'Datos'),
    (Icons.lock_outline, Icons.lock, 'Seguridad'),
    (Icons.account_circle_outlined, Icons.account_circle, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    // Tablet grande u horizontal: barra lateral. Celular: barra inferior.
    final lateral = Responsive.ancho(context) >= Responsive.anchoNavLateral;
    final paginas = IndexedStack(
      index: _indice,
      children: const [
        DashboardScreen(),
        MisDatosScreen(enPestana: true),
        CambiarPasswordScreen(enPestana: true),
        ConfiguracionScreen(enPestana: true),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: MenuLateral(indiceActual: _indice),
      body: lateral
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _indice,
                  onDestinationSelected: _cambiar,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (icono, activo, texto) in _destinos)
                      NavigationRailDestination(
                          icon: Icon(icono), selectedIcon: Icon(activo), label: Text(texto)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: paginas),
              ],
            )
          : paginas,
      bottomNavigationBar: lateral
          ? null
          : NavigationBar(
              selectedIndex: _indice,
              onDestinationSelected: _cambiar,
              height: 68,
              destinations: [
                for (final (icono, activo, texto) in _destinos)
                  NavigationDestination(icon: Icon(icono), selectedIcon: Icon(activo), label: texto),
              ],
            ),
    );
  }
}
