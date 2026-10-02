/**
 * Configuración de la conexión a MongoDB.
 * Base de datos: spf_autotransporte
 * 
 * Usa la variable de entorno MONGODB_URI para conectar.
 * En pruebas se usa mongodb-memory-server (base aislada).
 */
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/spf_autotransporte';
    
    await mongoose.connect(uri);
    
    console.log(`[MongoDB] Conectado a: ${mongoose.connection.name}`);
  } catch (error) {
    console.error('[MongoDB] Error de conexión:', error.message);
    process.exit(1);
  }
};

const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    console.log('[MongoDB] Desconectado');
  } catch (error) {
    console.error('[MongoDB] Error al desconectar:', error.message);
  }
};

module.exports = { connectDB, disconnectDB };
