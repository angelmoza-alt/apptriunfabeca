import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';

/// Filtros de la pantalla Usuarios
enum FiltroUsuarios { todos, activos, inactivos, admins, staff }

/// Lista de usuarios con búsqueda y filtros (pantalla Usuarios, solo admin).
class UsuariosProvider extends ChangeNotifier {
  final ApiService api;
  UsuariosProvider(this.api);

  List<Usuario> usuarios = [];
  String busqueda = '';
  FiltroUsuarios filtro = FiltroUsuarios.todos;
  bool cargando = false;
  String? error;
  Timer? _debounce;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      usuarios = await api.usuarios(
        busqueda: busqueda,
        activo: switch (filtro) {
          FiltroUsuarios.activos => true,
          FiltroUsuarios.inactivos => false,
          _ => null,
        },
        role: switch (filtro) {
          FiltroUsuarios.admins => 'ADMIN',
          FiltroUsuarios.staff => 'staff',
          _ => null,
        },
      );
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void buscar(String texto) {
    busqueda = texto;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), cargar);
  }

  void filtrar(FiltroUsuarios f) {
    filtro = f;
    cargar();
  }

  /// Reemplaza un usuario en la lista después de editarlo
  void actualizarEnLista(Usuario u) {
    final i = usuarios.indexWhere((x) => x.id == u.id);
    if (i != -1) {
      usuarios[i] = u;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
