import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/config_provider.dart';
import '../providers/usuarios_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 2. Registrar usuario.
/// - Sin sesión: "Crea tu cuenta" y entra directo a la app.
/// - Con sesión (admin desde Inicio o Usuarios): crea otro usuario y vuelve.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apPaterno = TextEditingController();
  final _apMaterno = TextEditingController();
  final _dni = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombres, _apPaterno, _apMaterno, _dni, _correo, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final datos = {
      'nombres': _nombres.text.trim(),
      'apellidoPaterno': _apPaterno.text.trim(),
      'apellidoMaterno': _apMaterno.text.trim(),
      'dni': _dni.text.trim(),
      'correo': _correo.text.trim(),
      'password': _password.text,
    };
    setState(() => _guardando = true);
    try {
      if (auth.haySesion) {
        final nuevo = await auth.registrarOtro(datos);
        if (!mounted) return;
        context.read<UsuariosProvider>().cargar();
        mostrarMensaje(context, 'Usuario ${nuevo.nombreCorto} registrado');
        Navigator.pop(context, true);
      } else {
        final config = context.read<ConfigProvider>();
        await auth.registrarYEntrar(datos);
        config.reiniciar();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (_) => false);
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final haySesion = context.read<AuthProvider>().haySesion;
    final campoNombres = CampoTexto(
      etiqueta: 'Nombres',
      pista: 'Ej. Ana',
      icono: Icons.person_outline,
      controller: _nombres,
      validator: (v) => Validadores.requerido(v, 'Nombres'),
    );
    final campoApPaterno = CampoTexto(
      etiqueta: 'Apellido paterno',
      pista: 'Ej. Torres',
      icono: Icons.person_outline,
      controller: _apPaterno,
      validator: (v) => Validadores.requerido(v, 'Apellido paterno'),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar nuevo usuario')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context, maxAncho: 560),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Logo(ancho: 120, soloIcono: true)),
              const SizedBox(height: 8),
              Text(
                haySesion ? 'Registra a un estudiante' : 'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.gris),
              ),
              const SizedBox(height: 20),
              const Text('Nombre completo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.azul)),
              const SizedBox(height: 8),
              if (Responsive.esAngosto(context)) ...[
                campoNombres,
                campoApPaterno,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: campoNombres),
                    const SizedBox(width: 10),
                    Expanded(child: campoApPaterno),
                  ],
                ),
              CampoTexto(
                etiqueta: 'Apellido materno',
                pista: 'Ej. García',
                icono: Icons.person_outline,
                controller: _apMaterno,
                validator: (v) => Validadores.requerido(v, 'Apellido materno'),
              ),
              CampoTexto(
                etiqueta: 'DNI',
                pista: 'Ej. 76543210',
                icono: Icons.badge_outlined,
                controller: _dni,
                teclado: TextInputType.number,
                maxLength: 8,
                validator: Validadores.dni,
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
                pista: 'Crear contraseña (mín. 6)',
                icono: Icons.lock_outline,
                controller: _password,
                oculto: _ocultar,
                validator: Validadores.password,
                sufijo: IconButton(
                  icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _registrar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Registrar usuario'),
              ),
              if (!haySesion) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes una cuenta?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
