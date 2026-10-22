import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/comunes.dart';

/// Nota personal del usuario (se guarda en el celular)
class Nota {
  final String id;
  final String titulo;
  final String contenido;
  final DateTime fecha;
  final int color; // índice de la paleta

  Nota({required this.id, required this.titulo, required this.contenido, required this.fecha, this.color = 0});

  factory Nota.fromJson(Map<String, dynamic> j) => Nota(
        id: j['id'],
        titulo: j['titulo'] ?? '',
        contenido: j['contenido'] ?? '',
        fecha: DateTime.tryParse(j['fecha'] ?? '') ?? DateTime.now(),
        color: j['color'] ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'titulo': titulo, 'contenido': contenido, 'fecha': fecha.toIso8601String(), 'color': color};
}

const _paleta = [
  (AppColors.azulClaro, AppColors.azul),
  (AppColors.verdeClaro, AppColors.verde),
  (AppColors.naranjaClaro, AppColors.naranja),
  (AppColors.moradoClaro, AppColors.morado),
  (AppColors.rojoClaro, AppColors.rojo),
];

/// Pestaña "Notas": apuntes rápidos del usuario (cada usuario tiene las suyas).
class NotasScreen extends StatefulWidget {
  final bool enPestana;
  const NotasScreen({super.key, this.enPestana = false});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  List<Nota> _notas = [];
  String _busqueda = '';
  bool _cargando = true;

  String get _clave => 'notas_${context.read<AuthProvider>().usuario?.id ?? 'local'}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    final texto = p.getString(_clave);
    final lista = texto == null
        ? <Nota>[]
        : (jsonDecode(texto) as List).map((e) => Nota.fromJson(Map<String, dynamic>.from(e))).toList();
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    if (mounted) {
      setState(() {
        _notas = lista;
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_clave, jsonEncode(_notas.map((n) => n.toJson()).toList()));
  }

  Future<void> _editar([Nota? nota]) async {
    final resultado = await showModalBottomSheet<Nota>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditorNota(nota: nota),
    );
    if (resultado == null) return;
    setState(() {
      _notas.removeWhere((n) => n.id == resultado.id);
      _notas.insert(0, resultado);
    });
    await _guardar();
    if (mounted) mostrarMensaje(context, nota == null ? 'Nota guardada' : 'Nota actualizada');
  }

  Future<void> _eliminar(Nota nota) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text('¿Eliminar "${nota.titulo.isEmpty ? 'Sin título' : nota.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.rojo)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _notas.removeWhere((n) => n.id == nota.id));
    await _guardar();
  }

  String _fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} '
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.toLowerCase();
    final visibles = _notas
        .where((n) => q.isEmpty || n.titulo.toLowerCase().contains(q) || n.contenido.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notas'), automaticallyImplyLeading: !widget.enPestana),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: Responsive.padding(context, maxAncho: 640, lateral: 16, arriba: 16, abajo: 90),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar en mis notas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                if (_notas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Column(children: [
                      Icon(Icons.sticky_note_2_outlined, size: 64, color: AppColors.gris),
                      SizedBox(height: 12),
                      Text('Aún no tienes notas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Toca "Nueva nota" para apuntar pendientes,\nllamadas o datos de los estudiantes.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris)),
                    ]),
                  )
                else if (visibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('No hay notas que coincidan')),
                  )
                else
                  for (final n in visibles) _tarjeta(n),
              ],
            ),
    );
  }

  Widget _tarjeta(Nota n) {
    final (fondo, color) = _paleta[n.color % _paleta.length];
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: oscuro ? color.withOpacity(0.15) : fondo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _editar(n),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 4, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.titulo.isEmpty ? 'Sin título' : n.titulo,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (n.contenido.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(n.contenido, maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Text(_fecha(n.fecha), style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline, color: AppColors.gris),
                  onPressed: () => _eliminar(n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulario para crear o editar una nota
class _EditorNota extends StatefulWidget {
  final Nota? nota;
  const _EditorNota({this.nota});

  @override
  State<_EditorNota> createState() => _EditorNotaState();
}

class _EditorNotaState extends State<_EditorNota> {
  late final _titulo = TextEditingController(text: widget.nota?.titulo ?? '');
  late final _contenido = TextEditingController(text: widget.nota?.contenido ?? '');
  late int _color = widget.nota?.color ?? 0;

  @override
  void dispose() {
    _titulo.dispose();
    _contenido.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_titulo.text.trim().isEmpty && _contenido.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      Nota(
        id: widget.nota?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        titulo: _titulo.text.trim(),
        contenido: _contenido.text.trim(),
        fecha: DateTime.now(),
        color: _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.nota == null ? 'Nueva nota' : 'Editar nota',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _titulo,
            autofocus: widget.nota == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Título'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contenido,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Escribe tu nota...'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              for (var i = 0; i < _paleta.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _paleta[i].$2,
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == i ? Colors.black87 : Colors.transparent, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _guardar, icon: const Icon(Icons.save), label: const Text('Guardar')),
        ],
      ),
    );
  }
}
