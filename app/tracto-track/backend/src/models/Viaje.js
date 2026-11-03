/**
 * Modelo: Viaje (Flete / Despacho)
 * Colección: viajes
 *
 * Representa las órdenes de viaje y despachos activos (RF-05, US-07, A-03, A-04).
 * Formato de folio según S-02: FL-### (autoincrementado).
 */
const mongoose = require('mongoose');

const viajeSchema = new mongoose.Schema({
  folio: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    match: [/^FL-\d{3,}$/, 'El folio de flete debe tener el formato FL-###'],
  },
  cliente: {
    type: String,
    required: [true, 'El cliente solicitante es obligatorio'],
    trim: true,
  },
  origen: {
    type: String,
    required: [true, 'El origen del viaje es obligatorio'],
    trim: true,
  },
  destino: {
    type: String,
    required: [true, 'El destino del viaje es obligatorio'],
    trim: true,
  },
  ruta: {
    type: String,
    trim: true,
  },
  camion: {
    type: String,
    required: [true, 'El tractocamión asignado es obligatorio'],
    trim: true,
  },
  placasCamion: {
    type: String,
    default: 'NLZ-8823-A',
    trim: true,
  },
  chofer: {
    type: String,
    required: [true, 'El chofer designado es obligatorio'],
    trim: true,
  },
  tarifaPactada: {
    type: Number,
    required: [true, 'La tarifa pactada es obligatoria'],
    min: [0.01, 'La tarifa pactada debe ser mayor a 0'],
  },
  anticipoEntregado: {
    type: Number,
    default: 0,
    min: [0, 'El anticipo no puede ser negativo'],
  },
  estado: {
    type: String,
    enum: ['en_ruta', 'completado', 'liquidado', 'cancelado'],
    default: 'en_ruta',
  },
  fechaSalida: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
  collection: 'viajes',
});

// Pre-save para asegurar el formato de ruta si no fue provisto
viajeSchema.pre('save', function (next) {
  if (!this.ruta && this.origen && this.destino) {
    this.ruta = `${this.origen} → ${this.destino}`;
  }
  next();
});

module.exports = mongoose.model('Viaje', viajeSchema);
