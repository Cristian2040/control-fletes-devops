/**
 * Modelo: Cliente
 * Colección: clientes
 * 
 * Catálogo operativo de clientes (RF-05).
 * Campos según pantalla A-11 (Alta en Catálogo – Clientes):
 *   - razonSocial, rfc, diasCredito
 * 
 * Campos adicionales de la pantalla A-07:
 *   - estado ('activo' / 'inactivo')
 */
const mongoose = require('mongoose');

const clienteSchema = new mongoose.Schema({
  razonSocial: {
    type: String,
    required: [true, 'La razón social es obligatoria'],
    trim: true,
  },
  rfc: {
    type: String,
    required: [true, 'El RFC es obligatorio'],
    trim: true,
    uppercase: true,
  },
  diasCredito: {
    type: Number,
    required: [true, 'Los días de crédito son obligatorios'],
    min: [0, 'Los días de crédito no pueden ser negativos'],
    default: 0,
  },
  estado: {
    type: String,
    enum: {
      values: ['activo', 'inactivo'],
      message: 'El estado debe ser "activo" o "inactivo"',
    },
    default: 'activo',
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'clientes',
});

module.exports = mongoose.model('Cliente', clienteSchema);
