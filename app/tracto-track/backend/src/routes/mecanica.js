/**
 * Rutas de Mecánica — Tracto Trak (SPF)
 *
 * CRUD de órdenes de mecánica / reparación de unidades.
 * Todas las rutas requieren autenticación JWT.
 * La creación y eliminación requieren rol de administrador.
 *
 * GET    /api/mecanica                        — Listar órdenes (filtros: estado, prioridad, camion, tipoServicio)
 * GET    /api/mecanica/resumen/estadisticas   — Resumen estadístico
 * POST   /api/mecanica                        — Crear nueva orden (admin)
 * GET    /api/mecanica/:id                    — Detalle de una orden
 * PUT    /api/mecanica/:id                    — Actualizar orden
 * DELETE /api/mecanica/:id                    — Eliminar orden (soft delete, admin)
 * POST   /api/mecanica/:id/piezas             — Agregar piezas a una orden
 * PUT    /api/mecanica/:id/piezas/:piezaId    — Actualizar una pieza específica
 */
const express = require('express');
const router = express.Router();
const mecanicaController = require('../controllers/mecanicaController');
const { autenticarToken, requerirRol } = require('../middlewares/auth');

// Todas las rutas de mecánica requieren autenticación
router.use(autenticarToken);

// Estadísticas (debe ir antes de /:id para no colisionar)
router.get('/resumen/estadisticas', mecanicaController.obtenerEstadisticas);

// CRUD principal
router.get('/', mecanicaController.listarOrdenes);
router.post('/', requerirRol('administrador'), mecanicaController.crearOrden);
router.get('/:id', mecanicaController.obtenerOrden);
router.put('/:id', mecanicaController.actualizarOrden);
router.delete('/:id', requerirRol('administrador'), mecanicaController.eliminarOrden);

// Piezas dentro de una orden
router.post('/:id/piezas', mecanicaController.agregarPiezas);
router.put('/:id/piezas/:piezaId', mecanicaController.actualizarPieza);

module.exports = router;
