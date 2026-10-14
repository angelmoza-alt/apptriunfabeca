import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/usuarios_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// 8. Usuarios: búsqueda, filtros por estado y acceso al detalle
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _buscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<UsuariosProvider>();
    _buscador.text = p.busqueda;
    WidgetsBinding.instance.addPostFrameCallback((_) => p.cargar());
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsuariosProvider>();
    const filtros = <(FiltroUsuarios, String)>[
      (FiltroUsuarios.todos, 'Todos'),
      (FiltroUsuarios.activos, 'Activos'),
      (FiltroUsuarios.inactivos, 'Inactivos'),
      (FiltroUsuarios.admins, 'Admin'),
      (FiltroUsuarios.staff, 'Staff'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            tooltip: 'Registrar usuario',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => Navigator.pushNamed(context, Rutas.registro),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: Responsive.padding(context, maxAncho: 760, lateral: 16, arriba: 16, abajo: 8),
            child: TextField(
              controller: _buscador,
              onChanged: p.buscar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscador.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscador.clear();
                          p.buscar('');
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (valor, texto) in filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: ChoiceChip(
                      label: Text(texto, style: const TextStyle(fontSize: 12.5)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      selected: p.filtro == valor,
                      selectedColor: AppColors.azul,
                      labelStyle: TextStyle(color: p.filtro == valor ? Colors.white : null),
                      showCheckmark: false,
                      onSelected: (_) => p.filtrar(valor),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _lista(p)),
        ],
      ),
    );
  }

  Widget _lista(UsuariosProvider p) {
    if (p.cargando && p.usuarios.isEmpty) return const Center(child: CircularProgressIndicator());
    if (p.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(p.error!, textAlign: TextAlign.center)),
          TextButton(onPressed: p.cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    if (p.usuarios.isEmpty) return const Center(child: Text('No se encontraron usuarios'));

    return RefreshIndicator(
      onRefresh: p.cargar,
      child: ListView.separated(
        padding: Responsive.padding(context, maxAncho: 760, lateral: 16, arriba: 8),
        itemCount: p.usuarios.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = p.usuarios[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: AvatarUsuario(usuario: u),
            title: Text(u.nombre,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(u.correo, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  EstadoBadge(u.esActivo),
                  const SizedBox(height: 4),
                  RolBadge(u.esAdmin),
                ],
              ),
              const Icon(Icons.chevron_right),
            ]),
            onTap: () async {
              await Navigator.pushNamed(context, Rutas.detalleUsuario, arguments: u.id);
              p.cargar(); // por si cambió el estado y ya no coincide con el filtro
            },
          );
        },
      ),
    );
  }
}
