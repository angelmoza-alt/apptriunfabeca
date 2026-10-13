import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// Iniciar sesión (no estaba en el diseño, pero el flujo lo necesita)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final config = context.read<ConfigProvider>();
    try {
      await auth.login(_correo.text.trim(), _password.text);
      await config.cargarDelServidor();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (_) => false);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<AuthProvider>().cargando;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 110)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: Responsive.padding(context, maxAncho: 440, lateral: 24, arriba: 24, abajo: 120),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: Logo(ancho: 220)),
                      const SizedBox(height: 24),
                      const Text('Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Ingresa con tu correo y contraseña',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris)),
                      const SizedBox(height: 24),
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
                        pista: 'Tu contraseña',
                        icono: Icons.lock_outline,
                        controller: _password,
                        oculto: _ocultar,
                        validator: (v) => Validadores.requerido(v, 'Contraseña'),
                        sufijo: IconButton(
                          icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: cargando ? null : _entrar,
                        icon: cargando
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login),
                        label: const Text('Ingresar'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?'),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, Rutas.registro),
                            child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
