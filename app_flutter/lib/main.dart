import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/config_provider.dart';
import 'providers/usuarios_provider.dart';
import 'screens/ayuda_screen.dart';
import 'screens/cambiar_password_screen.dart';
import 'screens/configuracion_screen.dart';
import 'screens/datos_personales_screen.dart';
import 'screens/detalle_usuario_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/mis_datos_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/usuarios_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService(); // una sola instancia compartida (guarda el token)

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider(create: (_) => ConfigProvider(api)..cargarLocal()),
        ChangeNotifierProvider(create: (_) => UsuariosProvider(api)),
      ],
      child: const TriunfaBecaApp(),
    ),
  );
}

class Rutas {
  static const splash = '/';
  static const login = '/login';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const misDatos = '/mis-datos';
  static const datosPersonales = '/datos-personales';
  static const detalleUsuario = '/detalle-usuario';
  static const reportes = '/reportes';
  static const usuarios = '/usuarios';
  static const configuracion = '/configuracion';
  static const cambiarPassword = '/cambiar-password';
  static const ayuda = '/ayuda';
}

class TriunfaBecaApp extends StatelessWidget {
  const TriunfaBecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    return MaterialApp(
      title: 'Triunfa Beca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      themeMode: config.themeMode,
      // Respeta el tamaño de letra del celular, pero con un límite para que no rompa el diseño
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3)),
          child: child!,
        );
      },
      initialRoute: Rutas.splash,
      routes: {
        Rutas.splash: (_) => const SplashScreen(),
        Rutas.login: (_) => const LoginScreen(),
        Rutas.registro: (_) => const RegistroScreen(),
        Rutas.inicio: (_) => const MainShell(),
        Rutas.misDatos: (_) => const MisDatosScreen(),
        Rutas.datosPersonales: (_) => const DatosPersonalesScreen(),
        Rutas.detalleUsuario: (_) => const DetalleUsuarioScreen(),
        Rutas.reportes: (_) => const ReportesScreen(),
        Rutas.usuarios: (_) => const UsuariosScreen(),
        Rutas.configuracion: (_) => const ConfiguracionScreen(),
        Rutas.cambiarPassword: (_) => const CambiarPasswordScreen(),
        Rutas.ayuda: (_) => const AyudaScreen(),
      },
    );
  }
}
