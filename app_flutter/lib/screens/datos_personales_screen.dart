import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/usuarios_provider.dart';
import '../utils/responsive.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';

/// 4. Datos personales: ver y editar nombre y correo.
/// Sin argumentos edita al usuario logueado; con un [Usuario] como argumento
/// (desde Detalle de usuario) el administrador edita a ese usuario.
class DatosPersonalesScreen extends StatefulWidget {
  const DatosPersonalesScreen({super.key});

  @override
  State<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends State<DatosPersonalesScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  late Usuario _usuario;
  bool _deOtro = false;
  bool _iniciado = false;
  bool _editando = false;
  bool _guardando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    final yo = context.read<AuthProvider>().usuario!;
    _usuario = arg is Usuario ? arg : yo;
    _deOtro = arg is Usuario && arg.id != yo.id;
    _editando = arg is Usuario; // desde "Editar perfil" abre directo en edición
    _llenar();
    _iniciado = true;
  }

  void _llenar() {
    _nombre.text = _usuario.nombre;
    _correo.text = _usuario.correo;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final usuarios = context.read<UsuariosProvider>();
    final cambios = {'nombre': _nombre.text.trim(), 'correo': _correo.text.trim()};
    setState(() => _guardando = true);
    try {
      final actualizado = _deOtro
          ? await auth.api.actualizarUsuario(_usuario.id, cambios)
          : await auth.actualizarMisDatos(cambios);
      auth.reemplazarSiEsYo(actualizado);
      usuarios.actualizarEnLista(actualizado);
      _usuario = actualizado;
      if (!mounted) return;
      setState(() => _editando = false);
      mostrarMensaje(context, 'Datos actualizados');
      if (ModalRoute.of(context)?.settings.arguments is Usuario) Navigator.pop(context, actualizado);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_deOtro ? 'Editar usuario' : 'Mis datos')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context, maxAncho: 560),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text('Información personal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              CampoTexto(
                  etiqueta: 'Usuario', icono: Icons.person_outline, controller: _nombre,
                  habilitado: _editando, validator: (v) => Validadores.requerido(v, 'Usuario')),
              CampoTexto(
                  etiqueta: 'Correo electrónico', icono: Icons.email_outlined, controller: _correo,
                  teclado: TextInputType.emailAddress, habilitado: _editando, validator: Validadores.correo),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Text('Rol: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  RolBadge(_usuario.esAdmin),
                ]),
              ),
              if (_editando && !_deOtro)
                const Text(
                  'Si cambias tu correo, úsalo también para entrar a Gestión y Respuestas Rápidas.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              if (!_editando)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editando = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar datos'),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Guardar cambios'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _llenar();
                    _editando = false;
                  }),
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
