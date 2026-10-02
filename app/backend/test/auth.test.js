/**
 * Pruebas del módulo de autenticación (Registro y Login)
 */
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const app = require('../src/app');
const Usuario = require('../src/models/Usuario');

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

beforeEach(async () => {
  await Usuario.deleteMany({});
});

describe('POST /api/auth/register', () => {
  it('debe registrar un nuevo usuario operador/chofer exitosamente', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'chofer_juan',
        password: 'Password123!',
        nombre: 'Juan Pérez',
        rol: 'operador',
        email: 'juan@tractotrak.com',
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.ok).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.usuario.username).toBe('chofer_juan');
    expect(res.body.usuario.rol).toBe('operador');
  });

  it('debe rechazar el registro si faltan campos obligatorios', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'incompleto',
      });

    expect(res.statusCode).toEqual(400);
    expect(res.body.ok).toBe(false);
  });

  it('debe rechazar el registro si el username ya existe', async () => {
    await Usuario.create({
      username: 'usuario_duplicado',
      password: 'password123',
      nombre: 'Existente',
      rol: 'administrador',
    });

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'usuario_duplicado',
        password: 'password123',
        nombre: 'Nuevo Intento',
        rol: 'administrador',
      });

    expect(res.statusCode).toEqual(400);
    expect(res.body.ok).toBe(false);
  });
});

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        username: 'chofer_login',
        password: 'Password123!',
        nombre: 'Chofer Login',
        rol: 'operador',
      });
  });

  it('debe autenticar con credenciales correctas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'chofer_login',
        password: 'Password123!',
      });

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.usuario.username).toBe('chofer_login');
  });

  it('debe rechazar login con contraseña incorrecta', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'chofer_login',
        password: 'wrongpassword',
      });

    expect(res.statusCode).toEqual(401);
    expect(res.body.ok).toBe(false);
  });
});

describe('GET /api/auth/perfil (Middleware JWT)', () => {
  let userToken;

  beforeEach(async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'chofer_perfil',
        password: 'Password123!',
        nombre: 'Chofer Perfil',
        rol: 'operador',
      });
    userToken = res.body.token;
  });

  it('debe obtener el perfil del usuario autenticado enviando token Bearer', async () => {
    const res = await request(app)
      .get('/api/auth/perfil')
      .set('Authorization', `Bearer ${userToken}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.usuario.username).toBe('chofer_perfil');
    expect(res.body.usuario.nombre).toBe('Chofer Perfil');
  });

  it('debe rechazar la petición si no se proporciona cabecera Authorization', async () => {
    const res = await request(app).get('/api/auth/perfil');

    expect(res.statusCode).toEqual(401);
    expect(res.body.ok).toBe(false);
  });

  it('debe rechazar la petición con token inválido', async () => {
    const res = await request(app)
      .get('/api/auth/perfil')
      .set('Authorization', 'Bearer token_invalido_123');

    expect(res.statusCode).toEqual(401);
    expect(res.body.ok).toBe(false);
  });
});
