import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/usuarios_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 6. Detalle de usuario.
/// Argumento: id (int) del usuario. Sin argumento muestra al usuario logueado.
class DetalleUsuarioScreen extends StatefulWidget {
  const DetalleUsuarioScreen({super.key});

  @override
  State<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends State<DetalleUsuarioScreen> {
  Usuario? _usuario;
  String? _error;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _cargar();
  }

  int get _id {
    final arg = ModalRoute.of(context)?.settings.arguments;
    return arg is int ? arg : context.read<AuthProvider>().usuario!.id;
  }

  Future<void> _cargar() async {
    try {
      final u = await context.read<AuthProvider>().api.usuario(_id);
      if (mounted) setState(() => _usuario = u);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _editar() async {
    final res = await Navigator.pushNamed(context, Rutas.datosPersonales, arguments: _usuario);
    if (res is Usuario && mounted) setState(() => _usuario = res);
  }

  Future<void> _cambiarEstado(String estado) async {
    final auth = context.read<AuthProvider>();
    final lista = context.read<UsuariosProvider>();
    try {
      final u = await auth.api.actualizarUsuario(_usuario!.id, {'estado': estado});
      lista.actualizarEnLista(u);
      auth.reemplazarSiEsYo(u);
      if (!mounted) return;
      setState(() => _usuario = u);
      mostrarMensaje(context, 'Estado cambiado a ${EstadoBadge.texto(estado)}');
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = _usuario;
    final puedeEditar = u != null && (auth.esAdmin || auth.usuario?.id == u.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de usuario')),
      body: u == null
          ? Center(
              child: _error != null
                  ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))
                  : const CircularProgressIndicator(),
            )
          : Stack(
              children: [
                const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 90)),
                ListView(
                  padding: Responsive.padding(context, maxAncho: 640, abajo: 100),
                  children: [
                    Center(child: AvatarUsuario(usuario: u, radio: 48)),
                    const SizedBox(height: 12),
                    Text(u.nombreCorto,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulOscuro)),
                    Text(u.correo, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gris)),
                    const SizedBox(height: 8),
                    Center(child: EstadoBadge(u.estado)),
                    const SizedBox(height: 20),
                    const Text('Datos completos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    FilaDato(icono: Icons.person_outline, etiqueta: 'Nombres', valor: u.nombres),
                    FilaDato(icono: Icons.person_outline, etiqueta: 'Apellido paterno', valor: u.apellidoPaterno),
                    FilaDato(icono: Icons.person_outline, etiqueta: 'Apellido materno', valor: u.apellidoMaterno),
                    FilaDato(icono: Icons.badge_outlined, etiqueta: 'DNI', valor: u.dni),
                    FilaDato(icono: Icons.email_outlined, etiqueta: 'Correo', valor: u.correo),
                    const FilaDato(icono: Icons.key, etiqueta: 'Contraseña', valor: '••••••••'),
                    FilaDato(
                        icono: Icons.verified_user_outlined,
                        etiqueta: 'Rol',
                        valor: u.esAdmin ? 'Administrador' : 'Estudiante'),
                    if (auth.esAdmin && auth.usuario?.id != u.id) ...[
                      const SizedBox(height: 16),
                      const Text('Estado de la solicitud', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final e in ['activo', 'en_proceso', 'inactivo', 'rechazado'])
                            ChoiceChip(
                              label: Text(EstadoBadge.texto(e)),
                              selected: u.estado == e,
                              onSelected: (_) => _cambiarEstado(e),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (puedeEditar)
                      ElevatedButton.icon(
                        onPressed: _editar,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
