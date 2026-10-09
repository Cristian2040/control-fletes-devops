/**
 * Controlador de Gastos (RF-02, US-03, Sprint 3)
 * 
 * Gestiona la captura, validación (Patrón P3 Strategy), consulta
 * y bitácora de gastos e insumos en ruta.
 */
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
  const ultimoGasto = await Gasto.findOne({}, {}, { sort: { createdAt: -1 } });
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

    // 3. Generar folio secuencial
    const folio = await generarSiguienteFolio();

    // 4. Determinar fotografía final
    const fotoFinal = fotografiaUrl || (fotografiaBase64 ? 'data:image/jpeg;base64,...' : (fotografia || ''));

    // 5. Crear registro de gasto
    const tipoNormalizado = normalizarTipoGasto(tipo);
    const nuevoGasto = await Gasto.create({
      folio,
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
      filtro.chofer = req.query.choferId;
    }


    if (req.query.tipo) {
      filtro.tipo = normalizarTipoGasto(req.query.tipo);
    }

    if (req.query.estadoAuditoria) {
      filtro.estadoAuditoria = req.query.estadoAuditoria;
    }

    const gastos = await Gasto.find(filtro)
      .sort({ fecha: -1, createdAt: -1 })
      .populate('chofer', 'nombre licencia');

    // Calcular estadísticas para C-05 ("Barra de total")
    const totalComprobantes = gastos.length;
    const totalImporte = gastos.reduce((acc, curr) => acc + (curr.monto || 0), 0);

    return res.status(200).json({
      status: 'success',
      totalComprobantes,
      totalImporte,
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
    if (req.params.id.startsWith('#TT-')) {
      gasto = await Gasto.findOne({ folio: req.params.id }).populate('chofer', 'nombre licencia');
    } else {
      gasto = await Gasto.findById(req.params.id).populate('chofer', 'nombre licencia');
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
