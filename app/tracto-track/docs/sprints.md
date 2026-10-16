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

---

## Sprint 4 — Almacenamiento Local Offline (US-04, RF-03)

**Fecha:** Octubre 2026

### Entregables

#### Punto 1: Integrar base de datos local en el dispositivo (almacenamiento embebido de Flutter)
- **Data Source Local `LocalGastoStorage`** (`lib/data/datasources/local_gasto_storage.dart`):
  - Almacenamiento persistente basado en `SharedPreferences` con respaldo en memoria seguro (`_inMemoryStore`).
  - Serialización y deserialización de listas de comprobantes en JSON.
  - Generación de secuencias numéricas seguras para folios offline.
  - Métodos: `readAllRaw()`, `writeAllRaw()`, `insertRaw()`, `getNextSequence()`, `clearAll()`.
- **Repositorio Local `LocalGastoRepository`** (`lib/data/repositories/local_gasto_repository.dart`):
  - Manejo de objetos de dominio `GastoModel` y aislamiento de la capa de persistencia.
  - `guardarGastoOffline(GastoModel)`: Asigna folio `#TT-OFF-######` y bandera `estadoSincronizacion = 'pendiente'`.
  - Consultas: `obtenerTodos()`, `obtenerPendientes()`, `obtenerSincronizados()`, `contarPendientes()`.
  - Actualizaciones: `marcarComoSincronizado(id, nuevoFolio)` y `eliminar(id)`.

#### Punto 2: Adaptar el flujo de captura de gastos para guardar localmente sin red
- **Soporte Offline en `ApiClient`** (`lib/core/network/api_client.dart`):
  - Integración del Singleton `LocalGastoRepository`.
  - Banderas de control de conectividad: `_modoAvion`, `isModoAvion`, `isOnline` y `setModoAvion(bool)`.
  - `registrarGasto(...)`: Guarda automáticamente en el almacenamiento local embebido cuando no hay señal celular o la red falla, preservando intacta la fotografía en Base64.
  - `obtenerGastos(...)`: Combina los registros locales pendientes priorizados en la parte superior con los registros del servidor o demo, calculando totales de importe y comprobantes.
- **Formulario C-03 `CapturaGastoScreen`** (`lib/features/chofer/screens/captura_gasto_screen.dart`):
  - Indicador de estado de conexión `OnlineIndicator` visible en la barra superior.
  - Banner informativo en modo offline: "Modo Fuera de Línea (Sin Señal Celular) — El comprobante y la fotografía se guardarán de forma segura en el almacenamiento local del dispositivo (US-04 / RF-03)".
  - Botón adaptativo: "Guardar en Dispositivo (Offline)" frente a "Guardar y Transmitir Registro".

#### Punto 3: Implementar bandera de estado "pendiente de sincronización"
- **Modelo `GastoModel`** (`lib/data/models/gasto_model.dart`):
  - Getters `isPendiente`, `isSincronizado`, `estadoSincronizacionLegible` y método `copyWith()`.
- **Componente `StatusBadge`** (`lib/shared/widgets/status_badge.dart`):
  - Soporte de íconos semánticos (`showIcon: true`): nube tachada (`Icons.cloud_off`) para `'PENDIENTE DE SINCRONIZACIÓN'` y nube con check (`Icons.cloud_done`) para `'SINCRONIZADO'`.
  - Color ámbar de alto contraste (`AppColors.warning`) para estado pendiente.
- **Pantalla C-02 `RutaScreen`** (`lib/features/chofer/screens/ruta_screen.dart`):
  - `OnlineIndicator` interactivo en la barra superior que permite alternar y probar el modo offline/online con feedback táctil.
  - Alerta visual destacada cuando existen tickets pendientes guardados localmente.
  - Tarjetas de comprobantes recientes con badge dinámico `PENDIENTE` / `SINCRONIZADO`.
- **Pantalla C-04 `RegistroProcesadoScreen`** (`lib/features/chofer/screens/registro_procesado_screen.dart`):
  - Detecta si el gasto fue guardado offline (`isPendiente`).
  - Muestra ícono de guardado local, título "Registro Guardado Localmente", badge `PENDIENTE DE SINCRONIZACIÓN` y leyenda informativa de sincronización posterior.
- **Pantalla C-05 `MisGastosScreen`** (`lib/features/chofer/screens/mis_gastos_screen.dart`):
  - Barra de filtros segmentados: "Todos (N)", "Pendientes (N)", "Sincronizados (N)".
  - Badge dinámico en cada comprobante del historial.

#### Punto 4: Pruebas automatizadas en modo avión / sin red
- **Suite de Pruebas `frontend/test/sprint4_test.dart`**:
  - Test unitarios del almacenamiento local embebido y repositorio.
  - Test del escenario BDD US-04 (RF-03): registro de gasto y fotografía sin red celular.
  - Test de alternancia de conexión y widgets C-02, C-03, C-04 y C-05.
- **Resultados de Validación**:
  - Backend: 27/27 pruebas Jest pasando (`backend/test/*.test.js`).
  - Frontend: 37/37 pruebas Flutter pasando (`test/sprint1_test.dart`, `test/sprint3_test.dart`, `test/sprint4_test.dart`).

---

## Sprint 5 — Sincronización Automática y Manual Offline-Online (US-05, RF-04)

**Fecha:** Octubre 2026

### Entregables

#### Punto 1: Sincronización Automática al Restaurar Red Celular (US-05)
- **Monitoreo Reactivo y Periódico en `ApiClient`** (`lib/core/network/api_client.dart`):
  - `iniciarAutoSincronizacion({Duration intervalo})`: Timer periódico en segundo plano que vigila registros pendientes y dispara la sincronización tan pronto hay conectividad.
  - Notificadores `ValueNotifier<int> pendientesNotifier` y `ValueNotifier<bool> isOnlineNotifier` para actualización en tiempo real de la interfaz.
  - Sincronización automática inmediata al alternar de modo avión a online mediante `setModoAvion(false)`.

#### Punto 2: Transmisión y Transición de Estados
- **Motor de Transmisión `sincronizarPendientes({bool forzar})`**:
  - Recupera comprobantes con estado `pendiente` desde `LocalGastoRepository`.
  - Transmite fotos, odómetros, montos e insumos a la API REST `/api/gastos` preservando integridad criptográfica y datos.
  - Al recibir respuesta 201 de MongoDB, actualiza el estado local a `'sincronizado'`, sustituye el folio temporal `#TT-OFF-######` por el folio definitivo `#TT-######` emitido por el backend, y actualiza los contadores.
  - Estructura `SyncResult` con conteos detallados de pendientes, sincronizados y errores.

#### Punto 3: Gatillos Manuales en Pantallas del Chofer
- **Pantalla C-02 `RutaScreen`**:
  - Banner dinámico con botón "Sincronizar ahora" (`btn_sincronizar_ahora`) visible cuando hay comprobantes pendientes en almacenamiento local.
  - Recarga automática en tiempo real al concluir la transmisión.
- **Pantalla C-05 `MisGastosScreen`**:
  - Banner superior con contador de pendientes y botón "Sincronizar ahora" (`btn_sync_pendientes_banner`).
  - Botón de refresco manual en la AppBar (`btn_refresh_mis_gastos`) y soporte para gesto pull-to-refresh (`RefreshIndicator`).

### Pruebas
- Frontend: `frontend/test/sprint5_sync_test.dart` (40/40 tests pasando en toda la suite de Flutter).

---

## Sprint 6 — Panel Móvil de Catálogos (RF-05, A-05 a A-12)

**Fecha:** Octubre 2026

### Entregables

#### Backend
- **Modelo Mongoose `Tarifa`** (`src/models/Tarifa.js`):
  - Campos: `ruta`, `tipoCarga`, `capacidadTon`, `montoBase`, `estado`, `fechaCreacion`.
  - Registrado en `src/models/index.js`.
- **Controlador `catalogoController.js`** (`src/controllers/catalogoController.js`):
  - CRUD completo para Camiones, Choferes, Clientes y Tarifas.
  - Semillero automático con datos maestros iniciales (`asegurarDatosSemilla()`).
  - Filtros de búsqueda por texto (`q`) y estado (`estado`).
- **Rutas de Catálogos** (`src/routes/catalogos.js`):
  - Endpoints montados en `/api`: `/api/camiones`, `/api/choferes`, `/api/clientes`, `/api/tarifas`.
  - Protegidas con token JWT mediante middleware `autenticarToken`.
- **Pruebas de Integración**: `backend/test/catalogos.test.js` con 9 escenarios para verificar protección JWT, creación y filtrado de las 4 entidades maestras (36/36 tests pasando).

#### Frontend
- **Modelos de Catálogos** (`lib/data/models/catalogo_models.dart`):
  - `CamionModel`: placas, marca, modelo, año, capacidad Ton, odómetro, estado (`disponible`, `en_ruta`, `en_taller`).
  - `ChoferModel`: nombre, licencia federal, teléfono, empresa, estado (`disponible`, `en_ruta`, `inactivo`).
  - `ClienteModel`: razón social, RFC, días de crédito, estado (`activo`, `inactivo`).
  - `TarifaModel`: ruta/tramo, tipo de carga, capacidad Ton, monto base MXN, estado (`activa`, `inactiva`).
- **Métodos en `ApiClient`** (`lib/core/network/api_client.dart`):
  - `fetchCamiones`, `crearCamion`, `fetchChoferes`, `crearChofer`, `fetchClientes`, `crearCliente`, `fetchTarifas`, `crearTarifa`.
  - Respaldo de datos semilla en memoria (`_demoCamiones`, `_demoChoferes`, `_demoClientes`, `_demoTarifas`) para operación fluida en modo demo / offline.
- **Navegación del Administrador**:
  - `AdminBottomNavBar` (`lib/features/admin/widgets/admin_bottom_nav_bar.dart`): Barra inferior de 6 módulos (Tablero A-02, Viajes A-03, Catálogos A-05, Auditoría A-13, Liquidación A-15, Perfil A-17).
- **Pantalla Central `CatalogosScreen`** (`lib/features/admin/screens/catalogos_screen.dart`):
  - Implementa A-05 (Camiones), A-06 (Choferes), A-07 (Clientes) y A-08 (Tarifas).
  - Pestañas con `TabController` y recarga reactiva de datos.
  - Buscador reactivo superior (`input_buscar_catalogo`) con hint dinámico por entidad.
  - Tarjetas detalladas con insignias semánticas (`StatusBadge`).
  - Botón superior `+ Alta` (`btn_alta_catalogo`) que navega directamente al formulario de alta de la pestaña activa.
  - Soporte para pull-to-refresh (`RefreshIndicator`).
- **Formularios de Alta (A-09 a A-12)**:
  - `AltaCamionScreen` (A-09, `lib/features/admin/screens/alta_camion_screen.dart`): Placas, marca, modelo, año y capacidad Ton.
  - `AltaChoferScreen` (A-10, `lib/features/admin/screens/alta_chofer_screen.dart`): Nombre completo, licencia federal y teléfono celular.
  - `AltaClienteScreen` (A-11, `lib/features/admin/screens/alta_cliente_screen.dart`): Razón social, RFC y días de crédito.
  - `AltaTarifaScreen` (A-12, `lib/features/admin/screens/alta_tarifa_screen.dart`): Ruta pactada, tipo de carga, capacidad y monto base en MXN.
- **Rutas en `AppRoutes`** (`lib/core/routes/app_routes.dart`):
  - Reemplazo de placeholders por las pantallas definitivas de A-05 a A-12.

### Pruebas
- Backend: `backend/test/catalogos.test.js` (36/36 tests pasando).
- Frontend: `frontend/test/sprint6_catalogos_test.dart` (50/50 tests pasando en toda la suite de Flutter).




