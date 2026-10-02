/**
 * Rutas de Autenticación
 * POST /api/auth/register — Registro de nuevo usuario
 * POST /api/auth/login — Inicio de sesión
 */
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { autenticarToken } = require('../middlewares/auth');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/perfil', autenticarToken, authController.obtenerPerfil);

module.exports = router;
