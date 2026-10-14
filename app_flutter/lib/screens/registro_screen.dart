import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/usuarios_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';

/// 2. Registrar usuario (solo administrador).
/// El usuario se crea en la tabla compartida de la API de Triunfa Beca,
/// así que con ese correo y contraseña podrá iniciar sesión en
/// Gestión, Respuestas Rápidas y en esta app.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  String _role = 'staff';
  bool _ocultar = true;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _correo, _password, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final usuarios = context.read<UsuariosProvider>();
    setState(() => _guardando = true);
    try {
      final nuevo = await auth.crearUsuario(
        nombre: _nombre.text.trim(),
        correo: _correo.text.trim(),
        password: _password.text,
        role: _role,
      );
      usuarios.cargar();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.verde, size: 48),
          title: const Text('Usuario creado'),
          content: Text(
            '${nuevo.nombre} ya puede iniciar sesión en Gestión, Respuestas Rápidas y en la app con:\n\n'
            'Correo: ${nuevo.correo}\nContraseña: la que acabas de asignar.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ojo = IconButton(
      icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _ocultar = !_ocultar),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Registrar nuevo usuario')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context, maxAncho: 560),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Logo(ancho: 90, soloIcono: true)),
              const SizedBox(height: 4),
              const Text('Crea una cuenta', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris)),
              const SizedBox(height: 12),
              CajaPunteada(
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppColors.azulOscuro, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(color: AppColors.azulOscuro, fontSize: 12.5),
                          children: const [
                            TextSpan(text: 'Esta cuenta servirá para iniciar sesión en '),
                            TextSpan(text: 'Respuestas Rápidas', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ', '),
                            TextSpan(text: 'Gestión', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ' y esta app'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Usuario',
                pista: 'Ej. Ana Torres',
                icono: Icons.person_outline,
                controller: _nombre,
                validator: (v) => Validadores.requerido(v, 'Usuario'),
              ),
              CampoTexto(
                etiqueta: 'Correo electrónico',
                pista: 'ejemplo@correo.com',
                icono: Icons.email_outlined,
                controller: _correo,
                teclado: TextInputType.emailAddress,
                validator: Validadores.correo,
              ),
              CampoTexto(
                etiqueta: 'Contraseña',
                pista: 'Mínimo 6 caracteres',
                icono: Icons.lock_outline,
                controller: _password,
                oculto: _ocultar,
                validator: Validadores.password,
                sufijo: ojo,
              ),
              CampoTexto(
                etiqueta: 'Confirmar contraseña',
                pista: 'Repite la contraseña',
                icono: Icons.lock_outline,
                controller: _confirmar,
                oculto: _ocultar,
                validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
              ),
              const Text('Rol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'staff', label: Text('Staff'), icon: Icon(Icons.badge_outlined)),
                  ButtonSegment(value: 'ADMIN', label: Text('Administrador'), icon: Icon(Icons.admin_panel_settings)),
                ],
                showSelectedIcon: false,
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _registrar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Registrar usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
