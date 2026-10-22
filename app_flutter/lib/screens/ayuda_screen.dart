import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Ayuda: manual y preguntas frecuentes con buscador en tiempo real.
class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> {
  String _busqueda = '';
  final _ctrl = TextEditingController();

  static const _preguntas = [
    ('Cuenta', '¿Qué es Triunfa Beca?',
        'Es una academia que prepara a estudiantes para Beca 18 y otras becas. Esta app sirve para que el equipo administre sus cuentas y su trabajo diario.'),
    ('Cuenta', '¿Con qué cuenta inicio sesión?',
        'Con tu correo y contraseña. Es la misma cuenta que usas en las páginas de Gestión y Respuestas Rápidas.'),
    ('Cuenta', '¿Cómo cambio mi contraseña?',
        '1. Ve a Mis datos o Configuración.\n2. Toca "Cambiar contraseña".\n3. Escribe tu contraseña actual y la nueva dos veces.\n4. Toca "Actualizar contraseña".'),
    ('Cuenta', 'Olvidé mi contraseña, ¿qué hago?',
        'Pide al administrador que la restablezca: él entra a Usuarios → tu usuario → "Restablecer contraseña".'),
    ('Cuenta', '¿Cómo actualizo mis datos?',
        'Ve a Mis datos → Información personal, toca "Editar datos", cambia lo que necesites y guarda.'),
    ('Usuarios', '¿Cómo registro a un nuevo usuario?',
        'Solo los administradores pueden hacerlo:\n1. En Inicio toca "Registrar nuevo usuario".\n2. Escribe usuario, correo y contraseña.\n3. Elige el rol (Staff o Administrador).\n4. Toca "Registrar usuario".\nCon ese correo y contraseña podrá entrar a la app, a Gestión y a Respuestas Rápidas.'),
    ('Usuarios', '¿Qué significa que una cuenta esté inactiva?',
        'Que esa persona no puede iniciar sesión en la app ni en las páginas web. El administrador puede activarla otra vez desde el detalle del usuario.'),
    ('Usuarios', '¿Qué diferencia hay entre Staff y Administrador?',
        'El Staff ve sus datos, notas, el asistente y la configuración. El Administrador además registra usuarios, los activa o desactiva y ve los reportes.'),
    ('Herramientas', '¿Cómo uso el Asistente IA?',
        'En Inicio toca "Asistente IA" y escribe lo que necesitas, por ejemplo: "redacta un aviso de Beca 18 para el 20 de marzo". Luego toca "Copiar para WhatsApp" y pégalo en el chat.'),
    ('Herramientas', '¿Para qué sirven las Notas?',
        'Para apuntar pendientes, llamadas o datos rápidos. Se guardan en tu celular y cada usuario tiene las suyas. Puedes buscarlas, editarlas y elegir un color.'),
    ('Herramientas', '¿Cómo genero un reporte en PDF?',
        '1. Abre Reportes.\n2. Elige el rango de fechas.\n3. Toca "Generar reporte".\n4. Elige "Ver / imprimir" o "Compartir PDF" para enviarlo por WhatsApp o correo.'),
    ('Configuración', '¿Cómo cambio el logo de la academia?',
        'Ve a Configuración → Logo de la academia → "Elegir de la galería". El nuevo logo aparecerá en el menú lateral, el inicio de sesión y el registro. Puedes volver al original con "Restablecer logo original".'),
    ('Configuración', '¿Cómo activo el modo oscuro?', 'En Configuración → Tema, elige "Oscuro".'),
    ('Configuración', '¿Cómo cambio el nombre de la sede?',
        'En Configuración → Sede. Ese nombre se usa en los mensajes que redacta el Asistente IA y en los reportes.'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _n(String s) {
    const con = 'áéíóúüñ', sin = 'aeiouun';
    var r = s.toLowerCase();
    for (var i = 0; i < con.length; i++) {
      r = r.replaceAll(con[i], sin[i]);
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final q = _n(_busqueda.trim());
    final visibles = _preguntas
        .where((p) => q.isEmpty || _n(p.$2).contains(q) || _n(p.$3).contains(q) || _n(p.$1).contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: Responsive.padding(context, maxAncho: 720, lateral: 16, arriba: 16),
        children: [
          const Text('¿En qué te ayudamos?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar: contraseña, PDF, logo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(children: [
                Icon(Icons.search_off, size: 56, color: AppColors.gris),
                SizedBox(height: 8),
                Text('No encontramos resultados', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Prueba con otra palabra', style: TextStyle(color: AppColors.gris)),
              ]),
            )
          else ...[
            Text('${visibles.length} pregunta(s)', style: const TextStyle(color: AppColors.gris, fontSize: 12)),
            const SizedBox(height: 6),
            for (final (categoria, pregunta, respuesta) in visibles)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  // Si hay búsqueda, se abren solas para ver la respuesta
                  key: ValueKey('$pregunta-${q.isNotEmpty}'),
                  initiallyExpanded: q.isNotEmpty && visibles.length <= 3,
                  leading: const Icon(Icons.help_outline, color: AppColors.morado),
                  title: Text(pregunta, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(categoria, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(respuesta, style: const TextStyle(height: 1.4))],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
