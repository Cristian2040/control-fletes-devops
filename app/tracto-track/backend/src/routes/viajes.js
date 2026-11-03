/**
 * Rutas de Viajes, Fletes y Tablero de Control (Sprint 7)
 *
 * Protegidas mediante autenticación JWT.
 *   - GET  /api/tablero/resumen (A-02, RNF-01)
 *   - GET  /api/viajes          (A-03)
 *   - POST /api/viajes          (A-04, RF-05, US-07)
 */
const express = require('express');
const router = express.Router();
const { autenticarToken } = require('../middlewares/auth');
const viajeController = require('../controllers/viajeController');

router.use(autenticarToken);

router.get('/tablero/resumen', viajeController.obtenerTableroResumen);
router.get('/viajes', viajeController.listarViajes);
router.post('/viajes', viajeController.crearViaje);

module.exports = router;
