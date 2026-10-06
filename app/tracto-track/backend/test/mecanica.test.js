/**
 * Pruebas del módulo de Mecánica (Órdenes de reparación)
 *
 * Verifica el CRUD completo: crear, listar, detalle, actualizar,
 * agregar piezas, estadísticas y eliminación de órdenes.
 */
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const app = require('../src/app');
const Usuario = require('../src/models/Usuario');
const Camion = require('../src/models/Camion');
const OrdenMecanica = require('../src/models/OrdenMecanica');

let mongoServer;
let adminToken;
let operadorToken;
let camionId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

beforeEach(async () => {
  await Usuario.deleteMany({});
  await Camion.deleteMany({});
  await OrdenMecanica.deleteMany({});

  // Crear usuario administrador
  const adminRes = await request(app)
    .post('/api/auth/register')
    .send({
      username: 'admin_taller',
      password: 'Password123!',
      nombre: 'Admin Taller',
      rol: 'administrador',
    });
  adminToken = adminRes.body.token;

  // Crear usuario operador
  const operadorRes = await request(app)
    .post('/api/auth/register')
    .send({
      username: 'chofer_mec',
      password: 'Password123!',
      nombre: 'Chofer Mecánica',
      rol: 'operador',
    });
  operadorToken = operadorRes.body.token;

  // Crear un camión de prueba
  const camion = await Camion.create({
    placas: 'NLZ-8823-A',
    marca: 'Kenworth',
    modelo: 'T680',
    anio: 2021,
    capacidadCarga: 30,
    kilometraje: 125000,
    estado: 'disponible',
  });
  camionId = camion._id.toString();
});

describe('POST /api/mecanica', () => {
  it('debe crear una nueva orden de mecánica como administrador', async () => {
    const res = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Fuga de aceite en el motor principal',
        prioridad: 'alta',
        tipoServicio: 'correctivo',
        tiempoEstimadoHoras: 16,
        kilometrajeAlIngreso: 125340,
        mecanicoAsignado: 'Roberto García',
        piezas: [
          { nombre: 'Junta de culata', cantidad: 1, costoUnitario: 1500 },
          { nombre: 'Empaque de cárter', cantidad: 2, costoUnitario: 350 },
        ],
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.ok).toBe(true);
    expect(res.body.orden.folio).toMatch(/^OM-/);
    expect(res.body.orden.descripcionFalla).toContain('Fuga de aceite');
    expect(res.body.orden.piezas).toHaveLength(2);
    expect(res.body.orden.estado).toBe('reportada');

    // Verificar que el camión cambió a 'en_taller'
    const camionActualizado = await Camion.findById(camionId);
    expect(camionActualizado.estado).toBe('en_taller');
  });

  it('debe rechazar la creación sin campos obligatorios', async () => {
    const res = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ camion: camionId });

    expect(res.statusCode).toEqual(400);
    expect(res.body.ok).toBe(false);
  });

  it('debe rechazar la creación por un operador (solo admin)', async () => {
    const res = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${operadorToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Frenos desgastados',
      });

    expect(res.statusCode).toEqual(403);
    expect(res.body.ok).toBe(false);
  });

  it('debe rechazar si el camión no existe', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: fakeId,
        descripcionFalla: 'Problema eléctrico',
      });

    expect(res.statusCode).toEqual(404);
  });
});

describe('GET /api/mecanica', () => {
  beforeEach(async () => {
    await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Neumáticos desgastados',
        prioridad: 'media',
      });
  });

  it('debe listar todas las órdenes activas', async () => {
    const res = await request(app)
      .get('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.ordenes).toHaveLength(1);
    expect(res.body.total).toBe(1);
  });

  it('debe filtrar por prioridad', async () => {
    const res = await request(app)
      .get('/api/mecanica?prioridad=alta')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ordenes).toHaveLength(0);
  });
});

describe('GET /api/mecanica/:id', () => {
  it('debe obtener el detalle de una orden', async () => {
    const createRes = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Sistema de frenos ABS con falla',
        piezas: [{ nombre: 'Sensor ABS', cantidad: 4, costoUnitario: 800 }],
      });

    const ordenId = createRes.body.orden._id;

    const res = await request(app)
      .get(`/api/mecanica/${ordenId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.orden.descripcionFalla).toContain('frenos ABS');
    expect(res.body.orden.piezas).toHaveLength(1);
  });

  it('debe responder 404 para una orden inexistente', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app)
      .get(`/api/mecanica/${fakeId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(404);
  });
});

describe('PUT /api/mecanica/:id', () => {
  it('debe actualizar el estado y diagnóstico de una orden', async () => {
    const createRes = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Ruido en la transmisión',
      });

    const ordenId = createRes.body.orden._id;

    const res = await request(app)
      .put(`/api/mecanica/${ordenId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        estado: 'en_diagnostico',
        diagnostico: 'Rodamiento de salida de caja dañado',
        costoEstimado: 12000,
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.orden.estado).toBe('en_diagnostico');
    expect(res.body.orden.diagnostico).toContain('Rodamiento');
  });

  it('debe liberar el camión cuando la orden se completa', async () => {
    const createRes = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Cambio de aceite programado',
        tipoServicio: 'preventivo',
      });

    const ordenId = createRes.body.orden._id;

    // Completar la orden
    await request(app)
      .put(`/api/mecanica/${ordenId}`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ estado: 'completada', costoFinal: 800 });

    // Verificar que el camión volvió a 'disponible'
    const camion = await Camion.findById(camionId);
    expect(camion.estado).toBe('disponible');
  });
});

describe('POST /api/mecanica/:id/piezas', () => {
  it('debe agregar piezas a una orden existente', async () => {
    const createRes = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Sistema eléctrico con fallas',
      });

    const ordenId = createRes.body.orden._id;

    const res = await request(app)
      .post(`/api/mecanica/${ordenId}/piezas`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        piezas: [
          { nombre: 'Alternador', cantidad: 1, costoUnitario: 4500, proveedor: 'AutoPartes MX' },
          { nombre: 'Banda serpentina', cantidad: 1, costoUnitario: 650 },
        ],
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.orden.piezas).toHaveLength(2);
  });
});

describe('GET /api/mecanica/resumen/estadisticas', () => {
  it('debe devolver estadísticas de las órdenes', async () => {
    await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Orden para estadísticas',
      });

    const res = await request(app)
      .get('/api/mecanica/resumen/estadisticas')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.estadisticas).toHaveProperty('totalOrdenesActivas');
    expect(res.body.estadisticas).toHaveProperty('porEstado');
    expect(res.body.estadisticas).toHaveProperty('porPrioridad');
  });
});

describe('DELETE /api/mecanica/:id', () => {
  it('debe eliminar (soft delete) una orden como administrador', async () => {
    const createRes = await request(app)
      .post('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        camion: camionId,
        descripcionFalla: 'Orden a eliminar',
      });

    const ordenId = createRes.body.orden._id;

    const res = await request(app)
      .delete(`/api/mecanica/${ordenId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);

    // Verificar que ya no aparece en el listado
    const listRes = await request(app)
      .get('/api/mecanica')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(listRes.body.ordenes).toHaveLength(0);
  });
});
