/**
 * Rutas de Catálogos Operativos (RF-05, Sprint 6)
 * Camiones (A-05, A-09), Choferes (A-06, A-10), Clientes (A-07, A-11), Tarifas (A-08, A-12)
 */
const express = require('express');
const router = express.Router();
const catalogoController = require('../controllers/catalogoController');
const { autenticarToken } = require('../middlewares/auth');

// Todas las rutas de catálogos requieren autenticación JWT (RNF-04)
router.use(autenticarToken);

// 1. Camiones
router.get('/camiones', catalogoController.listarCamiones);
router.post('/camiones', catalogoController.crearCamion);
router.get('/camiones/:id', catalogoController.obtenerCamionPorId);

// 2. Choferes
router.get('/choferes', catalogoController.listarChoferes);
router.post('/choferes', catalogoController.crearChofer);

// 3. Clientes
router.get('/clientes', catalogoController.listarClientes);
router.post('/clientes', catalogoController.crearCliente);

// 4. Tarifas
router.get('/tarifas', catalogoController.listarTarifas);
router.post('/tarifas', catalogoController.crearTarifa);

module.exports = router;
