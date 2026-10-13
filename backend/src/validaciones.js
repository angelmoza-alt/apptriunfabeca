const CORREO_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DNI_RE = /^\d{8}$/;

// Valida los datos personales. parcial = true permite omitir campos (para editar)
function validarDatos(d, { parcial = false, conPassword = false } = {}) {
  const errores = [];
  const req = (campo, etiqueta) => {
    if (!parcial || d[campo] !== undefined) {
      if (!d[campo] || String(d[campo]).trim() === '') errores.push(`${etiqueta} es obligatorio`);
    }
  };
  req('nombres', 'Nombres');
  req('apellidoPaterno', 'Apellido paterno');
  req('apellidoMaterno', 'Apellido materno');
  req('dni', 'DNI');
  req('correo', 'Correo');

  if (d.dni !== undefined && d.dni !== '' && !DNI_RE.test(String(d.dni))) {
    errores.push('El DNI debe tener 8 dígitos');
  }
  if (d.correo !== undefined && d.correo !== '' && !CORREO_RE.test(String(d.correo))) {
    errores.push('Correo electrónico no válido');
  }
  if (conPassword && (!d.password || String(d.password).length < 6)) {
    errores.push('La contraseña debe tener al menos 6 caracteres');
  }
  return errores;
}

module.exports = { validarDatos };
