import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 5. Mis datos (menú de opciones de la cuenta)
class MisDatosScreen extends StatelessWidget {
  final bool enPestana;
  const MisDatosScreen({super.key, this.enPestana = false});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos'), automaticallyImplyLeading: !enPestana),
      body: Stack(
        children: [
          const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 100)),
          ListView(
            padding: Responsive.padding(context, maxAncho: 640, abajo: 110),
            children: [
              OpcionMenu(
                icono: Icons.person,
                titulo: 'Información personal',
                subtitulo: 'Ver y editar tus datos',
                color: AppColors.verde,
                fondo: AppColors.verdeClaro,
                onTap: () => Navigator.pushNamed(context, Rutas.datosPersonales),
              ),
              OpcionMenu(
                icono: Icons.lock,
                titulo: 'Cambiar contraseña',
                subtitulo: 'Actualiza tu contraseña',
                onTap: () => Navigator.pushNamed(context, Rutas.cambiarPassword),
              ),
              OpcionMenu(
                icono: Icons.notifications,
                titulo: 'Notificaciones',
                subtitulo: config.notificaciones ? 'Activadas' : 'Desactivadas',
                color: AppColors.naranja,
                fondo: AppColors.naranjaClaro,
                onTap: () => context.read<ConfigProvider>().cambiar(notificaciones: !config.notificaciones),
                trailing: Switch(
                  value: config.notificaciones,
                  onChanged: (v) => context.read<ConfigProvider>().cambiar(notificaciones: v),
                ),
              ),
              OpcionMenu(
                icono: Icons.help,
                titulo: 'Ayuda',
                subtitulo: 'Preguntas frecuentes',
                color: AppColors.morado,
                fondo: AppColors.moradoClaro,
                onTap: () => Navigator.pushNamed(context, Rutas.ayuda),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
