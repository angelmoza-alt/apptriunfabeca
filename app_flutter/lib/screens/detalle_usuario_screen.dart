import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/usuarios_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';

/// 6. Detalle de usuario.
/// Argumento: id (String) del usuario. Sin argumento muestra al usuario logueado.
class DetalleUsuarioScreen extends StatefulWidget {
  const DetalleUsuarioScreen({super.key});

  @override
  State<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends State<DetalleUsuarioScreen> {
  Usuario? _usuario;
  String? _error;
  bool _iniciado = false;
  bool _ocupado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    _cargar();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    final arg = ModalRoute.of(context)?.settings.arguments;
    try {
      // Admin: /usuarios/:id (datos completos). Staff solo ve su perfil: /auth/me
      final id = arg is String ? arg : auth.usuario!.id;
      final u = auth.esAdmin ? await auth.api.usuario(id) : await auth.api.yo();
      if (mounted) setState(() => _usuario = u);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _editar() async {
    final res = await Navigator.pushNamed(context, Rutas.datosPersonales, arguments: _usuario);
    if (res is Usuario && mounted) setState(() => _usuario = res);
  }

  Future<void> _aplicar(Future<Usuario> Function() accion, String mensaje) async {
    final lista = context.read<UsuariosProvider>();
    final auth = context.read<AuthProvider>();
    setState(() => _ocupado = true);
    try {
      final u = await accion();
      lista.actualizarEnLista(u);
      auth.reemplazarSiEsYo(u);
      if (!mounted) return;
      setState(() => _usuario = u);
      mostrarMensaje(context, mensaje);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _restablecerPassword() async {
    final api = context.read<AuthProvider>().api;
    final ctrl = TextEditingController();
    final form = GlobalKey<FormState>();
    final nueva = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Asigna una nueva contraseña a ${_usuario!.nombre}. '
                'Servirá para la app, Gestión y Respuestas Rápidas.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              obscureText: true,
              validator: Validadores.password,
              decoration: const InputDecoration(hintText: 'Nueva contraseña (mín. 6)'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, ctrl.text);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nueva == null || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await api.restablecerPassword(_usuario!.id, nueva);
      if (mounted) mostrarMensaje(context, 'Contraseña restablecida');
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = _usuario;
    final esYo = u != null && auth.usuario?.id == u.id;
    final adminSobreOtro = u != null && auth.esAdmin && !esYo;
    final api = auth.api;

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
                    Center(child: AvatarUsuario(usuario: u, radio: 40)),
                    const SizedBox(height: 12),
                    Text(u.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulOscuro)),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      EstadoBadge(u.esActivo),
                      const SizedBox(width: 6),
                      RolBadge(u.esAdmin),
                    ]),
                    const SizedBox(height: 12),
                    FilaDato(icono: Icons.person_outline, etiqueta: 'Usuario', valor: u.nombre),
                    FilaDato(icono: Icons.email_outlined, etiqueta: 'Correo', valor: u.correo),
                    const FilaDato(icono: Icons.key, etiqueta: 'Contraseña', valor: '••••••••'),
                    FilaDato(icono: Icons.verified_user_outlined, etiqueta: 'Rol', valor: u.rolTexto),
                    const FilaDato(icono: Icons.apps, etiqueta: 'Acceso a', valor: 'App, Gestión y R. Rápidas'),
                    if (adminSobreOtro) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Cuenta activa', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(u.esActivo ? 'Puede iniciar sesión' : 'No puede iniciar sesión'),
                        value: u.esActivo,
                        onChanged: _ocupado
                            ? null
                            : (v) => _aplicar(() => api.cambiarEstado(u.id, v),
                                v ? 'Usuario activado' : 'Usuario desactivado'),
                      ),
                      const SizedBox(height: 4),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'staff', label: Text('Staff')),
                          ButtonSegment(value: 'ADMIN', label: Text('Administrador')),
                        ],
                        selected: {u.esAdmin ? 'ADMIN' : 'staff'},
                        onSelectionChanged: _ocupado
                            ? null
                            : (s) => _aplicar(() => api.actualizarUsuario(u.id, {'role': s.first}), 'Rol actualizado'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _ocupado ? null : _restablecerPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Restablecer contraseña'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (esYo || auth.esAdmin)
                      ElevatedButton.icon(
                        onPressed: _ocupado ? null : _editar,
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
