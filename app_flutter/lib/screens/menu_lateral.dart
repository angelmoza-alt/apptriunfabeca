import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import 'main_shell.dart';

/// 10. Menú lateral
class MenuLateral extends StatelessWidget {
  final int indiceActual;
  const MenuLateral({super.key, required this.indiceActual});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    void irPestana(int i) {
      Navigator.pop(context);
      MainShell.irAPestana(context, i);
    }

    void irRuta(String ruta) {
      Navigator.pop(context);
      Navigator.pushNamed(context, ruta);
    }

    Widget item(IconData icono, String texto, VoidCallback onTap, {bool activo = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          leading: Icon(icono, color: activo ? Colors.white : AppColors.azul),
          title: Text(texto,
              style: TextStyle(fontWeight: FontWeight.w600, color: activo ? Colors.white : null)),
          tileColor: activo ? AppColors.azul : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          onTap: onTap,
        ),
      );
    }

    return Drawer(
      child: Stack(
        children: [
          const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 110)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ),
                const Center(child: Logo(ancho: 170)),
                if (auth.usuario != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.usuario!.nombreCorto,
                      textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(auth.esAdmin ? 'Administrador' : 'Estudiante',
                      textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gris, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                item(Icons.home, 'Inicio', () => irPestana(0), activo: indiceActual == 0),
                item(Icons.person, 'Mis datos', () => irPestana(1), activo: indiceActual == 1),
                if (auth.esAdmin) item(Icons.bar_chart, 'Reportes', () => irRuta(Rutas.reportes)),
                if (auth.esAdmin) item(Icons.groups, 'Usuarios', () => irRuta(Rutas.usuarios)),
                item(Icons.settings, 'Configuración', () => irPestana(3), activo: indiceActual == 3),
                item(Icons.help_outline, 'Ayuda', () => irRuta(Rutas.ayuda)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.rojo),
                    title: const Text('Cerrar sesión',
                        style: TextStyle(color: AppColors.rojo, fontWeight: FontWeight.w600)),
                    onTap: () => confirmarCerrarSesion(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Usado por el menú lateral y por Configuración
Future<void> confirmarCerrarSesion(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres salir?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Salir', style: TextStyle(color: AppColors.rojo)),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    context.read<ConfigProvider>().reiniciar();
    await context.read<AuthProvider>().cerrarSesion();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(Rutas.login, (_) => false);
    }
  }
}
