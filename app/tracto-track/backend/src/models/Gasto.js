/**
 * Modelo: Gasto
 * Colección: gastos
 * 
 * Registros de gastos e insumos en ruta (RF-02, US-03).
 * Tipos de gasto: 'diesel', 'fluidos', 'viaticos'.
 * Folio generado según S-01: #TT-###### (autoincrementado).
 * 
 * Reglas de negocio:
 *   - Fotografía del comprobante obligatoria en todos los tipos (US-03).
 *   - Lectura de odómetro obligatoria para Diésel y Fluidos (Strategy P3).
 *   - Lectura de odómetro opcional para Viáticos (Strategy P3).
 */
const mongoose = require('mongoose');

const gastoSchema = new mongoose.Schema({
  folio: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    match: [/^#TT-\d{6}$/, 'El folio debe tener el formato #TT-######'],
  },
  tipo: {
    type: String,
    required: [true, 'El tipo de gasto es obligatorio'],
    enum: {
      values: ['diesel', 'fluidos', 'viaticos'],
      message: 'El tipo debe ser "diesel", "fluidos" o "viaticos"',
    },
    lowercase: true,
    trim: true,
  },
  monto: {
    type: Number,
    required: [true, 'El monto del comprobante es obligatorio'],
    min: [0.01, 'El monto debe ser mayor a 0'],
  },
  odometro: {
    type: Number,
    min: [0, 'El odómetro no puede ser negativo'],
    default: null,
  },
  proveedor: {
    type: String,
    required: [true, 'El proveedor o estación de carga es obligatorio'],
    trim: true,
  },
  fotografiaUrl: {
    type: String,
    default: '',
    trim: true,
  },
  fotografiaBase64: {
    type: String,
    default: '',
  },
  compresionOptimizada: {
    type: Boolean,
    default: true, // RNF-03 / US-09comp: Compresión activa
  },
  chofer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Chofer',
    default: null,
  },
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    required: [true, 'El usuario que registra el gasto es obligatorio'],
  },
  camion: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Camion',
    default: null,
  },
  placasCamion: {
    type: String,
    default: 'NLZ-8823-A',
  },
  estadoSincronizacion: {
    type: String,
    enum: ['sincronizado', 'pendiente'],
    default: 'sincronizado',
  },
  estadoAuditoria: {
    type: String,
    enum: ['pendiente', 'aprobado', 'rechazado'],
    default: 'pendiente',
  },
  motivoRechazo: {
    type: String,
    default: '',
  },
  fecha: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
  collection: 'gastos',
});

// Índice para consultas rápidas por chofer y fecha
gastoSchema.index({ usuario: 1, fecha: -1 });
gastoSchema.index({ chofer: 1, fecha: -1 });

module.exports = mongoose.model('Gasto', gastoSchema);
