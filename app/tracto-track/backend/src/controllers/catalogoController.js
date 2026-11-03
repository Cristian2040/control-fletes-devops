/**
 * Controlador de Catálogos Operativos (RF-05, Sprint 6)
 * 
 * Gestiona el mantenimiento y consulta de:
 *   - Camiones (A-05, A-09)
 *   - Choferes (A-06, A-10)
 *   - Clientes (A-07, A-11)
 *   - Tarifas Pactadas (A-08, A-12)
 */
const { Camion, Chofer, Cliente, Tarifa } = require('../models');

// --- Datos semilla para entorno de desarrollo/pruebas ---
async function asegurarDatosSemilla() {
  try {
    const totalCamiones = await Camion.countDocuments();
    if (totalCamiones === 0) {
      await Camion.insertMany([
        { placas: 'NLZ-8823-A', marca: 'Kenworth', modelo: 'T680', anio: 2021, capacidadCarga: 28, estado: 'en_ruta', kilometraje: 142500 },
        { placas: 'SPF-4412-B', marca: 'Freightliner', modelo: 'Cascadia', anio: 2022, capacidadCarga: 30, estado: 'disponible', kilometraje: 98200 },
        { placas: 'MTY-9910-C', marca: 'International', modelo: 'LT', anio: 2020, capacidadCarga: 26, estado: 'en_taller', kilometraje: 187400 },
      ]);
    }

    const totalChoferes = await Chofer.countDocuments();
    if (totalChoferes === 0) {
      await Chofer.insertMany([
        { nombre: 'Jorge González', licencia: 'LF-9928172', telefono: '811-234-5678', empresa: 'Transportes Flores S.A.', estado: 'en_ruta' },
        { nombre: 'Raúl Mendoza', licencia: 'LF-8812301', telefono: '818-456-7890', empresa: 'Transportes Flores S.A.', estado: 'disponible' },
        { nombre: 'Carlos Herrera', licencia: 'LF-7723910', telefono: '812-789-0123', empresa: 'Transportes Flores S.A.', estado: 'inactivo' },
      ]);
    }

    const totalClientes = await Cliente.countDocuments();
    if (totalClientes === 0) {
      await Cliente.insertMany([
        { razonSocial: 'CEMEX S.A. de C.V.', rfc: 'CEM850101XYZ', diasCredito: 30, estado: 'activo' },
        { razonSocial: 'Gruma Internacional', rfc: 'GRU900215ABC', diasCredito: 15, estado: 'activo' },
        { razonSocial: 'Ternium México', rfc: 'TER050820DEF', diasCredito: 45, estado: 'activo' },
      ]);
    }

    const totalTarifas = await Tarifa.countDocuments();
    if (totalTarifas === 0) {
      await Tarifa.insertMany([
        { ruta: 'Monterrey → CDMX', tipoCarga: 'General', capacidadTon: 28, montoBase: 18500.0, estado: 'activa' },
        { ruta: 'San Luis Potosí → GDL', tipoCarga: 'Refrigerada', capacidadTon: 24, montoBase: 14200.0, estado: 'activa' },
        { ruta: 'Querétaro → Monterrey', tipoCarga: 'General', capacidadTon: 30, montoBase: 16800.0, estado: 'activa' },
      ]);
    }
  } catch (_) {}
}

// Inicializar semillas en memoria si está vacío (solo en entornos fuera de pruebas)
if (process.env.NODE_ENV !== 'test') {
  asegurarDatosSemilla();
}

// ==========================================
// 1. CAMIONES (A-05, A-09)
// ==========================================

exports.listarCamiones = async (req, res, next) => {
  try {
    const { q, estado } = req.query;
    const filtro = { activo: true };

    if (estado) {
      filtro.estado = estado;
    }

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filtro.$or = [{ placas: regex }, { marca: regex }, { modelo: regex }];
    }

    const camiones = await Camion.find(filtro).sort({ createdAt: -1 });
    res.status(200).json({
      status: 'success',
      total: camiones.length,
      data: { camiones },
    });
  } catch (err) {
    next(err);
  }
};

exports.crearCamion = async (req, res, next) => {
  try {
    const { placas, marca, modelo, anio, capacidadCarga, estado, kilometraje } = req.body;

    if (!placas || !marca || !modelo || !anio || capacidadCarga === undefined) {
      return res.status(400).json({
        status: 'fail',
        message: 'Todos los campos son obligatorios: placas, marca, modelo, año y capacidad de carga',
      });
    }

    const existe = await Camion.findOne({ placas: placas.toUpperCase().trim() });
    if (existe) {
      return res.status(400).json({
        status: 'fail',
        message: `Ya existe un camión registrado con las placas ${placas.toUpperCase().trim()}`,
      });
    }

    const camion = await Camion.create({
      placas: placas.toUpperCase().trim(),
      marca: marca.trim(),
      modelo: modelo.trim(),
      anio: Number(anio),
      capacidadCarga: Number(capacidadCarga),
      estado: estado || 'disponible',
      kilometraje: kilometraje ? Number(kilometraje) : 0,
    });

    res.status(201).json({
      status: 'success',
      message: 'Camión registrado exitosamente en el catálogo (RF-05)',
      data: { camion },
    });
  } catch (err) {
    next(err);
  }
};

exports.obtenerCamionPorId = async (req, res, next) => {
  try {
    const camion = await Camion.findById(req.params.id);
    if (!camion) {
      return res.status(404).json({ status: 'fail', message: 'Camión no encontrado' });
    }
    res.status(200).json({ status: 'success', data: { camion } });
  } catch (err) {
    next(err);
  }
};

// ==========================================
// 2. CHOFERES (A-06, A-10)
// ==========================================

exports.listarChoferes = async (req, res, next) => {
  try {
    const { q, estado } = req.query;
    const filtro = { activo: true };

    if (estado) {
      filtro.estado = estado;
    }

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filtro.$or = [{ nombre: regex }, { licencia: regex }, { telefono: regex }];
    }

    const choferes = await Chofer.find(filtro).sort({ createdAt: -1 });
    res.status(200).json({
      status: 'success',
      total: choferes.length,
      data: { choferes },
    });
  } catch (err) {
    next(err);
  }
};

exports.crearChofer = async (req, res, next) => {
  try {
    const { nombre, licencia, telefono, empresa, estado } = req.body;

    if (!nombre || !licencia || !telefono) {
      return res.status(400).json({
        status: 'fail',
        message: 'Nombre completo, licencia federal y teléfono celular son obligatorios',
      });
    }

    const chofer = await Chofer.create({
      nombre: nombre.trim(),
      licencia: licencia.trim(),
      telefono: telefono.trim(),
      empresa: (empresa || 'Transportes Flores S.A.').trim(),
      estado: estado || 'disponible',
    });

    res.status(201).json({
      status: 'success',
      message: 'Chofer registrado exitosamente en el catálogo (RF-05)',
      data: { chofer },
    });
  } catch (err) {
    next(err);
  }
};

// ==========================================
// 3. CLIENTES (A-07, A-11)
// ==========================================

exports.listarClientes = async (req, res, next) => {
  try {
    const { q, estado } = req.query;
    const filtro = { activo: true };

    if (estado) {
      filtro.estado = estado;
    }

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filtro.$or = [{ razonSocial: regex }, { rfc: regex }];
    }

    const clientes = await Cliente.find(filtro).sort({ createdAt: -1 });
    res.status(200).json({
      status: 'success',
      total: clientes.length,
      data: { clientes },
    });
  } catch (err) {
    next(err);
  }
};

exports.crearCliente = async (req, res, next) => {
  try {
    const { razonSocial, rfc, diasCredito, estado } = req.body;

    if (!razonSocial || !rfc || diasCredito === undefined) {
      return res.status(400).json({
        status: 'fail',
        message: 'Razón social, RFC y días de crédito son obligatorios',
      });
    }

    const cliente = await Cliente.create({
      razonSocial: razonSocial.trim(),
      rfc: rfc.toUpperCase().trim(),
      diasCredito: Number(diasCredito),
      estado: estado || 'activo',
    });

    res.status(201).json({
      status: 'success',
      message: 'Cliente registrado exitosamente en el catálogo (RF-05)',
      data: { cliente },
    });
  } catch (err) {
    next(err);
  }
};

// ==========================================
// 4. TARIFAS (A-08, A-12)
// ==========================================

exports.listarTarifas = async (req, res, next) => {
  try {
    const { q } = req.query;
    const filtro = { activo: true };

    if (q) {
      const regex = new RegExp(q.trim(), 'i');
      filtro.$or = [{ ruta: regex }, { tipoCarga: regex }];
    }

    const tarifas = await Tarifa.find(filtro).sort({ createdAt: -1 });
    res.status(200).json({
      status: 'success',
      total: tarifas.length,
      data: { tarifas },
    });
  } catch (err) {
    next(err);
  }
};

exports.crearTarifa = async (req, res, next) => {
  try {
    const { ruta, tipoCarga, montoBase, capacidadTon, estado } = req.body;

    if (!ruta || !tipoCarga || montoBase === undefined) {
      return res.status(400).json({
        status: 'fail',
        message: 'Ruta pactada, tipo de carga y monto base son obligatorios',
      });
    }

    const tarifa = await Tarifa.create({
      ruta: ruta.trim(),
      tipoCarga: tipoCarga.trim(),
      montoBase: Number(montoBase),
      capacidadTon: capacidadTon ? Number(capacidadTon) : 25,
      estado: estado || 'activa',
    });

    res.status(201).json({
      status: 'success',
      message: 'Tarifa base registrada exitosamente en el catálogo (RF-05)',
      data: { tarifa },
    });
  } catch (err) {
    next(err);
  }
};
