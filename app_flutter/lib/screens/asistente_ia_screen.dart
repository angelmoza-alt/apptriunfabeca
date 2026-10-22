import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';

/// Mensaje del chat. [plantilla] es el texto listo para copiar (WhatsApp).
class _Mensaje {
  final String texto;
  final bool esUsuario;
  final String? plantilla;
  _Mensaje(this.texto, {this.esUsuario = false, this.plantilla});
}

/// Asistente IA: ayuda al staff a redactar mensajes de WhatsApp, avisos y
/// plantillas para Beca 18. Funciona con reglas de palabras clave (sin internet),
/// igual que en la versión Swift.
class AsistenteIAScreen extends StatefulWidget {
  const AsistenteIAScreen({super.key});

  @override
  State<AsistenteIAScreen> createState() => _AsistenteIAScreenState();
}

class _AsistenteIAScreenState extends State<AsistenteIAScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Mensaje> _mensajes = [];
  bool _escribiendo = false;

  static const _sugerencias = [
    'Redacta un aviso por WhatsApp del cierre de inscripciones de Beca 18 el 20 de marzo',
    'Mensaje de bienvenida para un nuevo estudiante',
    'Requisitos para postular a Beca 18',
    'Recordatorio de clase para mañana',
    'Horarios de la academia',
  ];

  @override
  void initState() {
    super.initState();
    final nombre = context.read<AuthProvider>().usuario?.nombre.split(' ').first ?? '';
    _mensajes.add(_Mensaje(
      '¡Hola${nombre.isEmpty ? '' : ', $nombre'}! 👋 Soy el asistente de Triunfa Beca.\n\n'
      'Te ayudo a redactar mensajes para WhatsApp, redes y avisos de convocatoria. '
      'Escríbeme lo que necesitas o toca una sugerencia.',
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? texto]) async {
    final consulta = (texto ?? _ctrl.text).trim();
    if (consulta.isEmpty || _escribiendo) return;
    _ctrl.clear();
    setState(() {
      _mensajes.add(_Mensaje(consulta, esUsuario: true));
      _escribiendo = true;
    });
    _bajar();
    await Future.delayed(const Duration(milliseconds: 700)); // simula que "piensa"
    if (!mounted) return;
    final sede = context.read<ConfigProvider>().sede;
    setState(() {
      _mensajes.add(responder(consulta, sede: sede));
      _escribiendo = false;
    });
    _bajar();
  }

  /// Scroll automático al último mensaje
  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: 20),
          SizedBox(width: 8),
          Text('Asistente IA'),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              itemCount: _mensajes.length + (_escribiendo ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _mensajes.length) return const _Burbuja.escribiendo();
                return _Burbuja(mensaje: _mensajes[i]);
              },
            ),
          ),
          // Sugerencias rápidas
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final s in _sugerencias)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(s.length > 34 ? '${s.substring(0, 34)}…' : s, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _enviar(s),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _enviar(),
                    decoration: InputDecoration(
                      hintText: 'Ej. redacta un aviso de Beca 18...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _escribiendo ? null : () => _enviar(),
                  style: IconButton.styleFrom(backgroundColor: AppColors.azul),
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final _Mensaje? mensaje;
  const _Burbuja({required _Mensaje this.mensaje});
  const _Burbuja.escribiendo() : mensaje = null;

  @override
  Widget build(BuildContext context) {
    final m = mensaje;
    final esUsuario = m?.esUsuario ?? false;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = esUsuario ? AppColors.azul : (oscuro ? const Color(0xFF1B2547) : Colors.white);
    final colorTexto = esUsuario ? Colors.white : null;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(esUsuario ? 16 : 4),
              bottomRight: Radius.circular(esUsuario ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: m == null
              ? const Text('Escribiendo…', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.gris))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.texto, style: TextStyle(color: colorTexto, height: 1.35)),
                    if (m.plantilla != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.verdeClaro,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.verde.withOpacity(0.4)),
                        ),
                        child: SelectableText('"${m.plantilla}"',
                            style: const TextStyle(color: Color(0xFF14532D), height: 1.35)),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: m.plantilla!));
                            if (context.mounted) mostrarMensaje(context, 'Mensaje copiado. Pégalo en WhatsApp');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copiar para WhatsApp'),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Reglas de redacción automática (palabras clave → plantilla)
// ----------------------------------------------------------------------------

String _normalizar(String s) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  var r = s.toLowerCase();
  for (var i = 0; i < con.length; i++) {
    r = r.replaceAll(con[i], sin[i]);
  }
  return r;
}

bool _tiene(String q, List<String> palabras) => palabras.any(q.contains);

/// Genera la respuesta del asistente para una consulta.
_Mensaje responder(String consulta, {String sede = 'Sede principal'}) {
  final q = _normalizar(consulta);
  final pideRedaccion = _tiene(q, ['whatsapp', 'mensaje', 'redacta', 'escribe', 'aviso', 'comunicado', 'plantilla']);
  final beca18 = _tiene(q, ['beca 18', 'beca18', 'pronabec']);

  // 1. Cierre de inscripciones de Beca 18 (20 de marzo)
  if (_tiene(q, ['20 de marzo', '20 marzo']) ||
      (beca18 && _tiene(q, ['cierre', 'inscrip', 'convocatoria', 'plazo', 'ultimo dia']))) {
    return _Mensaje(
      'Aquí tienes un aviso listo para enviar por WhatsApp sobre el cierre de inscripciones de Beca 18:',
      plantilla: '📢 *¡ÚLTIMOS DÍAS! Beca 18* 🎓\n\n'
          'Hola 👋, te recordamos que el *20 de marzo* cierran las inscripciones para *Beca 18*.\n\n'
          '✅ Prepárate con nosotros: simulacros semanales, asesoría personalizada y acompañamiento en tu postulación.\n\n'
          '📍 Triunfa Beca – $sede\n'
          '📲 Escríbenos por este medio para reservar tu vacante.\n\n'
          '¡No dejes pasar tu oportunidad! 💪 #TriunfaBeca',
    );
  }

  // 2. Requisitos de Beca 18
  if (beca18 && _tiene(q, ['requisito', 'necesito', 'documento', 'postular'])) {
    return _Mensaje(
      'Te dejo un mensaje con los requisitos principales de Beca 18:',
      plantilla: '🎓 *Requisitos para postular a Beca 18*\n\n'
          '1️⃣ Haber culminado 5° de secundaria (o estar cursándolo).\n'
          '2️⃣ Alto rendimiento académico.\n'
          '3️⃣ Clasificación socioeconómica (SISFOH) de pobreza o pobreza extrema.\n'
          '4️⃣ DNI vigente.\n\n'
          'En Triunfa Beca te preparamos para el Examen Nacional de Preselección con simulacros semanales. '
          '¿Quieres que te reservemos una vacante? 😊',
    );
  }

  // 3. Bienvenida
  if (_tiene(q, ['bienvenida', 'bienvenido', 'nuevo estudiante', 'nueva estudiante'])) {
    return _Mensaje(
      'Este mensaje de bienvenida puedes enviarlo apenas se matricule el estudiante:',
      plantilla: '¡Hola! 👋 Te damos la bienvenida a *Triunfa Beca* – $sede 🎉\n\n'
          'Estamos felices de acompañarte en tu preparación. Aquí recibirás avisos de clases, simulacros y '
          'novedades de las becas.\n\n'
          'Cualquier duda, escríbenos por aquí. ¡Tu esfuerzo, nuestro apoyo! 💙',
    );
  }

  // 4. Recordatorio de clase
  if (_tiene(q, ['recordatorio', 'recordar', 'clase', 'simulacro'])) {
    final simulacro = q.contains('simulacro');
    return _Mensaje(
      'Aquí tienes un recordatorio. Cambia la hora si es necesario:',
      plantilla: '⏰ *Recordatorio Triunfa Beca*\n\n'
          'Hola 👋, te recordamos que mañana tenemos ${simulacro ? '*simulacro*' : '*clase*'} a las *3:00 p. m.* '
          'en $sede.\n\n'
          '📝 Trae tu cuaderno, lapicero y DNI.\n'
          '¡Te esperamos puntual! 💪',
    );
  }

  // 5. Horarios
  if (_tiene(q, ['horario', 'turno', 'hora'])) {
    return _Mensaje(
      'Puedes responder así cuando pregunten por los horarios:',
      plantilla: '🕒 *Horarios de Triunfa Beca* – $sede\n\n'
          '🌅 Mañana: 8:30 a. m. – 12:00 m.\n'
          '🌇 Tarde: 3:00 p. m. – 6:00 p. m.\n\n'
          'Atendemos de lunes a sábado. ¿En qué turno te gustaría estudiar? 😊',
    );
  }

  // 6. Información general de Beca 18
  if (beca18) {
    return _Mensaje(
      'Este mensaje presenta la preparación para Beca 18:',
      plantilla: '🎓 *Prepárate para Beca 18 con Triunfa Beca*\n\n'
          'Beca 18 financia tus estudios superiores completos. En Triunfa Beca te preparamos con:\n'
          '✅ Simulacros semanales del examen\n✅ Asesoría en tu postulación\n✅ Docentes especializados\n\n'
          '📲 Escríbenos para más información. ¡Tú puedes! 💪',
    );
  }

  // 7. Pedido de redacción genérico
  if (pideRedaccion) {
    return _Mensaje(
      'Te preparé un mensaje base. Cuéntame el tema (Beca 18, horarios, clase, bienvenida…) y lo ajusto:',
      plantilla: 'Hola 👋, te saludamos de *Triunfa Beca* – $sede.\n\n'
          '[Escribe aquí tu aviso]\n\n'
          'Cualquier consulta, escríbenos por este medio. ¡Gracias! 💙',
    );
  }

  // 8. No entendió
  return _Mensaje(
    'Puedo ayudarte a redactar:\n'
    '• Avisos de Beca 18 (por ejemplo, el cierre del 20 de marzo)\n'
    '• Requisitos para postular\n'
    '• Mensajes de bienvenida\n'
    '• Recordatorios de clase o simulacro\n'
    '• Horarios de la academia\n\n'
    'Prueba escribiendo: "redacta un mensaje de WhatsApp sobre Beca 18".',
  );
}
