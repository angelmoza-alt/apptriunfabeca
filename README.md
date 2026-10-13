# Triunfa Beca – App móvil (Flutter) + Backend (Node + PostgreSQL en Docker)

## 🚀 Inicio rápido (para probar el proyecto después de clonarlo)

Requisitos: **Docker Desktop**, **Flutter** y un celular Android con depuración USB (o un emulador).

> ⚠️ Clona el proyecto en una ruta **sin tildes ni ñ** (por ejemplo `D:\Proyectos\apptriunfabeca`), porque Android no compila con esos caracteres en la ruta.

```powershell
git clone https://github.com/angelmoza-alt/apptriunfabeca.git
cd apptriunfabeca
docker compose up -d --build          # 1. levanta la API y la base de datos

cd app_flutter
flutter pub get                       # 2. dependencias de Flutter
adb reverse tcp:3000 tcp:3000         # 3. conecta el celular/emulador con la API de tu PC
flutter run                           # 4. instala y abre la app
```

Usuarios de prueba (contraseña de todos: `123456`):
- Administrador: `ana@email.com`
- Estudiante: `carlos@email.com`

Si el proyecto está en el disco D: y Flutter en C: y sale un error de Kotlin ("different roots"), ejecuta una vez:
```powershell
[Environment]::SetEnvironmentVariable("PUB_CACHE", "D:\pub_cache", "User")
```
y reinicia VS Code.

---

```
Proyecto App-triunfaBeca/
├── docker-compose.yml        ← levanta la API y la base de datos
├── backend/                  ← API en Node.js + Express
│   ├── Dockerfile
│   └── src/ (index.js, db.js, auth.js, validaciones.js)
└── app_flutter/              ← App en Flutter
    ├── setup.bat             ← se ejecuta UNA vez para preparar el proyecto
    ├── assets/images/        ← logo.png, logo_icono.png, app_icon.png
    └── lib/
        ├── config/           ← dirección del servidor
        ├── models/           ← Usuario, Reporte
        ├── services/         ← ApiService (única clase que habla con el backend)
        ├── providers/        ← estado: sesión, usuarios, configuración
        ├── screens/          ← las pantallas
        ├── widgets/          ← componentes reutilizables
        └── theme/            ← colores del logo (azul y rojo)
```

## 1. Levantar el backend (Docker Desktop abierto)

En la carpeta raíz del proyecto:

```bash
docker compose up -d --build
```

- API: http://localhost:3000/api/health → debe responder `{"estado":"en_linea"}`
- PostgreSQL: puerto **5433** en tu PC (usuario `triunfa`, clave `triunfa123`, BD `triunfa_beca`)
- La primera vez se crean usuarios de ejemplo. **Contraseña de todos: `123456`**
  - Administrador: `ana@email.com`
  - Estudiante: `carlos@email.com`

Comandos útiles:

```bash
docker compose logs -f api     # ver logs de la API
docker compose down            # apagar (los datos se conservan)
docker compose down -v         # apagar y BORRAR la base de datos
```

## 2. Preparar y correr la app Flutter

Solo si faltan las carpetas android/ios: entra a `app_flutter` y haz doble clic en **setup.bat** (o ejecútalo en la terminal).
Esto genera las carpetas android/ios/web/windows, descarga dependencias, permite HTTP local en Android
y genera el ícono con el logo.

Luego, cada vez que quieras correrla:

```bash
cd app_flutter
flutter run
```

Dónde busca el servidor (`lib/config/api_config.dart`):

| Dispositivo        | Dirección usada              |
|--------------------|------------------------------|
| Emulador Android   | `http://10.0.2.2:3000/api`   |
| Chrome / Windows   | `http://localhost:3000/api`  |
| Celular físico     | poner la IP de tu PC en `ipManual` (misma WiFi) |

## 3. Lógica de la app

- **Splash** → si hay sesión guardada entra directo a **Inicio**; si no, va a **Login**.
- **Registro** sin sesión crea tu cuenta (rol estudiante) y entra. El **admin** puede registrar a otros desde Inicio o Usuarios.
- **Inicio**: saludo con tu nombre, accesos rápidos, notificaciones y estado del servidor (en línea / sin conexión).
- **Mis datos / Datos personales**: editar nombres, apellidos, DNI y correo (con validaciones). Se actualiza en todas las pantallas.
- **Seguridad**: cambiar contraseña (pide la actual). La nueva es la que vale para el login.
- **Usuarios** (solo admin): buscador, filtros por estado y detalle; el admin cambia el estado (Activo, En proceso, Inactivo, Rechazado).
- **Reportes** (solo admin): totales y gráfico por mes calculados desde la base de datos, con rango de fechas; "Generar reporte" lo copia.
- **Configuración**: notificaciones, tema claro/oscuro (se aplica al instante y se guarda por usuario), cerrar sesión.
- **Menú lateral**: navegación a todo; Reportes y Usuarios solo aparecen para el admin.
- Los usuarios inactivos o rechazados no pueden iniciar sesión.

## Pantallas de cualquier tamaño

- **Celular pequeño (< 380 px):** el registro pone Nombres y Apellido uno debajo del otro; los textos largos se recortan con "…".
- **Celular normal:** 2 columnas de tarjetas y barra de navegación inferior.
- **Tablet:** el contenido se centra con un ancho máximo (los formularios no se estiran) y las tarjetas pasan a 3 o 4 columnas.
- **Tablet grande u horizontal (≥ 840 px):** la barra inferior se cambia por una barra lateral (NavigationRail).
- **Celular en horizontal:** todo tiene scroll y las ondas decorativas se achican.
- **Letra grande en el celular:** se respeta, con un límite de 130 % para que no rompa el diseño.

Para probar: en el emulador, cambia a una tablet (Pixel Tablet) o gira la pantalla. En Chrome (`flutter run -d chrome`) abre DevTools (F12) y usa el modo dispositivo.

## 4. Endpoints de la API

| Método | Ruta                    | Descripción                               |
|--------|-------------------------|-------------------------------------------|
| GET    | /api/health             | Estado del sistema                        |
| POST   | /api/auth/registro      | Registrar usuario                         |
| POST   | /api/auth/login         | Iniciar sesión (devuelve token JWT)       |
| GET    | /api/auth/yo            | Datos del usuario logueado                |
| PUT    | /api/auth/password      | Cambiar contraseña                        |
| GET    | /api/usuarios?q=&estado=| Listar/buscar usuarios (admin)            |
| GET    | /api/usuarios/:id       | Detalle (admin o uno mismo)               |
| PUT    | /api/usuarios/:id       | Editar datos / estado                     |
| GET    | /api/reportes?desde=&hasta= | Resumen y registros por mes (admin)   |
| GET/PUT| /api/configuracion      | Preferencias del usuario                  |

Cuando conecten con la página web, solo se cambia `lib/services/api_service.dart` y `api_config.dart`;
las pantallas no se tocan. La versión Swift puede usar esta misma API.
