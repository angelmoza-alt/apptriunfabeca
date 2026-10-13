import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/api_service.dart';

/// Lista de usuarios con búsqueda y filtro por estado (pantalla Usuarios).
class UsuariosProvider extends ChangeNotifier {
  final ApiService api;
  UsuariosProvider(this.api);

  List<Usuario> usuarios = [];
  String busqueda = '';
  String? filtroEstado; // null = Todos
  bool cargando = false;
  String? error;
  Timer? _debounce;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      usuarios = await api.usuarios(busqueda: busqueda, estado: filtroEstado);
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

  void filtrar(String? estado) {
    filtroEstado = estado;
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
