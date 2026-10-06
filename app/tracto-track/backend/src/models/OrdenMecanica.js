/**
 * Modelo: OrdenMecanica
 * Colección: ordenes_mecanica
 *
 * Registro de reportes de daño, diagnóstico y reparación de unidades (camiones/tráilers).
 *
 * Campos principales:
 *   - camion: referencia al camión/tráiler dañado
 *   - descripcionFalla: descripción del problema reportado
 *   - tipoServicio: correctivo o preventivo
 *   - prioridad: alta, media, baja
 *   - estado: reportada → en_diagnostico → en_reparacion → completada | cancelada
 *   - tiempoEstimadoHoras: horas estimadas para el arreglo
 *   - fechaEstimadaEntrega: fecha estimada de liberación de la unidad
 *   - piezas[]: lista de refacciones necesarias con costo y estado individual
 *   - costoEstimado / costoFinal: presupuesto y cierre financiero
 *   - evidenciasFotos[]: URLs de fotografías del daño
 *   - kilometrajeAlIngreso: odómetro al momento de ingresar al taller
 *   - reportadoPor / mecanicoAsignado: trazabilidad de responsables
 */
const mongoose = require('mongoose');

// --- Sub-documento: Pieza / Refacción ---
const piezaSchema = new mongoose.Schema({
  nombre: {
    type: String,
    required: [true, 'El nombre de la pieza es obligatorio'],
    trim: true,
  },
  numeroParte: {
    type: String,
    trim: true,
    default: '',
  },
  cantidad: {
    type: Number,
    required: [true, 'La cantidad es obligatoria'],
    min: [1, 'La cantidad mínima es 1'],
    default: 1,
  },
  costoUnitario: {
    type: Number,
    min: [0, 'El costo no puede ser negativo'],
    default: 0,
  },
  proveedor: {
    type: String,
    trim: true,
    default: '',
  },
  estado: {
    type: String,
    enum: {
      values: ['pendiente', 'solicitada', 'recibida', 'instalada'],
      message: 'El estado de la pieza debe ser "pendiente", "solicitada", "recibida" o "instalada"',
    },
    default: 'pendiente',
  },
}, { _id: true });

// --- Documento principal: Orden de Mecánica ---
const ordenMecanicaSchema = new mongoose.Schema({
  folio: {
    type: String,
    unique: true,
    trim: true,
  },
  camion: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Camion',
    required: [true, 'La unidad (camión/tráiler) es obligatoria'],
  },
  descripcionFalla: {
    type: String,
    required: [true, 'La descripción de la falla es obligatoria'],
    trim: true,
  },
  tipoServicio: {
    type: String,
    enum: {
      values: ['correctivo', 'preventivo'],
      message: 'El tipo de servicio debe ser "correctivo" o "preventivo"',
    },
    default: 'correctivo',
  },
  prioridad: {
    type: String,
    enum: {
      values: ['alta', 'media', 'baja'],
      message: 'La prioridad debe ser "alta", "media" o "baja"',
    },
    default: 'media',
  },
  estado: {
    type: String,
    enum: {
      values: ['reportada', 'en_diagnostico', 'en_reparacion', 'completada', 'cancelada'],
      message: 'Estado no válido',
    },
    default: 'reportada',
  },

  // --- Tiempos ---
  fechaIngreso: {
    type: Date,
    default: Date.now,
  },
  tiempoEstimadoHoras: {
    type: Number,
    min: [0, 'El tiempo estimado no puede ser negativo'],
    default: 0,
  },
  fechaEstimadaEntrega: {
    type: Date,
    default: null,
  },
  fechaRealEntrega: {
    type: Date,
    default: null,
  },

  // --- Diagnóstico y reparación ---
  diagnostico: {
    type: String,
    trim: true,
    default: '',
  },
  trabajoRealizado: {
    type: String,
    trim: true,
    default: '',
  },

  // --- Piezas / Refacciones ---
  piezas: [piezaSchema],

  // --- Costos ---
  costoEstimado: {
    type: Number,
    min: [0, 'El costo estimado no puede ser negativo'],
    default: 0,
  },
  costoManoObra: {
    type: Number,
    min: [0, 'El costo de mano de obra no puede ser negativo'],
    default: 0,
  },
  costoFinal: {
    type: Number,
    min: [0, 'El costo final no puede ser negativo'],
    default: 0,
  },

  // --- Evidencias ---
  evidenciasFotos: [{
    type: String,
    trim: true,
  }],

  // --- Kilometraje ---
  kilometrajeAlIngreso: {
    type: Number,
    min: [0, 'El kilometraje no puede ser negativo'],
    default: 0,
  },

  // --- Responsables ---
  reportadoPor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Usuario',
    default: null,
  },
  mecanicoAsignado: {
    type: String,
    trim: true,
    default: '',
  },

  // --- Notas adicionales ---
  notas: {
    type: String,
    trim: true,
    default: '',
  },

  activo: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
  collection: 'ordenes_mecanica',
});

// Hook pre-save: Generar folio autoincremental OM-XXXX
ordenMecanicaSchema.pre('save', async function (next) {
  if (!this.folio) {
    const count = await mongoose.model('OrdenMecanica').countDocuments();
    this.folio = `OM-${String(count + 1).padStart(4, '0')}`;
  }
  next();
});

// Virtual: costo total de piezas
ordenMecanicaSchema.virtual('costoPiezas').get(function () {
  return this.piezas.reduce((total, pieza) => {
    return total + (pieza.costoUnitario * pieza.cantidad);
  }, 0);
});

// Incluir virtuals en JSON y Object
ordenMecanicaSchema.set('toJSON', { virtuals: true });
ordenMecanicaSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('OrdenMecanica', ordenMecanicaSchema);
