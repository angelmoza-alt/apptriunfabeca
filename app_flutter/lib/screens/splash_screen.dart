import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';

/// 1. Splash: muestra el logo y decide a dónde ir
/// (si hay sesión guardada → Inicio, si no → Login)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final auth = context.read<AuthProvider>();
    final results = await Future.wait([
      auth.restaurarSesion(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);
    final haySesion = results[0] as bool;
    if (!mounted) return;
    if (haySesion) {
      Navigator.pushReplacementNamed(context, Rutas.inicio);
    } else {
      Navigator.pushReplacementNamed(context, Rutas.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(bottom: 0, left: 0, right: 0, child: Ondas(alto: 150)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Logo(ancho: 260),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu esfuerzo, nuestro apoyo',
                    style: TextStyle(fontSize: 16, color: AppColors.azulOscuro, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conectamos estudiantes con oportunidades de becas y ayudas educativas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gris),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.azul),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
