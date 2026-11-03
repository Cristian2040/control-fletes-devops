/**
 * Suite de pruebas — Sprint 7: Tablero de Control, Viajes y Asignación de Viaje (A-02, A-03, A-04).
 */
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const config = require('../src/config');
const { Viaje, Gasto, Camion } = require('../src/models');

let mongoServer;
let tokenAdmin;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  tokenAdmin = jwt.sign(
    {
      id: new mongoose.Types.ObjectId().toString(),
      nombre: 'Roberto Flores',
      correo: 'admin@tractotrak.mx',
      rol: 'dueno',
    },
    config.jwtSecret,
    { expiresIn: '1h' }
  );
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

beforeEach(async () => {
  await Viaje.deleteMany({});
  await Gasto.deleteMany({});
  await Camion.deleteMany({});
});

describe('Sprint 7 — API de Tablero y Viajes (/api/tablero/resumen y /api/viajes)', () => {
  test('1. Rechaza peticiones sin token JWT (401)', async () => {
    const res = await request(app).get('/api/viajes');
    expect(res.statusCode).toBe(401);
  });

  test('2. Emite una Orden de Viaje (POST /api/viajes) con folio FL-101 y calcula ruta', async () => {
    const res = await request(app)
      .post('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        cliente: 'CEMEX S.A. de C.V.',
        origen: 'Monterrey',
        destino: 'CDMX',
        camion: 'Kenworth T680 (NLZ-8823-A)',
        chofer: 'Jorge González',
        tarifaPactada: 18500.0,
        anticipoEntregado: 5000.0,
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data.viaje.folio).toBe('FL-101');
    expect(res.body.data.viaje.ruta).toBe('Monterrey → CDMX');
    expect(res.body.data.viaje.placasCamion).toBe('NLZ-8823-A');
    expect(res.body.data.viaje.tarifaPactada).toBe(18500);
    expect(res.body.data.viaje.anticipoEntregado).toBe(5000);
    expect(res.body.data.viaje.estado).toBe('en_ruta');
  });

  test('3. Autoincrementa el folio a FL-102 al emitir un segundo viaje', async () => {
    await request(app)
      .post('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        cliente: 'CEMEX S.A. de C.V.',
        origen: 'Monterrey',
        destino: 'CDMX',
        camion: 'Kenworth T680 (NLZ-8823-A)',
        chofer: 'Jorge González',
        tarifaPactada: 18500.0,
      });

    const res2 = await request(app)
      .post('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        cliente: 'Gruma Internacional',
        origen: 'San Luis Potosí',
        destino: 'GDL',
        camion: 'Freightliner Cascadia (SPF-4412-B)',
        chofer: 'Raúl Mendoza',
        tarifaPactada: 14200.0,
        anticipoEntregado: 3500.0,
      });

    expect(res2.statusCode).toBe(201);
    expect(res2.body.data.viaje.folio).toBe('FL-102');
    expect(res2.body.data.viaje.ruta).toBe('San Luis Potosí → GDL');
  });

  test('4. Lista viajes activos y permite filtrar por búsqueda (GET /api/viajes)', async () => {
    await Viaje.create([
      {
        folio: 'FL-101',
        cliente: 'CEMEX S.A. de C.V.',
        origen: 'Monterrey',
        destino: 'CDMX',
        camion: 'Kenworth T680 (NLZ-8823-A)',
        chofer: 'Jorge González',
        tarifaPactada: 18500,
      },
      {
        folio: 'FL-102',
        cliente: 'Gruma Internacional',
        origen: 'San Luis Potosí',
        destino: 'GDL',
        camion: 'Freightliner Cascadia (SPF-4412-B)',
        chofer: 'Raúl Mendoza',
        tarifaPactada: 14200,
      },
    ]);

    const resTodos = await request(app)
      .get('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`);

    expect(resTodos.statusCode).toBe(200);
    expect(resTodos.body.total).toBe(2);

    const resFiltro = await request(app)
      .get('/api/viajes?q=Gruma')
      .set('Authorization', `Bearer ${tokenAdmin}`);

    expect(resFiltro.statusCode).toBe(200);
    expect(resFiltro.body.total).toBe(1);
    expect(resFiltro.body.data.viajes[0].folio).toBe('FL-102');
  });

  test('5. Obtiene los KPIs del Tablero de Control (GET /api/tablero/resumen)', async () => {
    await Viaje.create({
      folio: 'FL-101',
      cliente: 'CEMEX S.A. de C.V.',
      origen: 'Monterrey',
      destino: 'CDMX',
      camion: 'Kenworth T680 (NLZ-8823-A)',
      chofer: 'Jorge González',
      tarifaPactada: 18500,
      estado: 'en_ruta',
    });

    await Camion.create({
      placas: 'NLZ-8823-A',
      marca: 'Kenworth',
      modelo: 'T680',
      anio: 2021,
      capacidadCarga: 28,
      estado: 'en_ruta',
    });

    const res = await request(app)
      .get('/api/tablero/resumen')
      .set('Authorization', `Bearer ${tokenAdmin}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.data.empresa).toBe('Transportes Flores S.A.');
    expect(res.body.data.viajesActivos).toBe(1);
    expect(res.body.data.unidadesFlota).toBe(1);
    expect(res.body.data.ticketsPorAuditar).toBe(0);
  });
});
