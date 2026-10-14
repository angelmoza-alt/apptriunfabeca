import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import 'menu_lateral.dart';
import '../utils/responsive.dart';

/// 9. Perfil / Configuración
class ConfiguracionScreen extends StatelessWidget {
  final bool enPestana;
  const ConfiguracionScreen({super.key, this.enPestana = false});

  Future<void> _guardar(BuildContext context, Future<void> Function() accion) async {
    try {
      await accion();
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, 'No se pudo guardar: $e', error: true);
    }
  }

  Future<void> _elegirTema(BuildContext context) async {
    final config = context.read<ConfigProvider>();
    final elegido = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tema'),
        children: [
          for (final (valor, texto) in [('claro', 'Claro'), ('oscuro', 'Oscuro')])
            RadioListTile<String>(
              value: valor,
              groupValue: config.tema,
              title: Text(texto),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
        ],
      ),
    );
    if (elegido != null && context.mounted) {
      await _guardar(context, () => config.cambiar(tema: elegido));
    }
  }

  Future<void> _elegirIdioma(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Idioma'),
        children: [
          const ListTile(leading: Icon(Icons.check, color: AppColors.azul), title: Text('Español (ES)')),
          const ListTile(
            enabled: false,
            leading: SizedBox(width: 24),
            title: Text('English (próximamente)'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    Widget fila(IconData icono, String titulo, String sub, {VoidCallback? onTap, Widget? trailing}) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Icon(icono, color: AppColors.azul, size: 28),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        automaticallyImplyLeading: !enPestana,
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.settings))],
      ),
      body: Stack(
        children: [
          const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 90)),
          ListView(
            padding: Responsive.padding(context, maxAncho: 640, arriba: 12, abajo: 100),
            children: [
              fila(Icons.person, 'Perfil de usuario', 'Ver tu información completa',
                  onTap: () => Navigator.pushNamed(context, Rutas.detalleUsuario)),
              const Divider(),
              fila(Icons.lock, 'Cambiar contraseña', 'Configura una nueva clave',
                  onTap: () => Navigator.pushNamed(context, Rutas.cambiarPassword)),
              const Divider(),
              fila(
                Icons.notifications,
                'Notificaciones',
                'Gestiona tus alertas',
                trailing: Switch(
                  value: config.notificaciones,
                  onChanged: (v) => _guardar(context, () => config.cambiar(notificaciones: v)),
                ),
              ),
              const Divider(),
              fila(Icons.language, 'Idioma', 'Español (ES)', onTap: () => _elegirIdioma(context)),
              const Divider(),
              fila(Icons.dark_mode, 'Tema', 'Claro / Oscuro',
                  onTap: () => _elegirTema(context)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => confirmarCerrarSesion(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rojo,
                  backgroundColor: AppColors.rojoClaro,
                  side: const BorderSide(color: AppColors.rojo),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
