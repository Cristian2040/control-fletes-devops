/**
 * Suite de pruebas — Sprint 8: Auditoría en Ruta y Validación de Fotografía (RF-06, US-08, US-08b, A-13, A-14).
 */
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const jwt = require('jsonwebtoken');

const app = require('../src/app');
const config = require('../src/config');
const { Gasto } = require('../src/models');

let mongoServer;
let tokenAdmin;
let usuarioId;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  await mongoose.connect(mongoServer.getUri());

  usuarioId = new mongoose.Types.ObjectId();
  tokenAdmin = jwt.sign(
    {
      id: usuarioId.toString(),
      nombre: 'Roberto Flores',
      correo: 'admin@tractotrak.mx',
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

describe('Sprint 8 — API de Auditoría en Ruta y Validación de Fotografía (/api/gastos/:id/auditoria)', () => {
  test('1. Rechaza peticiones sin token JWT (401)', async () => {
    const res = await request(app).put('/api/gastos/TT-000001/auditoria').send({
      estadoAuditoria: 'aprobado',
    });
    expect(res.statusCode).toBe(401);
  });

  test('2. Lista tickets pendientes de auditoría con contador pendientesAuditoria (RF-06, A-13)', async () => {
    await Gasto.create([
      {
        folio: '#TT-000101',
        tipo: 'viaticos',
        monto: 1240.0,
        proveedor: 'PEMEX 4402',
        fotografiaUrl: 'ticket1.jpg',
        usuario: usuarioId,
        placasCamion: 'NLZ-8823-A',
        estadoAuditoria: 'pendiente',
      },
      {
        folio: '#TT-000102',
        tipo: 'diesel',
        monto: 3800.0,
        odometro: 148320,
        proveedor: 'Oxxo Gas',
        fotografiaUrl: 'ticket2.jpg',
        usuario: usuarioId,
        placasCamion: 'NLZ-8823-A',
        estadoAuditoria: 'aprobado',
      },
    ]);

    const res = await request(app)
      .get('/api/gastos?estadoAuditoria=pendiente')
      .set('Authorization', `Bearer ${tokenAdmin}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.totalComprobantes).toBe(1);
    expect(res.body.pendientesAuditoria).toBe(1);
    expect(res.body.data.gastos[0].folio).toBe('#TT-000101');
  });

  test('3. Aprueba un ticket fotográfico por ID o Folio (US-08, A-14)', async () => {
    const gasto = await Gasto.create({
      folio: '#TT-000103',
      tipo: 'diesel',
      monto: 1240.0,
      odometro: 148320,
      proveedor: 'ESTACIÓN PEMEX 4402',
      fotografiaUrl: 'ticket_pemex.jpg',
      usuario: usuarioId,
      placasCamion: 'NLZ-8823-A',
      estadoAuditoria: 'pendiente',
    });

    const res = await request(app)
      .put(`/api/gastos/${gasto._id}/auditoria`)
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        estadoAuditoria: 'aprobado',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.gasto.estadoAuditoria).toBe('aprobado');
  });

  test('4. Rechaza un ticket fotográfico por Folio registrando el motivo (US-08b, A-14)', async () => {
    await Gasto.create({
      folio: '#TT-000104',
      tipo: 'viaticos',
      monto: 650.0,
      proveedor: 'Caseta MTY-SLP',
      fotografiaUrl: 'ticket_caseta.jpg',
      usuario: usuarioId,
      placasCamion: 'NLZ-8823-A',
      estadoAuditoria: 'pendiente',
    });

    const res = await request(app)
      .put('/api/gastos/TT-000104/auditoria')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({
        estadoAuditoria: 'rechazado',
        motivoRechazo: 'Fotografía ilegible o importe no coincide',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.gasto.estadoAuditoria).toBe('rechazado');
    expect(res.body.data.gasto.motivoRechazo).toBe('Fotografía ilegible o importe no coincide');
  });

  test('5. Valida estadoAuditoria inválido (400) y ticket inexistente (404)', async () => {
    const res400 = await request(app)
      .put('/api/gastos/TT-000999/auditoria')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({ estadoAuditoria: 'invalido' });

    expect(res400.statusCode).toBe(400);

    const res404 = await request(app)
      .put('/api/gastos/TT-000999/auditoria')
      .set('Authorization', `Bearer ${tokenAdmin}`)
      .send({ estadoAuditoria: 'aprobado' });

    expect(res404.statusCode).toBe(404);
  });
});
