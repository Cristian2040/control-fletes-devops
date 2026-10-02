/**
 * app.js — Aplicación Express del backend Tracto Trak (SPF).
 * 
 * Configura middlewares globales, rutas y manejo de errores.
 * Se exporta por separado del servidor para facilitar las pruebas
 * con Supertest (sin necesidad de levantar el puerto).
 */
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { notFound, errorHandler } = require('./middlewares/errorHandler');
const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');

const app = express();

// --- Middlewares globales ---
app.use(helmet());                         // Cabeceras de seguridad
app.use(cors());                           // CORS habilitado para desarrollo
app.use(express.json({ limit: '10mb' }));  // Parseo de JSON (hasta 10 MB para imágenes base64)
app.use(express.urlencoded({ extended: true }));

// Logging solo en desarrollo
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// --- Rutas ---
app.use('/health', healthRoutes);
app.use('/api/auth', authRoutes);

// --- Manejo de errores ---
app.use(notFound);
app.use(errorHandler);

module.exports = app;
