const test = require('node:test');
const assert = require('node:assert/strict');
const { validarOdometro, formatearOdometro } = require('./odometro');

test('validarOdometro acepta una lectura entera positiva', () => {
  const resultado = validarOdometro(125430);
  assert.equal(resultado.valido, true);
});

test('validarOdometro rechaza valores negativos', () => {
  const resultado = validarOdometro(-10);
  assert.equal(resultado.valido, false);
  assert.equal(resultado.error, 'La lectura no puede ser negativa');
});

test('validarOdometro rechaza valores no numéricos', () => {
  const resultado = validarOdometro('12000km');
  assert.equal(resultado.valido, false);
});

test('validarOdometro rechaza una lectura menor a la anterior', () => {
  const resultado = validarOdometro(1000, 5000);
  assert.equal(resultado.valido, false);
  assert.equal(resultado.error, 'La lectura no puede ser menor a la anterior');
});

test('validarOdometro acepta una lectura igual o mayor a la anterior', () => {
  const resultado = validarOdometro(5200, 5000);
  assert.equal(resultado.valido, true);
});

test('formatearOdometro agrega separador de miles y unidad', () => {
  assert.equal(formatearOdometro(125430), '125,430 km');
});

test('formatearOdometro lanza error con una lectura inválida', () => {
  assert.throws(() => formatearOdometro(-5));
});
