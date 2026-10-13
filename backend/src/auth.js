const jwt = require('jsonwebtoken');

const SECRET = process.env.JWT_SECRET || 'triunfa-beca-secreto-local';

function firmarToken(usuario) {
  return jwt.sign({ id: usuario.id, rol: usuario.rol }, SECRET, { expiresIn: '7d' });
}

// Middleware: exige "Authorization: Bearer <token>"
function requiereAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ mensaje: 'Debes iniciar sesión' });
  try {
    req.usuario = jwt.verify(token, SECRET);
    next();
  } catch {
    return res.status(401).json({ mensaje: 'Sesión expirada, vuelve a iniciar sesión' });
  }
}

function requiereAdmin(req, res, next) {
  if (req.usuario?.rol !== 'admin') return res.status(403).json({ mensaje: 'Solo el administrador puede ver esto' });
  next();
}

module.exports = { firmarToken, requiereAuth, requiereAdmin };
