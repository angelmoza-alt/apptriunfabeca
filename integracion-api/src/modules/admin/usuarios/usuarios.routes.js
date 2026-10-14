import { Router } from 'express';
import { authMiddleware, requireRole } from '../../../shared/middelwares/auth.middelware.js';
import {
  getResumen,
  getUsuario,
  getUsuarios,
  patchEstado,
  postUsuario,
  putMiPassword,
  putMiPerfil,
  putPasswordUsuario,
  putUsuario,
} from './usuarios.controller.js';

/**
 * Gestión de usuarios (tabla "usuarios").
 * Los usuarios creados aquí inician sesión en el panel admin
 * (Gestión y Respuestas Rápidas) con POST /api/v1/admin/auth/login,
 * y también en la app móvil Triunfa Beca.
 */
const router = Router();

router.use(authMiddleware);

// Cualquier usuario autenticado: su propio perfil y contraseña
router.put('/me', putMiPerfil);
router.put('/me/password', putMiPassword);

// Solo administradores
router.use(requireRole('ADMIN', 'admin'));
router.get('/', getUsuarios);
router.get('/resumen', getResumen);
router.get('/:id', getUsuario);
router.post('/', postUsuario);
router.put('/:id', putUsuario);
router.patch('/:id/estado', patchEstado);
router.put('/:id/password', putPasswordUsuario);

export default router;
