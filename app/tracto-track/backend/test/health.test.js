/**
 * Pruebas del endpoint /health
 * Sprint 1 — Fundación técnica y diseño base
 * 
 * Verifica que el servidor responda correctamente y reporte
 * el estado de la conexión a la base de datos.
 */
const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('GET /health', () => {
  it('debe responder con estado 200 y ok: true', async () => {
    const res = await request(app).get('/health');

    expect(res.statusCode).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.servidor).toBe('activo');
    expect(res.body.baseDeDatos).toBe('conectado');
    expect(res.body).toHaveProperty('timestamp');
    expect(res.body).toHaveProperty('version');
  });

  it('debe incluir el nombre del sistema en el mensaje', async () => {
    const res = await request(app).get('/health');

    expect(res.body.mensaje).toContain('Tracto Trak');
    expect(res.body.mensaje).toContain('SPF');
  });
});

describe('Rutas no encontradas', () => {
  it('debe responder 404 para rutas inexistentes', async () => {
    const res = await request(app).get('/ruta-inexistente');

    expect(res.statusCode).toBe(404);
    expect(res.body.ok).toBe(false);
    expect(res.body.mensaje).toContain('Ruta no encontrada');
  });
});
