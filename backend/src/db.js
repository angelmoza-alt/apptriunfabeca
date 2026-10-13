const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'triunfa',
  password: process.env.DB_PASSWORD || 'triunfa123',
  database: process.env.DB_NAME || 'triunfa_beca',
});

const query = (text, params) => pool.query(text, params);

// Crea las tablas si no existen
async function crearTablas() {
  await query(`
    CREATE TABLE IF NOT EXISTS usuarios (
      id SERIAL PRIMARY KEY,
      nombres VARCHAR(100) NOT NULL,
      apellido_paterno VARCHAR(100) NOT NULL,
      apellido_materno VARCHAR(100) NOT NULL,
      dni CHAR(8) NOT NULL UNIQUE,
      correo VARCHAR(150) NOT NULL UNIQUE,
      password_hash VARCHAR(200) NOT NULL,
      estado VARCHAR(20) NOT NULL DEFAULT 'activo'
        CHECK (estado IN ('activo', 'en_proceso', 'inactivo', 'rechazado')),
      rol VARCHAR(20) NOT NULL DEFAULT 'estudiante'
        CHECK (rol IN ('admin', 'estudiante')),
      creado_en TIMESTAMP NOT NULL DEFAULT NOW(),
      actualizado_en TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `);
  await query(`
    CREATE TABLE IF NOT EXISTS configuraciones (
      usuario_id INTEGER PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
      notificaciones BOOLEAN NOT NULL DEFAULT TRUE,
      idioma VARCHAR(10) NOT NULL DEFAULT 'es',
      tema VARCHAR(10) NOT NULL DEFAULT 'claro' CHECK (tema IN ('claro', 'oscuro'))
    );
  `);
}

// Datos de ejemplo la primera vez (para que Reportes y Usuarios no salgan vacíos)
async function sembrarDatos() {
  const { rows } = await query('SELECT COUNT(*)::int AS total FROM usuarios');
  if (rows[0].total > 0) return;

  const hash = await bcrypt.hash('123456', 10);
  const ejemplos = [
    ['Ana', 'Torres', 'García', '76543210', 'ana@email.com', 'activo', 'admin', 0],
    ['Carlos', 'Méndez', 'Ruiz', '71234567', 'carlos@email.com', 'activo', 'estudiante', 1],
    ['Lucía', 'Rojas', 'Paredes', '72345678', 'lucia@email.com', 'en_proceso', 'estudiante', 1],
    ['Daniel', 'Silva', 'Castro', '73456789', 'silva@email.com', 'inactivo', 'estudiante', 2],
    ['María', 'Quispe', 'Flores', '74567890', 'maria@email.com', 'activo', 'estudiante', 2],
    ['Jorge', 'Vargas', 'León', '75678901', 'jorge@email.com', 'rechazado', 'estudiante', 3],
    ['Rosa', 'Chávez', 'Díaz', '76789012', 'rosa@email.com', 'activo', 'estudiante', 4],
    ['Luis', 'Ramos', 'Soto', '77890123', 'luis@email.com', 'en_proceso', 'estudiante', 5],
  ];

  for (const [n, ap, am, dni, correo, estado, rol, mesesAtras] of ejemplos) {
    const usr = await query(
      `INSERT INTO usuarios (nombres, apellido_paterno, apellido_materno, dni, correo,
         password_hash, estado, rol, creado_en)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8, NOW() - ($9 || ' months')::interval)
       RETURNING id`,
      [n, ap, am, dni, correo, hash, estado, rol, String(mesesAtras)]
    );
    await query('INSERT INTO configuraciones (usuario_id) VALUES ($1)', [usr.rows[0].id]);
  }
  console.log('Datos de ejemplo creados (contraseña de todos: 123456)');
}

async function iniciarBD(intentos = 20) {
  for (let i = 1; i <= intentos; i++) {
    try {
      await query('SELECT 1');
      await crearTablas();
      await sembrarDatos();
      console.log('Base de datos lista');
      return;
    } catch (err) {
      console.log(`Esperando a PostgreSQL (${i}/${intentos})... ${err.message}`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  throw new Error('No se pudo conectar a PostgreSQL');
}

module.exports = { query, iniciarBD, pool };
