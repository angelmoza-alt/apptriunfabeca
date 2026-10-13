class Validadores {
  static String? requerido(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? '$campo es obligatorio' : null;

  static String? dni(String? v) {
    if (v == null || v.trim().isEmpty) return 'DNI es obligatorio';
    if (!RegExp(r'^\d{8}$').hasMatch(v.trim())) return 'El DNI debe tener 8 dígitos';
    return null;
  }

  static String? correo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Correo es obligatorio';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) return 'Correo no válido';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Contraseña es obligatoria';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
