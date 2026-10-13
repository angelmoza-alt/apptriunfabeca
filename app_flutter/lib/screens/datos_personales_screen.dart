import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../providers/usuarios_provider.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 4. Datos personales: ver y editar.
/// Sin argumentos edita al usuario logueado; con un [Usuario] como argumento
/// (desde Detalle de usuario) edita a ese usuario (solo admin).
class DatosPersonalesScreen extends StatefulWidget {
  const DatosPersonalesScreen({super.key});

  @override
  State<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends State<DatosPersonalesScreen> {
  final _form = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apPaterno = TextEditingController();
  final _apMaterno = TextEditingController();
  final _dni = TextEditingController();
  final _correo = TextEditingController();
  late Usuario _usuario;
  bool _iniciado = false;
  bool _editando = false;
  bool _guardando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    _usuario = arg is Usuario ? arg : context.read<AuthProvider>().usuario!;
    _llenar();
    // Si viene desde "Editar perfil", abre directamente en modo edición
    _editando = arg is Usuario;
    _iniciado = true;
  }

  void _llenar() {
    _nombres.text = _usuario.nombres;
    _apPaterno.text = _usuario.apellidoPaterno;
    _apMaterno.text = _usuario.apellidoMaterno;
    _dni.text = _usuario.dni;
    _correo.text = _usuario.correo;
  }

  @override
  void dispose() {
    for (final c in [_nombres, _apPaterno, _apMaterno, _dni, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final usuarios = context.read<UsuariosProvider>();
    final cambios = {
      'nombres': _nombres.text.trim(),
      'apellidoPaterno': _apPaterno.text.trim(),
      'apellidoMaterno': _apMaterno.text.trim(),
      'dni': _dni.text.trim(),
      'correo': _correo.text.trim(),
    };
    setState(() => _guardando = true);
    try {
      final actualizado = await auth.api.actualizarUsuario(_usuario.id, cambios);
      auth.reemplazarSiEsYo(actualizado); // actualiza saludo, menú, etc.
      usuarios.actualizarEnLista(actualizado); // actualiza la lista de Usuarios
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
      appBar: AppBar(title: const Text('Mis datos')),
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
                  etiqueta: 'Nombres', icono: Icons.person_outline, controller: _nombres,
                  habilitado: _editando, validator: (v) => Validadores.requerido(v, 'Nombres')),
              CampoTexto(
                  etiqueta: 'Apellido paterno', icono: Icons.person_outline, controller: _apPaterno,
                  habilitado: _editando, validator: (v) => Validadores.requerido(v, 'Apellido paterno')),
              CampoTexto(
                  etiqueta: 'Apellido materno', icono: Icons.person_outline, controller: _apMaterno,
                  habilitado: _editando, validator: (v) => Validadores.requerido(v, 'Apellido materno')),
              CampoTexto(
                  etiqueta: 'DNI', icono: Icons.badge_outlined, controller: _dni, maxLength: 8,
                  teclado: TextInputType.number, habilitado: _editando, validator: Validadores.dni),
              CampoTexto(
                  etiqueta: 'Correo electrónico', icono: Icons.email_outlined, controller: _correo,
                  teclado: TextInputType.emailAddress, habilitado: _editando, validator: Validadores.correo),
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
