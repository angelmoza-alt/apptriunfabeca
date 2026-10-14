import { AppError } from '../../../shared/app-error.js';
import {
  ROLES,
  actualizarUsuario,
  cambiarEstado,
  cambiarMiPassword,
  crearUsuario,
  listarUsuarios,
  obtenerUsuario,
  resumenUsuarios,
  restablecerPassword,
} from './usuarios.service.js';

const CORREO_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MIN_PASSWORD = 6;

/** id del usuario autenticado (el JWT de auth.service guarda el id en "sub") */
const actorId = (req) => req.usuario?.sub ?? null;

const validarId = (id) => {
  if (!UUID_RE.test(String(id))) throw new AppError(400, 'Id de usuario inválido');
};

/** Normaliza y valida nombre / correo / role. parcial=true permite omitir campos. */
function leerDatos(body, { parcial = false } = {}) {
  const datos = {};
  const { nombre, correo, role } = body ?? {};

  if (nombre !== undefined || !parcial) {
    if (!nombre || !String(nombre).trim()) throw new AppError(400, 'El nombre es obligatorio');
    datos.nombre = String(nombre).trim();
  }
  if (correo !== undefined || !parcial) {
    const c = String(correo ?? '').trim().toLowerCase();
    if (!CORREO_RE.test(c)) throw new AppError(400, 'Correo electrónico no válido');
    datos.correo = c;
  }
  if (role !== undefined) {
    if (!ROLES.includes(role)) throw new AppError(400, `Rol no válido (usa: ${ROLES.join(', ')})`);
    datos.role = role;
  }
  return datos;
}

const validarPassword = (p, campo = 'La contraseña') => {
  if (!p || String(p).length < MIN_PASSWORD) {
    throw new AppError(400, `${campo} debe tener al menos ${MIN_PASSWORD} caracteres`);
  }
};

/** Traduce el error de correo duplicado de PostgreSQL a un mensaje claro */
const correoDuplicado = (error) => {
  if (error.code === '23505') return new AppError(409, 'Ya existe un usuario con ese correo');
  return error;
};

/* ---------- Rutas para cualquier usuario autenticado ---------- */

/** PUT /api/v1/admin/usuarios/me — editar mi nombre/correo */
export async function putMiPerfil(req, res, next) {
  try {
    const { nombre, correo } = req.body ?? {};
    const datos = leerDatos({ nombre, correo }, { parcial: true });
    if (!Object.keys(datos).length) throw new AppError(400, 'No hay cambios');
    const data = await actualizarUsuario(actorId(req), datos, actorId(req));
    if (!data) throw new AppError(404, 'Usuario no encontrado');
    res.json({ success: true, data, message: 'Datos actualizados' });
  } catch (error) {
    next(correoDuplicado(error));
  }
}

/** PUT /api/v1/admin/usuarios/me/password { actual, nueva } */
export async function putMiPassword(req, res, next) {
  try {
    const { actual, nueva } = req.body ?? {};
    if (!actual) throw new AppError(400, 'Ingresa tu contraseña actual');
    validarPassword(nueva, 'La nueva contraseña');
    const r = await cambiarMiPassword(actorId(req), String(actual), String(nueva));
    if (r === 'NO_ENCONTRADO') throw new AppError(404, 'Usuario no encontrado o inactivo');
    if (r === 'ACTUAL_INCORRECTA') throw new AppError(400, 'La contraseña actual no es correcta');
    res.json({ success: true, data: null, message: 'Contraseña actualizada' });
  } catch (error) {
    next(error);
  }
}

/* ---------- Rutas solo para ADMIN ---------- */

/** GET /api/v1/admin/usuarios?q=&role=&activo=true|false */
export async function getUsuarios(req, res, next) {
  try {
    const { q, role, activo } = req.query;
    if (role && !ROLES.includes(role)) throw new AppError(400, 'Rol no válido');
    const data = await listarUsuarios({
      q: q ? String(q).trim() : undefined,
      role,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined,
    });
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** GET /api/v1/admin/usuarios/resumen?desde=YYYY-MM-DD&hasta=YYYY-MM-DD */
export async function getResumen(req, res, next) {
  try {
    const hoy = new Date();
    const fecha = /^\d{4}-\d{2}-\d{2}$/;
    const desde = fecha.test(req.query.desde ?? '')
      ? req.query.desde
      : new Date(hoy.getFullYear(), hoy.getMonth() - 5, 1).toISOString().slice(0, 10);
    const hasta = fecha.test(req.query.hasta ?? '') ? req.query.hasta : hoy.toISOString().slice(0, 10);
    if (desde > hasta) throw new AppError(400, 'La fecha inicial no puede ser mayor que la final');
    const data = await resumenUsuarios(desde, hasta);
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** GET /api/v1/admin/usuarios/:id */
export async function getUsuario(req, res, next) {
  try {
    validarId(req.params.id);
    const data = await obtenerUsuario(req.params.id);
    if (!data) throw new AppError(404, 'Usuario no encontrado');
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

/** POST /api/v1/admin/usuarios { nombre, correo, password, role? } */
export async function postUsuario(req, res, next) {
  try {
    const datos = leerDatos(req.body);
    validarPassword(req.body?.password);
    const data = await crearUsuario(
      { ...datos, role: datos.role ?? 'staff', password: String(req.body.password) },
      actorId(req),
    );
    res.status(201).json({ success: true, data, message: 'Usuario creado' });
  } catch (error) {
    next(correoDuplicado(error));
  }
}

/** PUT /api/v1/admin/usuarios/:id { nombre?, correo?, role? } */
export async function putUsuario(req, res, next) {
  try {
    validarId(req.params.id);
    const datos = leerDatos(req.body, { parcial: true });
    if (!Object.keys(datos).length) throw new AppError(400, 'No hay cambios');
    // Evita que un admin se quite a sí mismo el rol y se quede sin acceso
    if (req.params.id === actorId(req) && datos.role && datos.role !== 'ADMIN') {
      throw new AppError(400, 'No puedes quitarte tu propio rol de administrador');
    }
    const data = await actualizarUsuario(req.params.id, datos, actorId(req));
    if (!data) throw new AppError(404, 'Usuario no encontrado');
    res.json({ success: true, data, message: 'Usuario actualizado' });
  } catch (error) {
    next(correoDuplicado(error));
  }
}

/** PATCH /api/v1/admin/usuarios/:id/estado { es_activo } */
export async function patchEstado(req, res, next) {
  try {
    validarId(req.params.id);
    const { es_activo: esActivo } = req.body ?? {};
    if (typeof esActivo !== 'boolean') throw new AppError(400, 'es_activo debe ser true o false');
    if (req.params.id === actorId(req) && !esActivo) {
      throw new AppError(400, 'No puedes desactivar tu propia cuenta');
    }
    const data = await cambiarEstado(req.params.id, esActivo, actorId(req));
    if (!data) throw new AppError(404, 'Usuario no encontrado');
    res.json({ success: true, data, message: esActivo ? 'Usuario activado' : 'Usuario desactivado' });
  } catch (error) {
    next(error);
  }
}

/** PUT /api/v1/admin/usuarios/:id/password { nueva } — el admin restablece la contraseña */
export async function putPasswordUsuario(req, res, next) {
  try {
    validarId(req.params.id);
    validarPassword(req.body?.nueva, 'La nueva contraseña');
    const data = await restablecerPassword(req.params.id, String(req.body.nueva), actorId(req));
    if (!data) throw new AppError(404, 'Usuario no encontrado');
    res.json({ success: true, data, message: 'Contraseña restablecida' });
  } catch (error) {
    next(error);
  }
}
