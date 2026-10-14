# Módulo `usuarios` para triunfa-beca-api

La app móvil crea y administra usuarios en la **misma tabla `usuarios`** que usa el panel admin
(Gestión y Respuestas Rápidas). La API no tenía endpoints para crear usuarios, así que este
módulo los agrega **sin modificar nada de lo existente** (solo 2 líneas en `src/app.js`).

- Contraseñas con **bcryptjs (10 rondas)**, igual que `seed-admin.js` → funcionan en `POST /api/v1/admin/auth/login`.
- Roles válidos: `ADMIN` y `staff` (los mismos que usa `requireRole`).
- Cada acción queda registrada en la tabla `auditoria` (entidad `USUARIO`).
- Un admin no puede desactivarse ni quitarse el rol a sí mismo (para no quedarse sin acceso).

## Instalar

Opción A (script, Windows):
```powershell
.\instalar.ps1 -Api "D:\ruta\a\triunfa-beca-api"
```

Opción B (a mano):
1. Copia la carpeta `src/modules/admin/usuarios/` dentro de `triunfa-beca-api/src/modules/admin/`.
2. En `src/app.js` agrega:
   ```js
   import usuariosRoutes from './modules/admin/usuarios/usuarios.routes.js';
   // ...
   app.use('/api/v1/admin/usuarios', usuariosRoutes);
   ```

No necesita migraciones nuevas: usa la tabla `usuarios` de `001_init.sql`.

## Endpoints (todos con `Authorization: Bearer <token>`)

| Método | Ruta | Quién | Body |
|---|---|---|---|
| PUT | `/api/v1/admin/usuarios/me` | cualquiera | `{ nombre?, correo? }` |
| PUT | `/api/v1/admin/usuarios/me/password` | cualquiera | `{ actual, nueva }` |
| GET | `/api/v1/admin/usuarios?q=&role=&activo=` | ADMIN | – |
| GET | `/api/v1/admin/usuarios/resumen?desde=&hasta=` | ADMIN | – |
| GET | `/api/v1/admin/usuarios/:id` | ADMIN | – |
| POST | `/api/v1/admin/usuarios` | ADMIN | `{ nombre, correo, password, role? }` |
| PUT | `/api/v1/admin/usuarios/:id` | ADMIN | `{ nombre?, correo?, role? }` |
| PATCH | `/api/v1/admin/usuarios/:id/estado` | ADMIN | `{ es_activo: true/false }` |
| PUT | `/api/v1/admin/usuarios/:id/password` | ADMIN | `{ nueva }` |

Respuestas con el formato de la API: `{ success, message, data }`.
