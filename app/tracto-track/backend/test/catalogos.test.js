/**
 * Pruebas unitarias e integrales para Catálogos Operativos (Sprint 6, RF-05)
 * Camiones (A-05, A-09), Choferes (A-06, A-10), Clientes (A-07, A-11), Tarifas (A-08, A-12)
 */
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const { Usuario, Camion, Chofer, Cliente, Tarifa } = require('../src/models');
const config = require('../src/config');

let mongoServer;
let tokenAdmin;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  const admin = await Usuario.create({
    username: 'admin_test',
    password: 'Password123!',
    nombre: 'Dueño de Flota Test',
    rol: 'administrador',
    email: 'admin.test@tractotrak.com',
  });

  tokenAdmin = jwt.sign(
    { id: admin._id, rol: admin.rol, username: admin.username },
    config.jwtSecret,
    { expiresIn: '1h' }
  );
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Sprint 6: Catálogos Operativos (RF-05)', () => {
  describe('Protección de rutas con JWT', () => {
    test('Rechaza peticiones sin token JWT con código 401', async () => {
      const res = await request(app).get('/api/camiones');
      expect(res.statusCode).toBe(401);
      expect(res.body.ok).toBe(false);
    });
  });

  describe('1. Catálogo de Camiones (A-05, A-09)', () => {
    test('POST /api/camiones registra un camión nuevo', async () => {
      const res = await request(app)
        .post('/api/camiones')
        .set('Authorization', `Bearer ${tokenAdmin}`)
        .send({
          placas: 'NLZ-9999-Z',
          marca: 'Kenworth',
          modelo: 'T680',
          anio: 2021,
          capacidadCarga: 28,
          estado: 'en_ruta',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.camion.placas).toBe('NLZ-9999-Z');
    });

    test('GET /api/camiones lista camiones y filtra por placas/modelo', async () => {
      const res = await request(app)
        .get('/api/camiones?q=Kenworth')
        .set('Authorization', `Bearer ${tokenAdmin}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.camiones.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('2. Catálogo de Choferes (A-06, A-10)', () => {
    test('POST /api/choferes registra un chofer nuevo', async () => {
      const res = await request(app)
        .post('/api/choferes')
        .set('Authorization', `Bearer ${tokenAdmin}`)
        .send({
          nombre: 'Jorge González',
          licencia: 'LF-9928172',
          telefono: '811-234-5678',
          empresa: 'Transportes Flores S.A.',
          estado: 'en_ruta',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.chofer.nombre).toBe('Jorge González');
    });

    test('GET /api/choferes lista choferes y busca por nombre', async () => {
      const res = await request(app)
        .get('/api/choferes?q=González')
        .set('Authorization', `Bearer ${tokenAdmin}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.choferes.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('3. Catálogo de Clientes (A-07, A-11)', () => {
    test('POST /api/clientes registra un cliente nuevo', async () => {
      const res = await request(app)
        .post('/api/clientes')
        .set('Authorization', `Bearer ${tokenAdmin}`)
        .send({
          razonSocial: 'CEMEX S.A. de C.V.',
          rfc: 'CEM850101XYZ',
          diasCredito: 30,
          estado: 'activo',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.cliente.razonSocial).toBe('CEMEX S.A. de C.V.');
    });

    test('GET /api/clientes lista clientes y busca por RFC', async () => {
      const res = await request(app)
        .get('/api/clientes?q=CEM850101XYZ')
        .set('Authorization', `Bearer ${tokenAdmin}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.clientes.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('4. Catálogo de Tarifas (A-08, A-12)', () => {
    test('POST /api/tarifas registra una tarifa base', async () => {
      const res = await request(app)
        .post('/api/tarifas')
        .set('Authorization', `Bearer ${tokenAdmin}`)
        .send({
          ruta: 'Monterrey → CDMX',
          tipoCarga: 'General',
          montoBase: 18500.0,
          capacidadTon: 28,
        });

      expect(res.statusCode).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.tarifa.montoBase).toBe(18500.0);
    });

    test('GET /api/tarifas lista tarifas pactadas', async () => {
      const res = await request(app)
        .get('/api/tarifas?q=CDMX')
        .set('Authorization', `Bearer ${tokenAdmin}`);

      expect(res.statusCode).toBe(200);
      expect(res.body.data.tarifas.length).toBeGreaterThanOrEqual(1);
    });
  });
});
