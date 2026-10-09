/**
 * Pruebas unitarias e integrales para Captura de Gastos e Insumos (Sprint 3, RF-02, US-03, P3 Strategy)
 */
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const { Usuario, Chofer, Gasto } = require('../src/models');
const {
  gastoValidator,
  DieselValidationStrategy,
  FluidosValidationStrategy,
  ViaticosValidationStrategy,
} = require('../src/strategies');
const config = require('../src/config');

let mongoServer;
let tokenChofer;
let usuarioChoferId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  // Crear usuario chofer para pruebas
  const usuario = await Usuario.create({
    username: 'jgonzalez_test',
    password: 'Password123!',
    nombre: 'Jorge González Test',
    rol: 'operador',
    email: 'jorge.test@tractotrak.com',
  });
  usuarioChoferId = usuario._id;

  await Chofer.create({
    nombre: 'Jorge González Test',
    licencia: 'LF-9928172',
    telefono: '8112345678',
    usuario: usuario._id,
    empresa: 'Transportes Flores S.A.',
  });

  tokenChofer = jwt.sign(
    { id: usuario._id, rol: usuario.rol, username: usuario.username },
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

describe('Patrón de Diseño P3: Strategy (Validación de Gastos)', () => {
  const dieselStrategy = new DieselValidationStrategy();
  const fluidosStrategy = new FluidosValidationStrategy();
  const viaticosStrategy = new ViaticosValidationStrategy();

  describe('US-03: Validación de Fotografía del Comprobante', () => {
    test('Rechaza el registro si no se adjunta fotografía (escenario US-03)', () => {
      const res = dieselStrategy.validar({
        monto: 3500,
        odometro: 142500,
        proveedor: 'Oxxo Gas',
        // Sin fotografía
      });
      expect(res.esValido).toBe(false);
      expect(res.errores).toContain('La fotografía del comprobante es obligatoria para registrar el gasto');
    });

    test('Acepta si se incluye fotografía en base64 o URL', () => {
      const res = dieselStrategy.validar({
        monto: 3500,
        odometro: 142500,
        proveedor: 'Oxxo Gas',
        fotografiaUrl: 'https://cdn.tractotrak.com/tickets/ticket1.jpg',
      });
      expect(res.esValido).toBe(true);
    });
  });

  describe('Estrategia Diésel', () => {
    test('Exige lectura de odómetro obligatoria', () => {
      const res = dieselStrategy.validar({
        monto: 3500,
        proveedor: 'Oxxo Gas',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(false);
      expect(res.errores.some(e => e.includes('odómetro'))).toBe(true);
    });

    test('Pasa cuando tiene odómetro, monto y fotografía válidos', () => {
      const res = dieselStrategy.validar({
        monto: 3500,
        odometro: 142500,
        proveedor: 'Oxxo Gas',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(true);
    });
  });

  describe('Estrategia Fluidos', () => {
    test('Exige lectura de odómetro obligatoria para mantenimiento', () => {
      const res = fluidosStrategy.validar({
        monto: 450,
        proveedor: 'Refaccionaria del Norte',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(false);
      expect(res.errores.some(e => e.includes('odómetro'))).toBe(true);
    });

    test('Pasa cuando tiene odómetro, monto y fotografía válidos', () => {
      const res = fluidosStrategy.validar({
        monto: 450,
        odometro: 142500,
        proveedor: 'Refaccionaria del Norte',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(true);
    });
  });

  describe('Estrategia Viáticos', () => {
    test('El odómetro es opcional (no rompe si falta)', () => {
      const res = viaticosStrategy.validar({
        monto: 250,
        proveedor: 'Restaurante El Parador',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(true);
    });

    test('Rechaza si no tiene monto válido', () => {
      const res = viaticosStrategy.validar({
        monto: 0,
        proveedor: 'Restaurante El Parador',
        fotografiaUrl: 'foto.jpg',
      });
      expect(res.esValido).toBe(false);
      expect(res.errores.some(e => e.includes('monto'))).toBe(true);
    });
  });

  describe('Contexto de Validación (GastoValidationContext)', () => {
    test('Selecciona dinámicamente la estrategia según el tipo', () => {
      const resDiesel = gastoValidator.validar({
        tipo: 'diesel',
        monto: 1000,
        odometro: 120000,
        proveedor: 'Pemex',
        fotografiaUrl: 'foto.jpg',
      });
      expect(resDiesel.esValido).toBe(true);

      const resViaticos = gastoValidator.validar({
        tipo: 'viáticos',
        monto: 300,
        proveedor: 'Comida',
        fotografiaUrl: 'foto.jpg',
      });
      expect(resViaticos.esValido).toBe(true);
    });

    test('Rechaza tipo de gasto desconocido', () => {
      const res = gastoValidator.validar({
        tipo: 'hospedaje_desconocido',
        monto: 300,
      });
      expect(res.esValido).toBe(false);
    });
  });
});

describe('Endpoints de Gastos (/api/gastos)', () => {
  describe('POST /api/gastos', () => {
    test('Rechaza la petición sin token de autenticación (401)', async () => {
      const res = await request(app)
        .post('/api/gastos')
        .send({ tipo: 'diesel', monto: 1500 });
      expect(res.status).toBe(401);
    });

    test('Crea un gasto de Diésel exitosamente con folio #TT-###### (201)', async () => {
      const payload = {
        tipo: 'diesel',
        monto: 5400.50,
        odometro: 142500,
        proveedor: 'OXXO GAS Saltillo',
        fotografiaUrl: 'data:image/jpeg;base64,simulated_ticket',
        placasCamion: 'NLZ-8823-A',
      };

      const res = await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('success');
      expect(res.body.data.gasto.folio).toMatch(/^#TT-\d{6}$/);
      expect(res.body.data.gasto.folio).toBe('#TT-000001');
      expect(res.body.data.gasto.monto).toBe(5400.50);
      expect(res.body.data.gasto.tipo).toBe('diesel');
      expect(res.body.data.gasto.estadoSincronizacion).toBe('sincronizado');
    });

    test('Autoincrementa el folio para el siguiente registro (#TT-000002)', async () => {
      await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'diesel',
          monto: 1000,
          odometro: 100,
          proveedor: 'Gas 1',
          fotografiaUrl: 'foto1.jpg',
        });

      const res2 = await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'viaticos',
          monto: 350,
          proveedor: 'Comida 2',
          fotografiaUrl: 'foto2.jpg',
        });

      expect(res2.status).toBe(201);
      expect(res2.body.data.gasto.folio).toBe('#TT-000002');
    });

    test('Rechaza guardado sin foto con 400 (Escenario US-03)', async () => {
      const res = await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'diesel',
          monto: 2500,
          odometro: 142500,
          proveedor: 'Oxxo Gas',
        });

      expect(res.status).toBe(400);
      expect(res.body.status).toBe('fail');
      expect(res.body.errores).toContain('La fotografía del comprobante es obligatoria para registrar el gasto');
    });

    test('Rechaza guardado de Diésel sin odómetro con 400', async () => {
      const res = await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'diesel',
          monto: 2500,
          proveedor: 'Oxxo Gas',
          fotografiaUrl: 'foto.jpg',
        });

      expect(res.status).toBe(400);
      expect(res.body.status).toBe('fail');
      expect(res.body.errores.some(e => e.includes('odómetro'))).toBe(true);
    });
  });

  describe('GET /api/gastos', () => {
    test('Obtiene la lista de gastos y calcula totales para la bitácora C-05', async () => {
      await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'diesel',
          monto: 1500,
          odometro: 1000,
          proveedor: 'Estación 1',
          fotografiaUrl: 'foto1.jpg',
        });

      await request(app)
        .post('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`)
        .send({
          tipo: 'viaticos',
          monto: 500,
          proveedor: 'Restaurante 2',
          fotografiaUrl: 'foto2.jpg',
        });

      const res = await request(app)
        .get('/api/gastos')
        .set('Authorization', `Bearer ${tokenChofer}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('success');
      expect(res.body.totalComprobantes).toBe(2);
      expect(res.body.totalImporte).toBe(2000);
      expect(res.body.data.gastos.length).toBe(2);
    });
  });
});
