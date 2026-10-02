/**
 * Controlador de Autenticación — Tracto Trak (SPF)
 * 
 * Maneja el registro e inicio de sesión de usuarios (Choferes y Administradores).
 */
const jwt = require('jsonwebtoken');
const Usuario = require('../models/Usuario');
const Chofer = require('../models/Chofer');
const config = require('../config');

/**
 * Genera un token JWT firmado.
 */
const generarToken = (id, rol, username) => {
  return jwt.sign(
    { id, rol, username },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn || '24h' }
  );
};

/**
 * POST /api/auth/register
 * Registra un nuevo usuario en la plataforma (RF-01, RNF-04).
 */
const register = async (req, res, next) => {
  try {
    const { username, password, nombre, email, rol, telefono, licencia } = req.body;

    // Validación básica de campos requeridos
    if (!username || !password || !nombre || !rol) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Campos obligatorios faltantes: username, password, nombre y rol son requeridos',
      });
    }

    // Validar rol válido
    const rolNormalizado = rol.toLowerCase().trim();
    const rolesValidos = ['operador', 'administrador', 'chofer', 'admin'];
    if (!rolesValidos.includes(rolNormalizado)) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Rol no válido. Debe ser "operador" (chofer) o "administrador"',
      });
    }

    // Mapear nombres amigables al enum del modelo
    const rolMapeado = (rolNormalizado === 'chofer' || rolNormalizado === 'operador')
      ? 'operador'
      : 'administrador';

    // Verificar si el usuario ya existe
    const usuarioExistente = await Usuario.findOne({ username: username.toLowerCase().trim() });
    if (usuarioExistente) {
      return res.status(400).json({
        ok: false,
        mensaje: 'El nombre de usuario ya está registrado en el sistema',
      });
    }

    // Crear el usuario
    const nuevoUsuario = await Usuario.create({
      username,
      password,
      nombre,
      email: email || '',
      rol: rolMapeado,
    });

    // Si el rol es operador/chofer, crear registro en el catálogo de choferes
    if (rolMapeado === 'operador') {
      await Chofer.create({
        usuarioId: nuevoUsuario._id,
        nombre: nuevoUsuario.nombre,
        telefono: telefono || '',
        licenciaTipo: (licencia && licencia.tipo) || 'Tipo B (SPF carga)',
        licenciaNumero: (licencia && licencia.numero) || 'N/A',
      }).catch(err => {
        // Loguear pero no interrumpir el registro del usuario
        console.warn('Advertencia al crear registro de Chofer:', err.message);
      });
    }

    // Generar token JWT
    const token = generarToken(nuevoUsuario._id, nuevoUsuario.rol, nuevoUsuario.username);

    res.status(201).json({
      ok: true,
      mensaje: 'Usuario registrado exitosamente',
      token,
      usuario: {
        id: nuevoUsuario._id,
        username: nuevoUsuario.username,
        nombre: nuevoUsuario.nombre,
        rol: nuevoUsuario.rol,
        email: nuevoUsuario.email,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/login
 * Autentica un usuario y devuelve un token JWT.
 */
const login = async (req, res, next) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Se requiere nombre de usuario y contraseña',
      });
    }

    const usuario = await Usuario.findOne({ username: username.toLowerCase().trim() });
    if (!usuario) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Credenciales inválidas (usuario no encontrado)',
      });
    }

    if (!usuario.activo) {
      return res.status(403).json({
        ok: false,
        mensaje: 'El usuario se encuentra inactivo. Contacte al administrador.',
      });
    }

    const esPasswordCorrecto = await usuario.compararPassword(password);
    if (!esPasswordCorrecto) {
      return res.status(401).json({
        ok: false,
        mensaje: 'Credenciales inválidas (contraseña incorrecta)',
      });
    }

    const token = generarToken(usuario._id, usuario.rol, usuario.username);

    res.json({
      ok: true,
      mensaje: 'Inicio de sesión exitoso',
      token,
      usuario: {
        id: usuario._id,
        username: usuario.username,
        nombre: usuario.nombre,
        rol: usuario.rol,
        email: usuario.email,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/auth/perfil
 * Retorna la información del usuario actualmente autenticado (requiere token JWT).
 */
const obtenerPerfil = async (req, res, next) => {
  try {
    const usuario = await Usuario.findById(req.usuario.id);
    if (!usuario) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Usuario no encontrado',
      });
    }

    res.json({
      ok: true,
      usuario: {
        id: usuario._id,
        username: usuario.username,
        nombre: usuario.nombre,
        rol: usuario.rol,
        email: usuario.email,
        activo: usuario.activo,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  obtenerPerfil,
};
