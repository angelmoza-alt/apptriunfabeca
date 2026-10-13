import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Ayuda: preguntas frecuentes
class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  static const _preguntas = [
    ('¿Qué es Triunfa Beca?',
        'Es una plataforma que conecta a estudiantes con oportunidades de becas y ayudas educativas, y los acompaña en su preparación.'),
    ('¿Cómo actualizo mis datos?',
        'Ve a Mis datos → Información personal y presiona "Editar datos". Luego guarda los cambios.'),
    ('Olvidé mi contraseña, ¿qué hago?',
        'Por ahora debes comunicarte con el administrador de Triunfa Beca para que te ayude a recuperarla.'),
    ('¿Qué significa el estado de mi cuenta?',
        'Activo: tu cuenta está habilitada. En proceso: tu solicitud está en revisión. Inactivo o Rechazado: comunícate con el administrador.'),
    ('¿Cómo activo el modo oscuro?', 'En Configuración → Tema, elige "Oscuro".'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: Responsive.padding(context, maxAncho: 720, lateral: 16, arriba: 16),
        children: [
          const Text('Preguntas frecuentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final (p, r) in _preguntas)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline, color: AppColors.morado),
                title: Text(p, style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(r)],
              ),
            ),
        ],
      ),
    );
  }
}
