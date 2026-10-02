/**
 * server.js — Punto de entrada del backend Tracto Trak (SPF).
 * 
 * Carga las variables de entorno, conecta a MongoDB y arranca
 * el servidor Express en el puerto configurado.
 */
require('dotenv').config();

const app = require('./app');
const { connectDB } = require('./config/database');
const config = require('./config');

const iniciar = async () => {
  // Conectar a MongoDB
  await connectDB();

  // Iniciar el servidor HTTP
  const server = app.listen(config.port, () => {
    console.log(`[Servidor] Tracto Trak API ejecutándose en puerto ${config.port}`);
    console.log(`[Servidor] Entorno: ${config.nodeEnv}`);
    console.log(`[Servidor] Health check: http://localhost:${config.port}/health`);
  });

  return server;
};

iniciar().catch((error) => {
  console.error('[Servidor] Error al iniciar:', error.message);
  process.exit(1);
});
