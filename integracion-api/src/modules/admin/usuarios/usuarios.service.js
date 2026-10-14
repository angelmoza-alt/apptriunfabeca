import bcrypt from 'bcryptjs';
import { query } from '../../../config/database.js';
import { registrarAuditoria } from '../auditoria/auditoria.service.js';

/** Roles válidos en la tabla usuarios (mismos que usa requireRole en la API) */
export const ROLES = ['ADMIN', 'staff'];

const CAMPOS = `id, nombre, correo, role, es_activo, fecha_creacion`;

const auditar = (usuarioId, accion, usuario, descripcion, detalle = {}) =>
  registrarAuditoria({
    usuarioId,
    accion,
    entidad: 'USUARIO',
    entidadId: usuario.id,
    descripcion,
    detalle,
  }).catch((err) => console.error('[auditoria] no se pudo registrar:', err.message));

/** Lista usuarios con búsqueda por nombre/correo y filtros por rol y estado */
export async function listarUsuarios({ q, role, activo } = {}) {
  const condiciones = [];
  const params = [];

  if (q) {
    params.push(`%${q}%`);
    condiciones.push(`(nombre ILIKE $${params.length} OR correo ILIKE $${params.length})`);
  }
  if (role) {
    params.push(role);
    condiciones.push(`role = $${params.length}`);
  }
  if (activo === true || activo === false) {
    params.push(activo);
    condiciones.push(`es_activo = $${params.length}`);
  }

  const where = condiciones.length ? `WHERE ${condiciones.join(' AND ')}` : '';
  const { rows } = await query(
    `SELECT ${CAMPOS} FROM usuarios ${where} ORDER BY fecha_creacion DESC`,
    params,
  );
  return rows;
}

export async function obtenerUsuario(id) {
  const { rows } = await query(`SELECT ${CAMPOS} FROM usuarios WHERE id = $1`, [id]);
  return rows[0] ?? null;
}

/**
 * Crea un usuario. La contraseña se guarda con bcrypt (10 rondas),
 * igual que seed-admin.js, para que funcione en el login del panel admin.
 */
export async function crearUsuario({ nombre, correo, password, role }, actorId) {
  const passwordHash = await bcrypt.hash(password, 10);
  const { rows } = await query(
    `INSERT INTO usuarios (nombre, correo, password_hash, role, es_activo)
     VALUES ($1, $2, $3, $4, true)
     RETURNING ${CAMPOS}`,
    [nombre, correo, passwordHash, role],
  );
  const usuario = rows[0];
  await auditar(actorId, 'CREAR', usuario, `Creó el usuario ${usuario.correo}`, { role });
  return usuario;
}

/** Actualiza nombre, correo y/o rol (solo los campos enviados) */
export async function actualizarUsuario(id, cambios, actorId) {
  const sets = [];
  const params = [];
  for (const campo of ['nombre', 'correo', 'role']) {
    if (cambios[campo] !== undefined) {
      params.push(cambios[campo]);
      sets.push(`${campo} = $${params.length}`);
    }
  }
  if (!sets.length) return obtenerUsuario(id);

  params.push(id);
  const { rows } = await query(
    `UPDATE usuarios SET ${sets.join(', ')} WHERE id = $${params.length} RETURNING ${CAMPOS}`,
    params,
  );
  const usuario = rows[0] ?? null;
  if (usuario) {
    await auditar(actorId, 'EDITAR', usuario, `Editó el usuario ${usuario.correo}`, {
      campos: Object.keys(cambios),
    });
  }
  return usuario;
}

/** Activa o desactiva (baja lógica): un usuario inactivo no puede iniciar sesión */
export async function cambiarEstado(id, esActivo, actorId) {
  const { rows } = await query(
    `UPDATE usuarios SET es_activo = $1 WHERE id = $2 RETURNING ${CAMPOS}`,
    [esActivo, id],
  );
  const usuario = rows[0] ?? null;
  if (usuario) {
    await auditar(
      actorId,
      esActivo ? 'ACTIVAR' : 'DESACTIVAR',
      usuario,
      `${esActivo ? 'Activó' : 'Desactivó'} el usuario ${usuario.correo}`,
    );
  }
  return usuario;
}

/** El administrador asigna una nueva contraseña a otro usuario */
export async function restablecerPassword(id, nueva, actorId) {
  const hash = await bcrypt.hash(nueva, 10);
  const { rows } = await query(
    `UPDATE usuarios SET password_hash = $1 WHERE id = $2 RETURNING ${CAMPOS}`,
    [hash, id],
  );
  const usuario = rows[0] ?? null;
  if (usuario) {
    await auditar(actorId, 'RESTABLECER_PASSWORD', usuario, `Restableció la contraseña de ${usuario.correo}`);
  }
  return usuario;
}

/** Cualquier usuario cambia su propia contraseña (pide la actual) */
export async function cambiarMiPassword(id, actual, nueva) {
  const { rows } = await query(`SELECT password_hash FROM usuarios WHERE id = $1 AND es_activo = true`, [id]);
  if (!rows[0]) return 'NO_ENCONTRADO';
  const ok = await bcrypt.compare(actual, rows[0].password_hash);
  if (!ok) return 'ACTUAL_INCORRECTA';
  const hash = await bcrypt.hash(nueva, 10);
  await query(`UPDATE usuarios SET password_hash = $1 WHERE id = $2`, [hash, id]);
  await auditar(id, 'CAMBIAR_PASSWORD', { id }, 'Cambió su contraseña');
  return 'OK';
}

/** Resumen para la pantalla de Reportes de la app */
export async function resumenUsuarios(desde, hasta) {
  const totales = await query(
    `SELECT COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE es_activo)::int AS activos,
            COUNT(*) FILTER (WHERE NOT es_activo)::int AS inactivos,
            COUNT(*) FILTER (WHERE role = 'ADMIN')::int AS admins,
            COUNT(*) FILTER (WHERE role = 'staff')::int AS staff
     FROM usuarios
     WHERE fecha_creacion::date BETWEEN $1 AND $2`,
    [desde, hasta],
  );
  const porMes = await query(
    `SELECT to_char(m.mes, 'YYYY-MM') AS mes, COUNT(u.id)::int AS total
     FROM generate_series(date_trunc('month', $1::date), date_trunc('month', $2::date), '1 month') AS m(mes)
     LEFT JOIN usuarios u
       ON date_trunc('month', u.fecha_creacion) = m.mes
      AND u.fecha_creacion::date BETWEEN $1 AND $2
     GROUP BY m.mes
     ORDER BY m.mes`,
    [desde, hasta],
  );
  return { desde, hasta, ...totales.rows[0], porMes: porMes.rows };
}
