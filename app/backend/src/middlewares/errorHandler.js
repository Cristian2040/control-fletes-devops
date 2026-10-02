/**
 * Middleware de manejo centralizado de errores.
 * Captura errores no manejados y responde con un JSON estandarizado.
 */

// Middleware para rutas no encontradas
const notFound = (req, res, next) => {
  res.status(404).json({
    ok: false,
    mensaje: `Ruta no encontrada: ${req.method} ${req.originalUrl}`,
  });
};

// Middleware de manejo de errores general
const errorHandler = (err, req, res, _next) => {
  console.error('[Error]', err.message);

  // Errores de validación de Mongoose
  if (err.name === 'ValidationError') {
    const mensajes = Object.values(err.errors).map((e) => e.message);
    return res.status(400).json({
      ok: false,
      mensaje: 'Error de validación',
      errores: mensajes,
    });
  }

  // Errores de clave duplicada en MongoDB
  if (err.code === 11000) {
    const campo = Object.keys(err.keyValue).join(', ');
    return res.status(409).json({
      ok: false,
      mensaje: `El valor de "${campo}" ya existe en el sistema`,
    });
  }

  // Error genérico
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    ok: false,
    mensaje: err.message || 'Error interno del servidor',
  });
};

module.exports = { notFound, errorHandler };
