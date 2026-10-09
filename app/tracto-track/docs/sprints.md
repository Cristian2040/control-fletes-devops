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

---

## Sprint 3 — Captura Móvil de Gastos e Insumos (RF-02, US-03, P3 Strategy)

**Fecha:** Octubre 2026

### Entregables

#### Backend
- **Modelo Mongoose `Gasto`** (`src/models/Gasto.js`):
  - Folio autoincrementado con formato `#TT-######` (Supuesto S-01).
  - Tipos: `diesel`, `fluidos`, `viaticos`.
  - Campos: `monto`, `odometro`, `proveedor`, `fotografiaUrl`, `fotografiaBase64`, `compresionOptimizada`, `chofer`, `usuario`, `placasCamion`, `estadoSincronizacion`, `estadoAuditoria`, `fecha`.
- **Patrón de Diseño P3: Strategy** (`src/strategies/`):
  - `BaseGastoValidationStrategy.js`: Clase base abstracta para validación de gastos.
  - `DieselValidationStrategy.js`: Exige odómetro obligatorio, foto y monto > 0.
  - `FluidosValidationStrategy.js`: Exige odómetro obligatorio (mantenimiento), foto y monto > 0.
  - `ViaticosValidationStrategy.js`: Odómetro opcional, foto obligatoria y monto > 0.
  - `GastoValidationContext.js`: Selección dinámica de la estrategia en tiempo de ejecución.
- **Controlador `gastoController.js`**:
  - `POST /api/gastos`: Validación con Strategy P3, generación automática de folio secuencial y guardado.
  - `GET /api/gastos`: Consulta con cálculo de total acumulado y contador para la bitácora C-05.
  - `GET /api/gastos/:id`: Consulta individual por ID o Folio.
- **Rutas de Gastos** (`src/routes/gastos.js`): Protegidas con middleware JWT `autenticarToken` montadas en `/api/gastos`.

#### Frontend
- **Patrón Strategy en Dart** (`lib/features/chofer/strategies/gasto_validation_strategy.dart`):
  - `GastoValidationStrategy`, `DieselValidationStrategy`, `FluidosValidationStrategy`, `ViaticosValidationStrategy`, `GastoValidationContext`.
- **Modelo Dart `GastoModel`** (`lib/data/models/gasto_model.dart`).
- **Ampliación de `ApiClient`**: Métodos `registrarGasto` y `obtenerGastos` con respaldo offline y datos muestra.
- **Barra de Navegación Inferior `ChoferBottomNavBar`** (`lib/features/chofer/widgets/chofer_bottom_nav_bar.dart`): Navegación entre C-02, C-05 y C-06.
- **Pantalla C-02 `RutaScreen`** (`lib/features/chofer/screens/ruta_screen.dart`):
  - Operador asignado con etiqueta `EN RUTA`.
  - Tarjeta de unidad con placas `NLZ-8823-A`, odómetro `142,500 KM`, tramo `Monterrey → CDMX`, cliente `CEMEX S.A. de C.V.`.
  - Botón principal `+ Registrar Gasto de Ruta (RF-02)`.
  - Lista de comprobantes recientes con estado `SINCRONIZADO`.
- **Pantalla C-03 `CapturaGastoScreen`** (`lib/features/chofer/screens/captura_gasto_screen.dart`):
  - Formulario express con selector de tipo (Diésel, Fluidos, Viáticos).
  - Campo dinámico de odómetro (obligatorio/opcional según Strategy).
  - Zona de fotografía con validación estricta (US-03) e indicador de compresión (US-09comp: 1.8 MB → 142 KB).
  - Botón `Guardar y Transmitir Registro`.
- **Pantalla C-04 `RegistroProcesadoScreen`** (`lib/features/chofer/screens/registro_procesado_screen.dart`):
  - Confirmación de registro con folio `#TT-######`.
  - Resumen de monto, insumo, odómetro y estado `SINCRONIZADO`.
  - Acciones: `Capturar Otro Ticket` y `Regresar a Ruta Activa`.
- **Pantalla C-05 `MisGastosScreen`** (`lib/features/chofer/screens/mis_gastos_screen.dart`):
  - Barra de totales con importe acumulado y contador de comprobantes.
  - Historial de comprobantes con badges de estado y auditoría.
- **Pantalla C-06 `PerfilChoferScreen`** (`lib/features/chofer/screens/perfil_chofer_screen.dart`):
  - Datos de identidad y licencia federal `LF-9928172`.
  - Asignación de unidad y empresa `Transportes Flores S.A.`.
  - Botón `Cerrar Sesión` con limpieza de token JWT.
- **Actualización de `AppRoutes`**: Rutas C-02 a C-06 conectadas directamente.

### Pruebas
- Backend: `backend/test/gastos.test.js` + `test/auth.test.js` + `test/health.test.js` (27 pruebas aprobadas).
- Frontend: `frontend/test/sprint3_test.dart` + `test/sprint1_test.dart` (27 pruebas aprobadas).


