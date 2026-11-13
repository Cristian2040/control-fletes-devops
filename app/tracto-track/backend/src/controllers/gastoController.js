/**
 * Controlador de Gastos y Auditoría en Ruta (RF-02, US-03, RF-06, US-08, US-08b — Sprints 3 y 8)
 * 
 * Gestiona la captura, validación (Patrón P3 Strategy), consulta,
 * bitácora y auditoría administrativa de gastos e insumos en ruta.
 */
const mongoose = require('mongoose');
const { Gasto, Chofer } = require('../models');
const { gastoValidator } = require('../strategies');

/**
 * Normaliza el tipo de gasto a su valor canónico en minúsculas sin acentos
 */
function normalizarTipoGasto(tipo) {
  if (!tipo) return '';
  const t = String(tipo).toLowerCase().trim();
  if (t === 'diesel' || t === 'diésel') return 'diesel';
  if (t === 'fluidos') return 'fluidos';
  if (t === 'viaticos' || t === 'viáticos') return 'viaticos';
  return t;
}

/**
 * Genera el siguiente folio en formato #TT-###### (Supuesto S-01)
 */
async function generarSiguienteFolio() {
  const ultimoGasto = await Gasto.findOne({ folio: /^#TT-\d{6}$/ }).sort({ folio: -1 });
  let numero = 1;
  if (ultimoGasto && ultimoGasto.folio) {
    const match = ultimoGasto.folio.match(/#TT-(\d+)/);
    if (match) {
      numero = parseInt(match[1], 10) + 1;
    }
  }
  return `#TT-${String(numero).padStart(6, '0')}`;
}

/**
 * POST /api/gastos
 * Registra un nuevo gasto de ruta con validación por Strategy
 */
exports.registrarGasto = async (req, res, next) => {
  try {
    const {
      tipo,
      monto,
      odometro,
      proveedor,
      fotografiaUrl,
      fotografiaBase64,
      fotografia,
      placasCamion,
      folioOffline,
    } = req.body;

    // 1. Validar usando el patrón Strategy (P3)
    const validacion = gastoValidator.validar({
      tipo,
      monto,
      odometro,
      proveedor,
      fotografiaUrl,
      fotografiaBase64,
      fotografia,
    });

    if (!validacion.esValido) {
      return res.status(400).json({
        status: 'fail',
        message: 'Error de validación en la captura de gasto',
        errores: validacion.errores,
      });
    }

    // 2. Resolver chofer asociado al usuario autenticado
    const usuarioId = req.usuario._id || req.usuario.id;
    let choferId = null;
    const choferDoc = await Chofer.findOne({ usuario: usuarioId });
    if (choferDoc) {
      choferId = choferDoc._id;
    }

    // 3. Verificación de Idempotencia: evitar duplicados si ya fue sincronizado previamente
    if (folioOffline) {
      const gastoExistente = await Gasto.findOne({
        usuario: usuarioId,
        folioOffline: String(folioOffline).trim(),
      });
      if (gastoExistente) {
        return res.status(200).json({
          status: 'success',
          message: 'Gasto ya sincronizado previamente',
          data: {
            gasto: gastoExistente,
          },
        });
      }
    }

    // 4. Determinar fotografía final
    const fotoFinal = fotografiaUrl || (fotografiaBase64 ? 'data:image/jpeg;base64,...' : (fotografia || ''));

    // 5. Crear registro de gasto con reintento automático ante concurrencia de folios
    const tipoNormalizado = normalizarTipoGasto(tipo);
    let nuevoGasto;
    let intentos = 0;

    while (intentos < 5) {
      try {
        const folio = await generarSiguienteFolio();
        nuevoGasto = await Gasto.create({
          folio,
          folioOffline: folioOffline ? String(folioOffline).trim() : null,
          tipo: tipoNormalizado,
          monto: Number(monto),
          odometro: odometro !== undefined && odometro !== null && odometro !== '' ? Number(odometro) : null,
          proveedor: String(proveedor).trim(),
          fotografiaUrl: fotoFinal,
          fotografiaBase64: fotografiaBase64 || '',
          compresionOptimizada: true,
          chofer: choferId,
          usuario: usuarioId,
          placasCamion: placasCamion || 'NLZ-8823-A',
          estadoSincronizacion: 'sincronizado',
          estadoAuditoria: 'pendiente',
          fecha: new Date(),
        });
        break; // Éxito
      } catch (err) {
        if (err.code === 11000 && err.keyPattern && err.keyPattern.folio && intentos < 4) {
          intentos++;
          await new Promise((resolve) => setTimeout(resolve, 60 * intentos));
          continue;
        }
        throw err;
      }
    }

    return res.status(201).json({
      status: 'success',
      message: 'Gasto registrado y transmitido correctamente',
      data: {
        gasto: nuevoGasto,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/gastos
 * Consulta la bitácora de gastos (C-05 / A-13).
 * Si el usuario es chofer/operador, lista sus propios gastos.
 * Si es administrador, lista todos los gastos o filtra por consulta.
 */
exports.listarGastos = async (req, res, next) => {
  try {
    const filtro = {};
    const usuarioId = req.usuario._id || req.usuario.id;

    if (req.usuario.rol === 'operador') {
      filtro.usuario = usuarioId;
    } else if (req.query.choferId) {
      // $eq + String() evita inyección NoSQL (p. ej. ?choferId[$ne]=x)
      filtro.chofer = { $eq: String(req.query.choferId) };
    }

    if (req.query.tipo) {
      filtro.tipo = normalizarTipoGasto(req.query.tipo);
    }

    if (req.query.estadoAuditoria) {
      filtro.estadoAuditoria = { $eq: String(req.query.estadoAuditoria) };
    }

    const gastos = await Gasto.find(filtro)
      .sort({ fecha: -1, createdAt: -1 })
      .populate('chofer', 'nombre licencia')
      .populate('usuario', 'nombre username');

    // Calcular estadísticas para C-05 ("Barra de total") y A-13 ("tickets por revisar")
    const totalComprobantes = gastos.length;
    const totalImporte = gastos.reduce((acc, curr) => acc + (curr.monto || 0), 0);
    const pendientesAuditoria = gastos.filter((g) => g.estadoAuditoria === 'pendiente').length;

    return res.status(200).json({
      status: 'success',
      totalComprobantes,
      totalImporte,
      pendientesAuditoria,
      data: {
        gastos,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/gastos/:id
 * Consulta un gasto específico por su ID o Folio
 */
exports.obtenerGastoPorId = async (req, res, next) => {
  try {
    let gasto = null;
    const paramId = decodeURIComponent(req.params.id);

    if (paramId.startsWith('#TT-') || paramId.startsWith('TT-')) {
      const folioNormalizado = paramId.startsWith('#') ? paramId : `#${paramId}`;
      gasto = await Gasto.findOne({ folio: folioNormalizado })
        .populate('chofer', 'nombre licencia')
        .populate('usuario', 'nombre username');
    } else if (mongoose.Types.ObjectId.isValid(paramId)) {
      gasto = await Gasto.findById(paramId)
        .populate('chofer', 'nombre licencia')
        .populate('usuario', 'nombre username');
    }

    if (!gasto) {
      return res.status(404).json({
        status: 'fail',
        message: 'Gasto no encontrado con el identificador proporcionado',
      });
    }

    return res.status(200).json({
      status: 'success',
      data: {
        gasto,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT / PATCH /api/gastos/:id/auditoria
 * Aprueba o rechaza un comprobante de gasto (Sprint 8 — RF-06, US-08, US-08b, A-14).
 */
exports.auditarGasto = async (req, res, next) => {
  try {
    const { estadoAuditoria, motivoRechazo } = req.body;
    const estadoNormalizado = estadoAuditoria
      ? String(estadoAuditoria).toLowerCase().trim()
      : '';

    const estadosPermitidos = ['aprobado', 'rechazado', 'pendiente'];
    if (!estadosPermitidos.includes(estadoNormalizado)) {
      return res.status(400).json({
        status: 'fail',
        message:
          'El estadoAuditoria es obligatorio y debe ser "aprobado", "rechazado" o "pendiente"',
      });
    }

    const paramId = decodeURIComponent(req.params.id);
    let gasto = null;

    if (paramId.startsWith('#TT-') || paramId.startsWith('TT-')) {
      const folioNormalizado = paramId.startsWith('#') ? paramId : `#${paramId}`;
      gasto = await Gasto.findOne({ folio: folioNormalizado });
    } else if (mongoose.Types.ObjectId.isValid(paramId)) {
      gasto = await Gasto.findById(paramId);
    }

    if (!gasto) {
      return res.status(404).json({
        status: 'fail',
        message: 'Comprobante de gasto no encontrado para auditar',
      });
    }

    gasto.estadoAuditoria = estadoNormalizado;
    if (estadoNormalizado === 'rechazado') {
      gasto.motivoRechazo = motivoRechazo
        ? String(motivoRechazo).trim()
        : 'Rechazado en validación fotográfica';
    } else {
      gasto.motivoRechazo = '';
    }

    await gasto.save();
    await gasto.populate('chofer', 'nombre licencia');
    await gasto.populate('usuario', 'nombre username');

    const accionTexto =
      estadoNormalizado === 'aprobado'
        ? 'aprobado'
        : estadoNormalizado === 'rechazado'
          ? 'rechazado'
          : 'marcado como pendiente';

    return res.status(200).json({
      status: 'success',
      message: `Ticket ${gasto.folio} ${accionTexto} exitosamente`,
      data: {
        gasto,
      },
    });
  } catch (error) {
    next(error);
  }
};
