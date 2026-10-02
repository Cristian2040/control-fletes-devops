/**
 * Modelo: Chofer
 * Colección: choferes
 * 
 * Catálogo operativo de choferes (RF-05).
 * Campos según pantalla A-10 (Alta en Catálogo – Choferes):
 *   - nombre, licencia (tipo y número), telefono
 * 
 * Campos adicionales de la pantalla C-06 (Perfil de Operador):
 *   - usuario (referencia al modelo Usuario para login)
 *   - empresa, rutaAsignada
 * 
 * Estados posibles (pantalla A-06):
 *   - 'disponible', 'en_ruta', 'inactivo'
 */
const mongoose = require('mongoose');

const choferSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre completo del chofer es obligatorio'],
    trim: true,
  },
  licencia: {
    type: String,
    required: [true, 'El tipo y número de licencia federal es obligatorio'],
    trim: true,
  },
  telefono: {
    type: String,
    required: [true, 'El teléfono celular es obligatorio'],
    trim: true,
  },
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    default: null,
  },
  empresa: {
    type: String,
    trim: true,
    default: '',
  },
  estado: {
    type: String,
    enum: {
      values: ['disponible', 'en_ruta', 'inactivo'],
      message: 'El estado debe ser "disponible", "en_ruta" o "inactivo"',
    },
    default: 'disponible',
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'choferes',
});

module.exports = mongoose.model('Chofer', choferSchema);
