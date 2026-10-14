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
      final accion = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DialogoUsuarioCreado(
          nombre: nuevo.nombre,
          correo: nuevo.correo,
          rol: nuevo.rolTexto,
        ),
      );
      if (!mounted) return;
      if (accion == 'otro') {
        // Limpia el formulario para registrar a alguien más
        _form.currentState!.reset();
        for (final c in [_nombre, _correo, _password, _confirmar]) {
          c.clear();
        }
        setState(() => _role = 'staff');
      } else {
        Navigator.pop(context, true);
      }
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

/// Mensaje de éxito al crear un usuario (con el estilo de la app)
class _DialogoUsuarioCreado extends StatelessWidget {
  final String nombre, correo, rol;
  const _DialogoUsuarioCreado({required this.nombre, required this.correo, required this.rol});

  @override
  Widget build(BuildContext context) {
    Widget fila(IconData icono, String etiqueta, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(icono, size: 18, color: AppColors.azul),
            const SizedBox(width: 8),
            SizedBox(width: 62, child: Text(etiqueta, style: const TextStyle(fontSize: 12.5, color: AppColors.gris))),
            Expanded(
              child: Text(valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ]),
        );

    Widget acceso(IconData icono, String texto) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: AppColors.rojoClaro, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Icon(icono, color: AppColors.rojo, size: 20),
              const SizedBox(height: 2),
              Text(texto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.rojo)),
            ]),
          ),
        );

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera azul con el check
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.azulOscuro, AppColors.azul]),
                ),
                child: Column(children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.verde, size: 38),
                  ),
                  const SizedBox(height: 10),
                  const Text('¡Usuario creado!',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('La cuenta ya está activa',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.azulClaro.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      fila(Icons.person_outline, 'Usuario', nombre),
                      fila(Icons.email_outlined, 'Correo', correo),
                      fila(Icons.verified_user_outlined, 'Rol', rol),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  const Text('Puede iniciar sesión en:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    acceso(Icons.bolt, 'Respuestas\nRápidas'),
                    const SizedBox(width: 8),
                    acceso(Icons.dashboard, 'Gestión'),
                    const SizedBox(width: 8),
                    acceso(Icons.smartphone, 'App\nTriunfa Beca'),
                  ]),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Icon(Icons.info_outline, size: 15, color: AppColors.gris),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text('Entrega al usuario su correo y la contraseña que asignaste.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.gris)),
                    ),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, 'otro'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: AppColors.azul,
                        side: const BorderSide(color: AppColors.azul),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Crear otro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'listo'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      child: const Text('Listo'),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
