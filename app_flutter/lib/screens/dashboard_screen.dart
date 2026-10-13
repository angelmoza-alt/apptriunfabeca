import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/config_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import '../utils/responsive.dart';

/// 3. Dashboard (Inicio)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool? _enLinea;
  int _enProceso = 0;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    if (_enLinea != null) setState(() => _enLinea = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.api.enLinea();
    int enProceso = 0;
    if (ok && auth.esAdmin) {
      try {
        enProceso = (await auth.api.usuarios(estado: 'en_proceso')).length;
      } on ApiException catch (_) {}
    }
    if (mounted) setState(() {
      _enLinea = ok;
      _enProceso = enProceso;
    });
  }

  void _verNotificaciones() {
    final notifOn = context.read<ConfigProvider>().notificaciones;
    final esAdmin = context.read<AuthProvider>().esAdmin;
    final avisos = <(IconData, String)>[
      if (!notifOn) (Icons.notifications_off, 'Tienes las notificaciones desactivadas en Configuración.'),
      if (notifOn && esAdmin && _enProceso > 0)
        (Icons.hourglass_top, 'Hay $_enProceso usuario(s) con solicitud en proceso.'),
      if (notifOn) (Icons.school, 'Bienvenido a Triunfa Beca. Completa tus datos para postular.'),
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            for (final (icono, texto) in avisos)
              ListTile(leading: Icon(icono, color: AppColors.azul), title: Text(texto)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifOn = context.watch<ConfigProvider>().notificaciones;
    final u = auth.usuario;
    final hayAviso = notifOn && auth.esAdmin && _enProceso > 0;

    final tarjetas = <_Accion>[
      if (auth.esAdmin)
        _Accion(Icons.person_add_alt_1, 'Registrar nuevo usuario', 'Crea una cuenta',
            () => Navigator.pushNamed(context, Rutas.registro)),
      _Accion(Icons.description_outlined, 'Mis datos', 'Consulta y edita tu perfil',
          () => MainShell.irAPestana(context, 1)),
      _Accion(Icons.lock_outline, 'Cambiar contraseña', 'Mantén tu cuenta segura',
          () => MainShell.irAPestana(context, 2)),
      _Accion(Icons.settings, 'Configuración', 'Ajusta tus preferencias',
          () => MainShell.irAPestana(context, 3)),
      if (auth.esAdmin)
        _Accion(Icons.groups, 'Usuarios', 'Gestiona estudiantes',
            () => Navigator.pushNamed(context, Rutas.usuarios)),
      if (auth.esAdmin)
        _Accion(Icons.bar_chart, 'Reportes', 'Resumen y estadísticas',
            () => Navigator.pushNamed(context, Rutas.reportes)),
      if (!auth.esAdmin)
        _Accion(Icons.help_outline, 'Ayuda', 'Preguntas frecuentes',
            () => Navigator.pushNamed(context, Rutas.ayuda)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => MainShell.abrirMenu(context)),
        title: const Text('Triunfa Beca'),
        actions: [
          IconButton(
            onPressed: _verNotificaciones,
            icon: Badge(isLabelVisible: hayAviso, backgroundColor: AppColors.rojo, child: const Icon(Icons.notifications)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _verificar,
        child: ListView(
          padding: Responsive.padding(context, maxAncho: 900),
          children: [
            Text('Hola, ${u?.nombreCorto ?? ''} 👋',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.azulOscuro)),
            const Text('Bienvenida(o) a Triunfa Beca', style: TextStyle(color: AppColors.azul)),
            const SizedBox(height: 20),
            // 2 columnas en celular, 3-4 en tablet; altura fija para que nunca se corte el texto
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisExtent: 185,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              children: tarjetas.map((a) => _TarjetaAccion(a)).toList(),
            ),
            const SizedBox(height: 16),
            _EstadoSistema(enLinea: _enLinea, onReintentar: _verificar),
          ],
        ),
      ),
    );
  }
}

class _Accion {
  final IconData icono;
  final String titulo, subtitulo;
  final VoidCallback onTap;
  _Accion(this.icono, this.titulo, this.subtitulo, this.onTap);
}

class _TarjetaAccion extends StatelessWidget {
  final _Accion a;
  const _TarjetaAccion(this.a);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: a.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.azul,
                child: Icon(a.icono, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(a.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(a.subtitulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoSistema extends StatelessWidget {
  final bool? enLinea;
  final VoidCallback onReintentar;
  const _EstadoSistema({required this.enLinea, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final color = enLinea == null ? AppColors.gris : (enLinea! ? AppColors.verde : AppColors.rojo);
    final texto = enLinea == null ? 'Verificando...' : (enLinea! ? 'En línea' : 'Sin conexión con el servidor');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estado del sistema', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.circle, size: 12, color: color),
                  const SizedBox(width: 6),
                  Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          IconButton(
            onPressed: onReintentar,
            icon: Icon(enLinea == false ? Icons.refresh : Icons.wifi, color: color),
          ),
        ],
      ),
    );
  }
}
