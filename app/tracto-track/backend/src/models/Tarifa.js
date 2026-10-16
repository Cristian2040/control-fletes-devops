/**
 * Modelo: Tarifa
 * Colección: tarifas
 * 
 * Catálogo operativo de tarifas base pactadas por ruta (RF-05).
 * Campos según pantallas A-08 y A-12:
 *   - ruta: Tramo o ruta pactada (ej. 'Monterrey → CDMX')
 *   - tipoCarga: 'General', 'Refrigerada', etc.
 *   - capacidadTon: Capacidad estimada en toneladas
 *   - montoBase: Monto pactado en MXN (ej. 18500.0)
 *   - estado: 'activa', 'inactiva'
 */
const mongoose = require('mongoose');

const tarifaSchema = new mongoose.Schema({
  ruta: {
    type: String,
    required: [true, 'La ruta o tramo pactado es obligatorio'],
    trim: true,
  },
  tipoCarga: {
    type: String,
    required: [true, 'El tipo de carga es obligatorio'],
    trim: true,
    default: 'General',
  },
  capacidadTon: {
    type: Number,
    min: [0, 'La capacidad no puede ser negativa'],
    default: 25,
  },
  montoBase: {
    type: Number,
    required: [true, 'El monto de tarifa base (MXN) es obligatorio'],
    min: [0, 'El monto de la tarifa no puede ser negativo'],
  },
  estado: {
    type: String,
    enum: {
      values: ['activa', 'inactiva'],
      message: 'El estado debe ser "activa" o "inactiva"',
    },
    default: 'activa',
  },
  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'tarifas',
});

module.exports = mongoose.model('Tarifa', tarifaSchema);
