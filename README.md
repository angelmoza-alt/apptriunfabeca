# Triunfa Beca – App móvil (Flutter)

App para **crear y administrar las cuentas** del equipo de Triunfa Beca.
Usa la **misma API y base de datos** que el panel web (**Gestión** y **Respuestas Rápidas**):
un usuario creado en la app inicia sesión en las dos páginas con el mismo correo y contraseña.

```
App Flutter ──┐
              ├──►  triunfa-beca-api (Node + Express)  ──►  PostgreSQL (tabla usuarios)
Panel admin ──┘     POST /api/v1/admin/auth/login           (Docker)
(Gestión / Respuestas Rápidas)
```

```
apptriunfabeca/
├── app_flutter/        ← la app
└── integracion-api/    ← módulo "usuarios" que se agrega a triunfa-beca-api
```

## 🚀 Cómo probarlo

Requisitos: **Docker Desktop**, **Node.js**, **Flutter** y un celular Android con depuración USB (o emulador).

> ⚠️ Trabaja en rutas **sin tildes ni ñ** (ej. `D:\Proyectos\...`): Android no compila con esos caracteres.

### 1. Levantar la API de Triunfa Beca (con el módulo de usuarios)

```powershell
git clone https://github.com/rootKarka/triunfa-beca-api.git
# instalar el módulo de usuarios (desde la carpeta de este repo):
.\integracion-api\instalar.ps1 -Api "RUTA\triunfa-beca-api"

cd RUTA\triunfa-beca-api
copy .env.example .env
docker compose up -d                 # PostgreSQL + migraciones (puerto 5433)
npm install
node src/database/seed-admin.js      # admin2@triunfabeca.com / triunfa2026
npm run dev                          # API en http://localhost:3000
```

> Cuando el módulo se suba al repo `triunfa-beca-api`, el paso de `instalar.ps1` ya no hace falta.

### 2. Correr la app

```powershell
cd app_flutter
flutter pub get
adb reverse tcp:3000 tcp:3000        # conecta el celular/emulador con la API de tu PC
flutter run
```

Inicia sesión con `admin2@triunfabeca.com` / `triunfa2026` (o la cuenta admin que tengan).

Si Flutter está en C: y el proyecto en D: y sale un error de Kotlin ("different roots"):
```powershell
[Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\pub_cache", "User")
```
y reinicia VS Code.

## Qué hace la app

| Rol | Puede |
|---|---|
| **ADMIN** | Registrar usuarios (nombre, correo, contraseña, rol), buscarlos y filtrarlos, editar sus datos, cambiar rol, activar/desactivar cuentas, restablecer contraseñas y ver reportes |
| **staff** | Ver y editar sus datos y cambiar su contraseña |

- Una cuenta **desactivada** no puede entrar ni a la app ni al panel web.
- Todas las acciones quedan en la **auditoría** de la API.
- Tema claro/oscuro y notificaciones se guardan en el celular.
- Se adapta a celulares pequeños, grandes y tablets.

## Dónde se conecta (`app_flutter/lib/config/api_config.dart`)

| Dispositivo | Configuración |
|---|---|
| Celular por USB / emulador | `ipManual = '127.0.0.1'` + `adb reverse tcp:3000 tcp:3000` |
| Chrome / Windows | `ipManual = null` (usa `localhost`) — agrega el origen a `CORS_ORIGINS` del `.env` de la API |
| Celular por WiFi | `ipManual = 'IP-de-tu-PC'` (misma red) |
