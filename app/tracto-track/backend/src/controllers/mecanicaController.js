/**
 * Controlador de Mecánica — Tracto Trak (SPF)
 *
 * CRUD completo para órdenes de mecánica / reparación de unidades.
 * Permite registrar daños, asignar piezas, actualizar estado y cerrar órdenes.
 */
const OrdenMecanica = require('../models/OrdenMecanica');
const Camion = require('../models/Camion');

/**
 * POST /api/mecanica
 * Crea una nueva orden de mecánica (reporte de daño).
 */
const crearOrden = async (req, res, next) => {
  try {
    const {
      camion,
      descripcionFalla,
      tipoServicio,
      prioridad,
      tiempoEstimadoHoras,
      fechaEstimadaEntrega,
      diagnostico,
      piezas,
      costoEstimado,
      kilometrajeAlIngreso,
      mecanicoAsignado,
      notas,
      evidenciasFotos,
    } = req.body;

    // Validar campos requeridos
    if (!camion || !descripcionFalla) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Campos obligatorios faltantes: camion y descripcionFalla son requeridos',
      });
    }

    // Verificar que el camión existe
    const camionExistente = await Camion.findById(camion);
    if (!camionExistente) {
      return res.status(404).json({
        ok: false,
        mensaje: 'La unidad (camión) especificada no fue encontrada',
      });
    }

    // Crear la orden
    const nuevaOrden = await OrdenMecanica.create({
      camion,
      descripcionFalla,
      tipoServicio: tipoServicio || 'correctivo',
      prioridad: prioridad || 'media',
      tiempoEstimadoHoras: tiempoEstimadoHoras || 0,
      fechaEstimadaEntrega: fechaEstimadaEntrega || null,
      diagnostico: diagnostico || '',
      piezas: piezas || [],
      costoEstimado: costoEstimado || 0,
      kilometrajeAlIngreso: kilometrajeAlIngreso || 0,
      mecanicoAsignado: mecanicoAsignado || '',
      notas: notas || '',
      evidenciasFotos: evidenciasFotos || [],
      reportadoPor: req.usuario ? req.usuario.id : null,
    });

    // Actualizar estado del camión a 'en_taller'
    await Camion.findByIdAndUpdate(camion, { estado: 'en_taller' });

    // Poblar referencia al camión para la respuesta
    await nuevaOrden.populate('camion', 'placas marca modelo anio');
    await nuevaOrden.populate('reportadoPor', 'username nombre');

    res.status(201).json({
      ok: true,
      mensaje: 'Orden de mecánica creada exitosamente',
      orden: nuevaOrden,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/mecanica
 * Lista todas las órdenes de mecánica (con filtros opcionales).
 * Query params: estado, prioridad, camion, tipoServicio
 */
const listarOrdenes = async (req, res, next) => {
  try {
    const filtro = { activo: true };

    if (req.query.estado) filtro.estado = req.query.estado;
    if (req.query.prioridad) filtro.prioridad = req.query.prioridad;
    if (req.query.camion) filtro.camion = req.query.camion;
    if (req.query.tipoServicio) filtro.tipoServicio = req.query.tipoServicio;

    const ordenes = await OrdenMecanica.find(filtro)
      .populate('camion', 'placas marca modelo anio estado')
      .populate('reportadoPor', 'username nombre')
      .sort({ createdAt: -1 });

    res.json({
      ok: true,
      total: ordenes.length,
      ordenes,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/mecanica/:id
 * Obtiene el detalle de una orden de mecánica por su ID.
 */
const obtenerOrden = async (req, res, next) => {
  try {
    const orden = await OrdenMecanica.findById(req.params.id)
      .populate('camion', 'placas marca modelo anio estado kilometraje')
      .populate('reportadoPor', 'username nombre');

    if (!orden) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Orden de mecánica no encontrada',
      });
    }

    res.json({
      ok: true,
      orden,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/mecanica/:id
 * Actualiza una orden de mecánica existente (estado, diagnóstico, piezas, etc.).
 */
const actualizarOrden = async (req, res, next) => {
  try {
    const orden = await OrdenMecanica.findById(req.params.id);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Orden de mecánica no encontrada',
      });
    }

    // Campos actualizables
    const camposPermitidos = [
      'descripcionFalla', 'tipoServicio', 'prioridad', 'estado',
      'tiempoEstimadoHoras', 'fechaEstimadaEntrega', 'fechaRealEntrega',
      'diagnostico', 'trabajoRealizado', 'piezas',
      'costoEstimado', 'costoManoObra', 'costoFinal',
      'evidenciasFotos', 'mecanicoAsignado', 'notas',
    ];

    camposPermitidos.forEach((campo) => {
      if (req.body[campo] !== undefined) {
        orden[campo] = req.body[campo];
      }
    });

    // Si se completa la orden, registrar fecha real de entrega y liberar el camión
    if (req.body.estado === 'completada' && !orden.fechaRealEntrega) {
      orden.fechaRealEntrega = new Date();

      // Liberar el camión (volver a 'disponible')
      await Camion.findByIdAndUpdate(orden.camion, { estado: 'disponible' });
    }

    // Si se cancela, también liberar el camión
    if (req.body.estado === 'cancelada') {
      await Camion.findByIdAndUpdate(orden.camion, { estado: 'disponible' });
    }

    await orden.save();

    await orden.populate('camion', 'placas marca modelo anio estado');
    await orden.populate('reportadoPor', 'username nombre');

    res.json({
      ok: true,
      mensaje: 'Orden de mecánica actualizada exitosamente',
      orden,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/mecanica/:id/piezas
 * Agrega una o más piezas a una orden existente.
 */
const agregarPiezas = async (req, res, next) => {
  try {
    const orden = await OrdenMecanica.findById(req.params.id);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Orden de mecánica no encontrada',
      });
    }

    const { piezas } = req.body;

    if (!piezas || !Array.isArray(piezas) || piezas.length === 0) {
      return res.status(400).json({
        ok: false,
        mensaje: 'Se requiere un arreglo de piezas con al menos un elemento',
      });
    }

    orden.piezas.push(...piezas);
    await orden.save();

    res.json({
      ok: true,
      mensaje: `${piezas.length} pieza(s) agregada(s) a la orden ${orden.folio}`,
      orden,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/mecanica/:id/piezas/:piezaId
 * Actualiza el estado de una pieza específica dentro de una orden.
 */
const actualizarPieza = async (req, res, next) => {
  try {
    const orden = await OrdenMecanica.findById(req.params.id);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Orden de mecánica no encontrada',
      });
    }

    const pieza = orden.piezas.id(req.params.piezaId);

    if (!pieza) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Pieza no encontrada en esta orden',
      });
    }

    // Actualizar campos de la pieza
    const camposPieza = ['nombre', 'numeroParte', 'cantidad', 'costoUnitario', 'proveedor', 'estado'];
    camposPieza.forEach((campo) => {
      if (req.body[campo] !== undefined) {
        pieza[campo] = req.body[campo];
      }
    });

    await orden.save();

    res.json({
      ok: true,
      mensaje: 'Pieza actualizada exitosamente',
      orden,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/mecanica/:id
 * Elimina (soft delete) una orden de mecánica.
 */
const eliminarOrden = async (req, res, next) => {
  try {
    const orden = await OrdenMecanica.findById(req.params.id);

    if (!orden) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Orden de mecánica no encontrada',
      });
    }

    orden.activo = false;
    await orden.save();

    // Si la orden estaba activa (no completada/cancelada), liberar el camión
    if (['reportada', 'en_diagnostico', 'en_reparacion'].includes(orden.estado)) {
      await Camion.findByIdAndUpdate(orden.camion, { estado: 'disponible' });
    }

    res.json({
      ok: true,
      mensaje: `Orden ${orden.folio} eliminada exitosamente`,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/mecanica/resumen/estadisticas
 * Devuelve un resumen estadístico de las órdenes de mecánica.
 */
const obtenerEstadisticas = async (req, res, next) => {
  try {
    const [porEstado, porPrioridad, porTipo] = await Promise.all([
      OrdenMecanica.aggregate([
        { $match: { activo: true } },
        { $group: { _id: '$estado', total: { $sum: 1 } } },
      ]),
      OrdenMecanica.aggregate([
        { $match: { activo: true } },
        { $group: { _id: '$prioridad', total: { $sum: 1 } } },
      ]),
      OrdenMecanica.aggregate([
        { $match: { activo: true } },
        { $group: { _id: '$tipoServicio', total: { $sum: 1 } } },
      ]),
    ]);

    const totalActivas = await OrdenMecanica.countDocuments({
      activo: true,
      estado: { $nin: ['completada', 'cancelada'] },
    });

    res.json({
      ok: true,
      estadisticas: {
        totalOrdenesActivas: totalActivas,
        porEstado,
        porPrioridad,
        porTipo,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  crearOrden,
  listarOrdenes,
  obtenerOrden,
  actualizarOrden,
  agregarPiezas,
  actualizarPieza,
  eliminarOrden,
  obtenerEstadisticas,
};
