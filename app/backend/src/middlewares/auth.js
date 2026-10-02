/**
 * Middleware de Autenticación y Autorización JWT — Tracto Trak (SPF)
 * 
 * Protege rutas privadas mediante la verificación de tokens JWT (RNF-04).
 */
const jwt = require('jsonwebtoken');
const config = require('../config');

/**
 * Middleware: Verifica que el request incluya un token JWT válido.
 * Extrae la cabecera: Authorization: Bearer <token>
 */
const autenticarToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      ok: false,
      mensaje: 'Acceso denegado: Token de autenticación no proporcionado',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    req.usuario = decoded; // { id, rol, username, iat, exp }
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        ok: false,
        mensaje: 'Sesión expirada. Por favor inicie sesión nuevamente.',
        codigo: 'TOKEN_EXPIRADO',
      });
    }

    return res.status(401).json({
      ok: false,
      mensaje: 'Token de autenticación inválido',
    });
  }
};

/**
 * Middleware: Restringe el acceso únicamente a usuarios con los roles especificados.
 * Ejemplo: requerirRol('administrador') o requerirRol('operador', 'administrador')
 */
const requerirRol = (...rolesPermitidos) => {
  return (req, res, next) => {
    if (!req.usuario) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Usuario no autenticado',
      });
    }

    if (!rolesPermitidos.includes(req.usuario.rol)) {
      return res.status(403).json({
        ok: false,
        mensaje: `Acceso no autorizado. Se requiere rol: ${rolesPermitidos.join(' o ')}`,
      });
    }

    next();
  };
};

module.exports = {
  autenticarToken,
  requerirRol,
};
