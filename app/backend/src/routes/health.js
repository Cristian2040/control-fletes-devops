/**
 * Rutas de salud del servidor.
 * GET /health — Verificación de conectividad con la API y MongoDB.
 */
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

/**
 * GET /health
 * Responde con el estado del servidor y la conexión a la base de datos.
 */
router.get('/', (req, res) => {
  const dbState = mongoose.connection.readyState;
  const estadosDB = {
    0: 'desconectado',
    1: 'conectado',
    2: 'conectando',
    3: 'desconectando',
  };

  res.json({
    ok: true,
    mensaje: 'Tracto Trak API — Sistema de Gestión para el Autotransporte de Carga (SPF)',
    version: '1.0.0',
    servidor: 'activo',
    baseDeDatos: estadosDB[dbState] || 'desconocido',
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
