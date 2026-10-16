/**
 * Configuración centralizada de variables de entorno.
 * Todas las variables se leen desde .env mediante dotenv.
 */
require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/spf_autotransporte',
  jwtSecret: process.env.JWT_SECRET || 'cambiar_este_secreto_en_produccion',
  nodeEnv: process.env.NODE_ENV || 'development',
  storageType: process.env.STORAGE_TYPE || 'local',
  // Orígenes permitidos por CORS (lista separada por comas). La app móvil no usa CORS.
  corsOrigins: (process.env.CORS_ORIGIN || 'http://localhost:3000,http://localhost:8080')
    .split(',')
    .map((o) => o.trim()),
};
