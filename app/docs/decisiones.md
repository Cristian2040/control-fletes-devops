# Decisiones de diseño y supuestos de partida

Este documento registra los supuestos aplicados y las decisiones tomadas ante ambigüedades en los documentos fuente.

---

## Supuestos de partida

### S-01: Formato de folio de gasto
- **Formato:** `#TT-######` (tomado de la pantalla C-04)
- **Generación:** autoincrementado en el backend al crear el registro.

### S-02: Formato de folio de flete
- **Formato:** `FL-###` (tomado de A-03)
- **Generación:** autoincrementado en el backend al crear el flete.

### S-03: Fórmula de liquidación (A-16, US-13)
```
Saldo final del chofer = Tarifa cobrada al cliente − Anticipo entregado − Gastos validados
```
Solo se consideran como "gastos validados" los tickets en estado **aprobado**.
- Deducida del ejemplo de A-16: `18,500 − 9,250 − 380 = 8,870`.

### S-04: Almacenamiento de imágenes
- Se define una interfaz/adaptador de almacenamiento con:
  - Implementación **local** de desarrollo (`backend/uploads/`, ignorada en Git).
  - Implementación para **Firebase Storage** o **S3**, configurable por variables de entorno (`STORAGE_TYPE`).
- Se puede probar sin credenciales externas usando `STORAGE_TYPE=local`.
- MongoDB guarda solo la URL/ruta de la imagen, nunca el binario.

### S-05: Panel administrativo
- El panel administrativo es **móvil**, dentro de la misma app Flutter (RF-05, RF-06).
- **No** se construye un panel web, aunque el apartado 1 de los documentos lo mencione como parte del MVP.

### S-06: Versión de Node.js
- El entorno documentado usa **Node 16.20.2** (End of Life desde septiembre de 2023).
- El código se mantiene compatible con Node 16 pero evita dependencias que impidan migrar.

> **Recomendación:** actualizar a **Node 18 LTS** o **Node 20 LTS** en cuanto sea posible para recibir parches de seguridad y soporte activo. La migración no debería requerir cambios en el código del backend.

### S-07: Datos de ejemplo (seed)
Se usan los datos que aparecen en las pantallas de los wireframes:
- **Chofer:** Jorge González, usuario `jgonzalez`
- **Unidad:** placas NLZ-8823-A, Kenworth T680, año 2021
- **Empresa:** Transportes Flores S.A.
- **Clientes:** CEMEX S.A. de C.V., Gruma Internacional
- **Tarifas:** Monterrey–CDMX, San Luis Potosí–GDL

### S-08: Pantallas con destino no implementado
- Mientras un Sprint no construye el destino de una navegación, esta lleva a una pantalla **placeholder** claramente marcada (ej. "Pendiente: A-13, Sprint 8").
- Esto garantiza que el flujo nunca se rompa y que el avance por Sprint sea incremental.

---

## Decisiones tomadas durante el desarrollo

### D-01: Separación app.js / server.js (Sprint 1)
- **Decisión:** separar la configuración de Express (`app.js`) del arranque del servidor (`server.js`).
- **Razón:** permite importar `app` en las pruebas con Supertest sin levantar un puerto real, mejorando el aislamiento de las pruebas.

### D-02: Base de datos de prueba (Sprint 1)
- **Decisión:** usar `mongodb-memory-server` para las pruebas en lugar de una instancia real de MongoDB.
- **Razón:** aislamiento completo; no requiere tener MongoDB instalado ni corriendo para ejecutar `npm test`.

### D-03: Selector de rol en pantalla de login (Sprint 1)
- **Decisión:** la pantalla de login C-01/A-01 es la misma pantalla con un selector segmentado de rol, tal como muestran los wireframes.
- **Razón:** el documento de interfaces muestra el mismo diseño para ambas pantallas, diferenciando solo cuál pestaña del selector está activa.

### D-04: Uso de `http` package para cliente HTTP (Sprint 1)
- **Decisión:** usar el paquete `http` de Dart en lugar de `dio`.
- **Razón:** es más ligero, es mantenido por el equipo de Dart y cubre las necesidades del `ApiClient` sin dependencias adicionales.
