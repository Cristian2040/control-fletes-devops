/**
 * Modelo: Camion
 * Colección: camiones
 * 
 * Catálogo operativo de unidades de la flota (RF-05).
 * Campos según pantalla A-09 (Alta en Catálogo – Camiones):
 *   - placas, marca, modelo, anio, capacidadCarga
 * 
 * Estados posibles (pantalla A-05):
 *   - 'disponible', 'en_ruta', 'en_taller'
 */
const mongoose = require('mongoose');

const camionSchema = new mongoose.Schema({
  placas: {
    type: String,
    required: [true, 'Las placas del camión son obligatorias'],
    unique: true,
    trim: true,
    uppercase: true,
  },
  marca: {
    type: String,
    required: [true, 'La marca es obligatoria'],
    trim: true,
  },
  modelo: {
    type: String,
    required: [true, 'El modelo es obligatorio'],
    trim: true,
  },
  anio: {
    type: Number,
    required: [true, 'El año es obligatorio'],
  },
  capacidadCarga: {
    type: Number,
    required: [true, 'La capacidad de carga (toneladas) es obligatoria'],
    min: [0, 'La capacidad de carga no puede ser negativa'],
  },
  kilometraje: {
    type: Number,
    default: 0,
    min: 0,
  },
  estado: {
    type: String,
    enum: {
      values: ['disponible', 'en_ruta', 'en_taller'],
      message: 'El estado debe ser "disponible", "en_ruta" o "en_taller"',
    },
    default: 'disponible',
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'camiones',
});

module.exports = mongoose.model('Camion', camionSchema);
