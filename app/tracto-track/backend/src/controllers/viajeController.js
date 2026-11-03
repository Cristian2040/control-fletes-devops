/**
 * Controlador de Viajes, Despachos y Tablero de Control (Sprint 7)
 *
 * Cubre:
 *   - A-02 · Tablero / Panel de Control (RNF-01) -> GET /api/tablero/resumen
 *   - A-03 · Módulo de Viajes y Fletes          -> GET /api/viajes
 *   - A-04 · Asignación de Viaje (RF-05, US-07) -> POST /api/viajes
 *
 * Formato de folio oficial según S-02: FL-### (ej. FL-101, FL-102).
 */
const { Viaje, Gasto, Camion } = require('../models');

/**
 * Inicializa datos semilla para viajes activos cuando el entorno no es test.
 */
async function asegurarViajesSemilla() {
  try {
    const totalViajes = await Viaje.countDocuments();
    if (totalViajes === 0) {
      await Viaje.insertMany([
        {
          folio: 'FL-101',
          cliente: 'CEMEX S.A. de C.V.',
          origen: 'Monterrey',
          destino: 'CDMX',
          ruta: 'Monterrey → CDMX',
          camion: 'Kenworth T680 (NLZ-8823-A)',
          placasCamion: 'NLZ-8823-A',
          chofer: 'Jorge González',
          tarifaPactada: 18500.0,
          anticipoEntregado: 5000.0,
          estado: 'en_ruta',
        },
        {
          folio: 'FL-102',
          cliente: 'Gruma Internacional',
          origen: 'San Luis Potosí',
          destino: 'GDL',
          ruta: 'San Luis Potosí → GDL',
          camion: 'Freightliner Cascadia (SPF-4412-B)',
          placasCamion: 'SPF-4412-B',
          chofer: 'Raúl Mendoza',
          tarifaPactada: 14200.0,
          anticipoEntregado: 4000.0,
          estado: 'en_ruta',
        },
      ]);
    }
  } catch (_) {}
}

if (process.env.NODE_ENV !== 'test') {
  asegurarViajesSemilla();
}

/**
 * Genera el siguiente folio consecutivo con formato FL-### (mínimo 3 dígitos, iniciando en FL-101).
 */
async function generarSiguienteFolioViaje() {
  const ultimo = await Viaje.findOne(
    { folio: /^FL-\d+$/ },
    { folio: 1 }
  ).sort({ folio: -1, createdAt: -1 });

  let siguienteNum = 101;
  if (ultimo && ultimo.folio) {
    const partes = ultimo.folio.split('-');
    const num = parseInt(partes[1], 10);
    if (!Number.isNaN(num)) {
      siguienteNum = Math.max(101, num + 1);
    }
  }

  return `FL-${String(siguienteNum).padStart(3, '0')}`;
}

/**
 * GET /api/tablero/resumen
 * Obtiene los indicadores KPI del Panel de Control (A-02, RNF-01):
 *   - viajesActivos: viajes con estado 'en_ruta'
 *   - ticketsPorAuditar: gastos con estadoAuditoria 'por_auditar'
 *   - unidadesFlota: total de camiones activos en flota
 */
exports.obtenerTableroResumen = async (req, res, next) => {
  try {
    const [viajesActivos, ticketsPorAuditar, unidadesFlota] = await Promise.all([
      Viaje.countDocuments({ estado: 'en_ruta' }),
      Gasto.countDocuments({ estadoAuditoria: 'por_auditar' }),
      Camion.countDocuments({ activo: true }),
    ]);

    res.status(200).json({
      status: 'success',
      data: {
        empresa: 'Transportes Flores S.A.',
        base: 'Base Monterrey',
        viajesActivos,
        ticketsPorAuditar,
        unidadesFlota,
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/viajes
 * Lista los despachos / órdenes de viaje registrados (A-03).
 */
exports.listarViajes = async (req, res, next) => {
  try {
    const { estado, q } = req.query;
    const filtro = {};

    if (estado) {
      filtro.estado = estado;
    }

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filtro.$or = [
        { folio: regex },
        { cliente: regex },
        { chofer: regex },
        { origen: regex },
        { destino: regex },
        { camion: regex },
      ];
    }

    const viajes = await Viaje.find(filtro).sort({ createdAt: -1 });
    res.status(200).json({
      status: 'success',
      total: viajes.length,
      data: { viajes },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/viajes
 * Emite una nueva Orden de Viaje con Flete y Anticipo (A-04, RF-05, US-07).
 */
exports.crearViaje = async (req, res, next) => {
  try {
    const {
      cliente,
      origen,
      destino,
      camion,
      placasCamion,
      chofer,
      tarifaPactada,
      anticipoEntregado,
      estado,
    } = req.body;

    if (
      !cliente ||
      !origen ||
      !destino ||
      !camion ||
      !chofer ||
      tarifaPactada === undefined
    ) {
      return res.status(400).json({
        status: 'fail',
        message:
          'Todos los campos obligatorios deben ser proporcionados: cliente, origen, destino, camion, chofer y tarifaPactada',
      });
    }

    const numTarifa = Number(tarifaPactada);
    if (Number.isNaN(numTarifa) || numTarifa <= 0) {
      return res.status(400).json({
        status: 'fail',
        message: 'La tarifa pactada debe ser un monto numérico mayor a 0',
      });
    }

    const numAnticipo =
      anticipoEntregado !== undefined && anticipoEntregado !== ''
        ? Number(anticipoEntregado)
        : 0;

    if (Number.isNaN(numAnticipo) || numAnticipo < 0) {
      return res.status(400).json({
        status: 'fail',
        message: 'El anticipo entregado no puede ser negativo',
      });
    }

    // Extraer placas si vienen en formato "Kenworth T680 (NLZ-8823-A)"
    let placasExtraidas = placasCamion;
    if (!placasExtraidas) {
      const matchPlacas = String(camion).match(/\(([^)]+)\)/);
      placasExtraidas = matchPlacas ? matchPlacas[1] : 'NLZ-8823-A';
    }

    const folio = await generarSiguienteFolioViaje();
    const origenLimpio = String(origen).trim();
    const destinoLimpio = String(destino).trim();

    const nuevoViaje = await Viaje.create({
      folio,
      cliente: String(cliente).trim(),
      origen: origenLimpio,
      destino: destinoLimpio,
      ruta: `${origenLimpio} → ${destinoLimpio}`,
      camion: String(camion).trim(),
      placasCamion: String(placasExtraidas).trim(),
      chofer: String(chofer).trim(),
      tarifaPactada: numTarifa,
      anticipoEntregado: numAnticipo,
      estado: estado || 'en_ruta',
    });

    res.status(201).json({
      status: 'success',
      message: `Orden de viaje ${folio} emitida correctamente`,
      data: { viaje: nuevoViaje },
    });
  } catch (err) {
    next(err);
  }
};
