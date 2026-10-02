# Registro de Sprints — Tracto Trak (SPF)

Registro de entregas por Sprint, con lo construido, pruebas y decisiones.

---

## Sprint 1 — Fundación técnica y diseño base

**Fecha:** Octubre 2026

### Entregables

#### Backend
- Estructura de carpetas completa (`src/config`, `models`, `controllers`, `routes`, `middlewares`, `services`, `strategies`)
- `package.json` con Express, Mongoose, JWT, bcrypt, Jest, Supertest, mongodb-memory-server
- `.env.example` con todas las variables documentadas
- Conexión a MongoDB (`spf_autotransporte`) en `src/config/database.js`
- 4 modelos Mongoose iniciales: `Usuario`, `Camion`, `Chofer`, `Cliente`
- `app.js` (Express + middlewares) y `server.js` (arranque)
- Endpoint `GET /health` con estado del servidor y la BD
- Middleware de manejo de errores (validación, duplicados, 404)

#### Frontend
- Proyecto Flutter creado (`tracto_trak`, org: `com.tractotrak`)
- Tema oscuro de alto contraste (`AppTheme.darkTheme`)
- Colores semánticos: verde, ámbar, azul, rojo
- Rutas nombradas para las 23 pantallas (C-01…C-06, A-01…A-17)
- `ApiClient` Singleton (patrón P1)
- Widget `OnlineIndicator` (estado de conexión visible)
- Widget `StatusBadge` (etiquetas con color semántico)
- Pantalla de login `LoginScreen` (C-01/A-01) con selector de rol
- Placeholders para todas las pantallas no implementadas
- `main.dart` configurado con tema y rutas

#### Raíz y documentación
- `.gitignore` global (Node, Flutter, OS)
- `README.md` raíz
- `docs/README.md` (índice)
- `docs/decisiones.md` (supuestos S-01 a S-08, decisiones D-01 a D-04)
- `docs/sprints.md` (este archivo)

### Pruebas
- Backend: `backend/test/health.test.js` — endpoint /health y rutas 404
- Frontend: `frontend/test/sprint1_test.dart` — app, login, tema, singleton, widgets

### Decisiones tomadas
- Ver `docs/decisiones.md`: D-01 a D-04

---

## Sprint 2 — Autenticación Completa y Gestión de Sesión

**Fecha:** Octubre 2026

### Entregables

#### Backend
- Middleware `autenticarToken` (`src/middlewares/auth.js`): verificación de token JWT en cabecera `Authorization: Bearer <token>`, manejo de expiración y extracción del payload de usuario.
- Middleware `requerirRol` (`src/middlewares/auth.js`): autorización basada en roles (`operador` / `administrador`).
- Controlador `authController.js`:
  - `POST /api/auth/register`: Registro de usuario, hasheo con bcrypt, vinculación automática de Chofer.
  - `POST /api/auth/login`: Autenticación de credenciales y emisión de token JWT.
  - `GET /api/auth/perfil`: Consulta de perfil del usuario autenticado.
- Rutas de autenticación en `src/routes/auth.js`.

#### Frontend
- Pantalla `RegisterScreen` (`lib/features/auth/screens/register_screen.dart`): Registro de choferes y administradores con selector de rol y validación completa.
- Actualización de `LoginScreen`: Conexión real con `ApiClient.login()`, manejo de estados de carga, alertas y fallback a Modo Demo.
- Persistencia de sesión con `shared_preferences` en `ApiClient`:
  - Métodos `initSession()`, `saveSession()`, `logout()`, `login()`, `register()`, `fetchPerfil()`.
  - Auto-login en `main.dart` redirigiendo al home correspondiente si existe sesión activa.
- Actualización del tema de color primario a tono azul por preferencia del usuario.

### Pruebas
- Backend: `backend/test/auth.test.js` (11 tests en total) — Registro, login, middleware JWT, token inválido/ausente.
- Frontend: `frontend/test/sprint1_test.dart` (15 tests en total) — Widgets, autenticación, tema, persistencia, ApiClient.

