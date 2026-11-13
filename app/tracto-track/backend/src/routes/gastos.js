/**
 * Rutas de Gastos, Insumos y Auditoría en Ruta (RF-02, US-03, RF-06, US-08, US-08b — Sprints 3 y 8)
 */
const express = require('express');
const router = express.Router();

const gastoController = require('../controllers/gastoController');
const { autenticarToken } = require('../middlewares/auth');

// Todas las rutas de gastos requieren token JWT autenticado (RNF-04)
router.use(autenticarToken);

router.post('/', gastoController.registrarGasto);
router.get('/', gastoController.listarGastos);
router.get('/:id', gastoController.obtenerGastoPorId);
router.put('/:id/auditoria', gastoController.auditarGasto);
router.patch('/:id/auditoria', gastoController.auditarGasto);

module.exports = router;
