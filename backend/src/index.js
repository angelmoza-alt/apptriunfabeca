const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { query, iniciarBD } = require('./db');
const { firmarToken, requiereAuth, requiereAdmin } = require('./auth');
const { validarDatos } = require('./validaciones');

const app = express();
app.use(cors());
app.use(express.json());

const ESTADOS = ['activo', 'en_proceso', 'inactivo', 'rechazado'];

// Convierte una fila de la BD al formato JSON que usa la app
const aJson = (u) => ({
  id: u.id,
  nombres: u.nombres,
  apellidoPaterno: u.apellido_paterno,
  apellidoMaterno: u.apellido_materno,
  dni: u.dni,
  correo: u.correo,
  estado: u.estado,
  rol: u.rol,
  creadoEn: u.creado_en,
});

// Traduce errores de PostgreSQL (DNI o correo repetido)
function manejarError(res, err) {
  if (err.code === '23505') {
    const campo = err.constraint && err.constraint.includes('dni') ? 'DNI' : 'correo';
    return res.status(409).json({ mensaje: `Ya existe un usuario con ese ${campo}` });
  }
  console.error(err);
  return res.status(500).json({ mensaje: 'Error interno del servidor' });
}

// ---------- Estado del sistema ----------
app.get('/api/health', async (req, res) => {
  try {
    await query('SELECT 1');
    res.json({ estado: 'en_linea', hora: new Date().toISOString() });
  } catch {
    res.status(503).json({ estado: 'sin_conexion' });
  }
});

// ---------- Autenticación ----------
app.post('/api/auth/registro', async (req, res) => {
  const d = req.body || {};
  const errores = validarDatos(d, { conPassword: true });
  if (errores.length) return res.status(400).json({ mensaje: errores[0], errores });

  try {
    const hash = await bcrypt.hash(String(d.password), 10);
    const { rows } = await query(
      `INSERT INTO usuarios (nombres, apellido_paterno, apellido_materno, dni, correo, password_hash, estado)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [d.nombres.trim(), d.apellidoPaterno.trim(), d.apellidoMaterno.trim(), d.dni,
       d.correo.trim().toLowerCase(), hash, ESTADOS.includes(d.estado) ? d.estado : 'activo']
    );
    await query('INSERT INTO configuraciones (usuario_id) VALUES ($1)', [rows[0].id]);
    const usuario = aJson(rows[0]);
    res.status(201).json({ usuario, token: firmarToken(usuario) });
  } catch (err) {
    manejarError(res, err);
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { correo, password } = req.body || {};
  if (!correo || !password) return res.status(400).json({ mensaje: 'Ingresa correo y contraseña' });

  const { rows } = await query('SELECT * FROM usuarios WHERE correo = $1', [String(correo).trim().toLowerCase()]);
  const u = rows[0];
  if (!u || !(await bcrypt.compare(String(password), u.password_hash))) {
    return res.status(401).json({ mensaje: 'Correo o contraseña incorrectos' });
  }
  if (u.estado === 'inactivo' || u.estado === 'rechazado') {
    return res.status(403).json({ mensaje: 'Tu cuenta no está activa' });
  }
  const usuario = aJson(u);
  res.json({ usuario, token: firmarToken(usuario) });
});

app.get('/api/auth/yo', requiereAuth, async (req, res) => {
  const { rows } = await query('SELECT * FROM usuarios WHERE id = $1', [req.usuario.id]);
  if (!rows[0]) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
  res.json(aJson(rows[0]));
});

app.put('/api/auth/password', requiereAuth, async (req, res) => {
  const { actual, nueva } = req.body || {};
  if (!actual || !nueva) return res.status(400).json({ mensaje: 'Completa ambos campos' });
  if (String(nueva).length < 6) return res.status(400).json({ mensaje: 'La nueva contraseña debe tener al menos 6 caracteres' });

  const { rows } = await query('SELECT password_hash FROM usuarios WHERE id = $1', [req.usuario.id]);
  if (!rows[0] || !(await bcrypt.compare(String(actual), rows[0].password_hash))) {
    return res.status(400).json({ mensaje: 'La contraseña actual no es correcta' });
  }
  const hash = await bcrypt.hash(String(nueva), 10);
  await query('UPDATE usuarios SET password_hash = $1, actualizado_en = NOW() WHERE id = $2', [hash, req.usuario.id]);
  res.json({ mensaje: 'Contraseña actualizada' });
});

// ---------- Usuarios ----------
app.get('/api/usuarios', requiereAuth, requiereAdmin, async (req, res) => {
  const { q, estado } = req.query;
  const condiciones = [];
  const params = [];
  if (q) {
    params.push(`%${q}%`);
    condiciones.push(`(nombres || ' ' || apellido_paterno || ' ' || apellido_materno || ' ' || correo || ' ' || dni) ILIKE $${params.length}`);
  }
  if (estado && ESTADOS.includes(estado)) {
    params.push(estado);
    condiciones.push(`estado = $${params.length}`);
  }
  const where = condiciones.length ? `WHERE ${condiciones.join(' AND ')}` : '';
  const { rows } = await query(`SELECT * FROM usuarios ${where} ORDER BY creado_en DESC`, params);
  res.json(rows.map(aJson));
});

app.get('/api/usuarios/:id', requiereAuth, async (req, res) => {
  if (req.usuario.rol !== 'admin' && req.usuario.id !== Number(req.params.id)) {
    return res.status(403).json({ mensaje: 'No puedes ver a otro usuario' });
  }
  const { rows } = await query('SELECT * FROM usuarios WHERE id = $1', [Number(req.params.id)]);
  if (!rows[0]) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
  res.json(aJson(rows[0]));
});

app.put('/api/usuarios/:id', requiereAuth, async (req, res) => {
  const id = Number(req.params.id);
  // Un estudiante solo puede editar sus propios datos; el admin puede editar a todos
  if (req.usuario.rol !== 'admin' && req.usuario.id !== id) {
    return res.status(403).json({ mensaje: 'No puedes editar a otro usuario' });
  }
  const d = req.body || {};
  const errores = validarDatos(d, { parcial: true });
  if (d.estado !== undefined && !ESTADOS.includes(d.estado)) errores.push('Estado no válido');
  if (d.estado !== undefined && req.usuario.rol !== 'admin') errores.push('Solo el administrador cambia estados');
  if (errores.length) return res.status(400).json({ mensaje: errores[0], errores });

  const mapa = {
    nombres: 'nombres', apellidoPaterno: 'apellido_paterno', apellidoMaterno: 'apellido_materno',
    dni: 'dni', correo: 'correo', estado: 'estado',
  };
  const sets = [];
  const params = [];
  for (const [campo, columna] of Object.entries(mapa)) {
    if (d[campo] !== undefined) {
      let valor = String(d[campo]).trim();
      if (campo === 'correo') valor = valor.toLowerCase();
      params.push(valor);
      sets.push(`${columna} = $${params.length}`);
    }
  }
  if (!sets.length) return res.status(400).json({ mensaje: 'No hay cambios' });
  params.push(id);
  try {
    const { rows } = await query(
      `UPDATE usuarios SET ${sets.join(', ')}, actualizado_en = NOW() WHERE id = $${params.length} RETURNING *`,
      params
    );
    if (!rows[0]) return res.status(404).json({ mensaje: 'Usuario no encontrado' });
    res.json(aJson(rows[0]));
  } catch (err) {
    manejarError(res, err);
  }
});

// ---------- Reportes ----------
app.get('/api/reportes', requiereAuth, requiereAdmin, async (req, res) => {
  const hoy = new Date();
  const desde = req.query.desde || new Date(hoy.getFullYear(), hoy.getMonth() - 5, 1).toISOString().slice(0, 10);
  const hasta = req.query.hasta || hoy.toISOString().slice(0, 10);

  const resumen = await query(
    `SELECT COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE estado = 'activo')::int AS activos,
            COUNT(*) FILTER (WHERE estado = 'en_proceso')::int AS en_proceso,
            COUNT(*) FILTER (WHERE estado = 'inactivo')::int AS inactivos,
            COUNT(*) FILTER (WHERE estado = 'rechazado')::int AS rechazados
     FROM usuarios WHERE creado_en::date BETWEEN $1 AND $2`,
    [desde, hasta]
  );
  // Registros por mes, incluyendo meses con 0
  const porMes = await query(
    `SELECT to_char(m.mes, 'YYYY-MM') AS mes, COUNT(u.id)::int AS total
     FROM generate_series(date_trunc('month', $1::date), date_trunc('month', $2::date), '1 month') AS m(mes)
     LEFT JOIN usuarios u ON date_trunc('month', u.creado_en) = m.mes
       AND u.creado_en::date BETWEEN $1 AND $2
     GROUP BY m.mes ORDER BY m.mes`,
    [desde, hasta]
  );
  const r = resumen.rows[0];
  res.json({
    desde, hasta,
    total: r.total, activos: r.activos, enProceso: r.en_proceso,
    inactivos: r.inactivos, rechazados: r.rechazados,
    porMes: porMes.rows,
  });
});

// ---------- Configuración ----------
app.get('/api/configuracion', requiereAuth, async (req, res) => {
  await query('INSERT INTO configuraciones (usuario_id) VALUES ($1) ON CONFLICT DO NOTHING', [req.usuario.id]);
  const { rows } = await query('SELECT * FROM configuraciones WHERE usuario_id = $1', [req.usuario.id]);
  const c = rows[0];
  res.json({ notificaciones: c.notificaciones, idioma: c.idioma, tema: c.tema });
});

app.put('/api/configuracion', requiereAuth, async (req, res) => {
  const { notificaciones, idioma, tema } = req.body || {};
  if (tema !== undefined && !['claro', 'oscuro'].includes(tema)) {
    return res.status(400).json({ mensaje: 'Tema no válido' });
  }
  const { rows } = await query(
    `INSERT INTO configuraciones (usuario_id, notificaciones, idioma, tema)
     VALUES ($1, COALESCE($2, TRUE), COALESCE($3, 'es'), COALESCE($4, 'claro'))
     ON CONFLICT (usuario_id) DO UPDATE SET
       notificaciones = COALESCE($2, configuraciones.notificaciones),
       idioma = COALESCE($3, configuraciones.idioma),
       tema = COALESCE($4, configuraciones.tema)
     RETURNING *`,
    [req.usuario.id, notificaciones ?? null, idioma ?? null, tema ?? null]
  );
  const c = rows[0];
  res.json({ notificaciones: c.notificaciones, idioma: c.idioma, tema: c.tema });
});

const PORT = Number(process.env.PORT || 3000);
iniciarBD()
  .then(() => app.listen(PORT, '0.0.0.0', () => console.log(`API Triunfa Beca en http://localhost:${PORT}`)))
  .catch((err) => { console.error(err); process.exit(1); });

module.exports = app;
