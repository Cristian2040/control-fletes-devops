/**
 * Modelo: Usuario
 * Colección: usuarios
 * 
 * Soporta dos roles (RF-01):
 *   - 'operador'      → Chofer en ruta (pantallas C-01 a C-06)
 *   - 'administrador'  → Dueño de flota (pantallas A-01 a A-17)
 * 
 * La contraseña se almacena hasheada con bcrypt (RNF-04).
 */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const usuarioSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'El identificador de usuario es obligatorio'],
    unique: true,
    trim: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: [true, 'La contraseña es obligatoria'],
    minlength: [6, 'La contraseña debe tener al menos 6 caracteres'],
  },
  nombre: {
    type: String,
    required: [true, 'El nombre es obligatorio'],
    trim: true,
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    default: '',
  },
  rol: {
    type: String,
    enum: {
      values: ['operador', 'administrador'],
      message: 'El rol debe ser "operador" o "administrador"',
    },
    required: [true, 'El rol es obligatorio'],
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'usuarios',
});

// Hook pre-save: hashear la contraseña si fue modificada
usuarioSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Método de instancia: comparar contraseña en texto plano con el hash
usuarioSchema.methods.compararPassword = async function (passwordPlano) {
  return bcrypt.compare(passwordPlano, this.password);
};

// Excluir la contraseña del JSON de respuesta
usuarioSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('Usuario', usuarioSchema);
