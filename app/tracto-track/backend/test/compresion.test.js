/**
 * Suite de pruebas — Sprint 9:
 *   - S9-01: Compresión y Almacenamiento de Evidencia Fotográfica (US-09comp, S-04)
 *   - S9-05: Pruebas de rendimiento — verificar respuesta de endpoints menor a 2 segundos (RNF-02)
 */
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const config = require('../src/config');
const { Gasto } = require('../src/models');
const { procesarEvidenciaFotografica } = require('../src/services/imageStorageService');

let mongoServer;
let tokenChofer;
let tokenAdmin;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  tokenChofer = jwt.sign(
    {
      id: new mongoose.Types.ObjectId().toString(),
      nombre: 'Jorge González',
      rol: 'operador',
    },
    config.jwtSecret,
    { expiresIn: '1h' }
  );

  tokenAdmin = jwt.sign(
    {
      id: new mongoose.Types.ObjectId().toString(),
      nombre: 'Roberto Flores',
      rol: 'administrador',
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
  await Gasto.deleteMany({});
});

describe('S9-01 — Compresión Automática de Imágenes antes de guardar/enviar (US-09comp, S-04)', () => {
  test('1. procesarEvidenciaFotografica normaliza data URI Base64 y calcula tamaño en bytes', () => {
    const rawPayload = Buffer.from('JPEG_COMPRESSED_TICKET_DATA_12345').toString('base64');
    const resultado = procesarEvidenciaFotografica({
      folio: '#TT-000201',
      fotografiaBase64: rawPayload,
      persistirDisco: false,
    });

    expect(resultado.compresionOptimizada).toBe(true);
    expect(resultado.fotografiaBase64).toBe(`data:image/jpeg;base64,${rawPayload}`);
    expect(resultado.tamanoBytes).toBeGreaterThan(10);
    expect(resultado.fotografiaUrl).toContain('/uploads/ticket_');
  });

  test('2. POST /api/gastos procesa fotografía comprimida Base64 y activa bandera compresionOptimizada', async () => {
    const fakeJpegBase64 =
      'data:image/jpeg;base64,' +
      Buffer.from('FAKE_COMPRESSED_JPEG_BYTES_FOR_TICKET').toString('base64');

    const res = await request(app)
      .post('/api/gastos')
      .set('Authorization', `Bearer ${tokenChofer}`)
      .send({
        tipo: 'diesel',
        monto: 1450.0,
        odometro: 149200,
        proveedor: 'PEMEX Autopista',
        fotografiaBase64: fakeJpegBase64,
        placasCamion: 'NLZ-8823-A',
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data.gasto.compresionOptimizada).toBe(true);
    expect(res.body.data.gasto.fotografiaBase64).toBe(fakeJpegBase64);
    expect(res.body.data.gasto.fotografiaUrl).toContain('/uploads/ticket_');
  });
});

describe('S9-05 — Pruebas de rendimiento: verificar respuesta de endpoints menor a 2 segundos (< 2000 ms, RNF-02)', () => {
  const LIMITE_MS = 2000;

  test('1. GET /health responde en menos de 2000 ms (RNF-02)', async () => {
    const inicio = Date.now();
    const res = await request(app).get('/health');
    const duracionMs = Date.now() - inicio;

    expect(res.statusCode).toBe(200);
    expect(duracionMs).toBeLessThan(LIMITE_MS);
  });

  test('2. GET /api/tablero/resumen responde en menos de 2000 ms (RNF-02)', async () => {
    const inicio = Date.now();
    const res = await request(app)
      .get('/api/tablero/resumen')
      .set('Authorization', `Bearer ${tokenAdmin}`);
    const duracionMs = Date.now() - inicio;

    expect(res.statusCode).toBe(200);
    expect(duracionMs).toBeLessThan(LIMITE_MS);
  });

  test('3. GET /api/viajes y POST /api/viajes responden en menos de 2000 ms (RNF-02)', async () => {
    const inicioPost = Date.now();
    const resPost = await request(app)
      .post('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        cliente: 'CEMEX S.A. de C.V.',
        origen: 'Monterrey',
        destino: 'CDMX',
        camion: 'Kenworth T680 (NLZ-8823-A)',
        chofer: 'Jorge González',
        tarifaPactada: 18500,
        anticipoEntregado: 5000,
      });
    const duracionPostMs = Date.now() - inicioPost;

    expect(resPost.statusCode).toBe(201);
    expect(duracionPostMs).toBeLessThan(LIMITE_MS);

    const inicioGet = Date.now();
    const resGet = await request(app)
      .get('/api/viajes')
      .set('Authorization', `Bearer ${tokenAdmin}`);
    const duracionGetMs = Date.now() - inicioGet;

    expect(resGet.statusCode).toBe(200);
    expect(duracionGetMs).toBeLessThan(LIMITE_MS);
  });

  test('4. POST /api/gastos y GET /api/gastos responden en menos de 2000 ms (RNF-02)', async () => {
    const inicioPost = Date.now();
    const resPost = await request(app)
      .post('/api/gastos')
      .set('Authorization', `Bearer ${tokenChofer}`)
      .send({
        tipo: 'viaticos',
        monto: 380.0,
        proveedor: 'Restaurante El Parador',
        fotografiaUrl: 'ticket_viaticos.jpg',
      });
    const duracionPostMs = Date.now() - inicioPost;

    expect(resPost.statusCode).toBe(201);
    expect(duracionPostMs).toBeLessThan(LIMITE_MS);

    const inicioGet = Date.now();
    const resGet = await request(app)
      .get('/api/gastos')
      .set('Authorization', `Bearer ${tokenAdmin}`);
    const duracionGetMs = Date.now() - inicioGet;

    expect(resGet.statusCode).toBe(200);
    expect(duracionGetMs).toBeLessThan(LIMITE_MS);
  });

  test('5. GET /api/camiones, /api/choferes, /api/clientes y /api/tarifas responden en menos de 2000 ms (RNF-02)', async () => {
    const endpoints = ['/api/camiones', '/api/choferes', '/api/clientes', '/api/tarifas'];
    for (const ep of endpoints) {
      const inicio = Date.now();
      const res = await request(app)
        .get(ep)
        .set('Authorization', `Bearer ${tokenAdmin}`);
      const duracionMs = Date.now() - inicio;

      expect(res.statusCode).toBe(200);
      expect(duracionMs).toBeLessThan(LIMITE_MS);
    }
  });
});
