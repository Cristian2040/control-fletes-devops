/**
 * Rutas de Gastos e Insumos (RF-02, US-03, Sprint 3)
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

module.exports = router;
