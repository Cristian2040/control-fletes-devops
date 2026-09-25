/**
 * Demostrador ejecutable (Producto F).
 * Simula el flujo de liquidación de un chofer con el motor NUEVO apagado y encendido,
 * mostrando cómo el flag cambia el comportamiento sin recompilar ni republicar nada.
 *
 * Ejecutar:  node demo/feature-flag/demo.js
 */

const { isEnabled, setFlag } = require('./featureFlag');
const { formatearOdometro } = require('./odometro');

function calcularLiquidacionLegacy(kilometraje, tarifaPorKm) {
  return kilometraje * tarifaPorKm;
}

function calcularLiquidacionNueva(kilometraje, tarifaPorKm, anticipo) {
  // "Motor nuevo": igual que el legacy, pero ya descuenta el anticipo entregado (US-13).
  return kilometraje * tarifaPorKm - anticipo;
}

function liquidarViaje({ kilometraje, tarifaPorKm, anticipo }) {
  console.log(`Odómetro del viaje: ${formatearOdometro(kilometraje)}`);

  if (isEnabled('NEW_LIQUIDACIONES_ENGINE')) {
    const monto = calcularLiquidacionNueva(kilometraje, tarifaPorKm, anticipo);
    console.log(`[flag ON]  Motor nuevo -> liquidación (con anticipo descontado): $${monto}`);
  } else {
    const monto = calcularLiquidacionLegacy(kilometraje, tarifaPorKm);
    console.log(`[flag OFF] Motor legacy -> liquidación (sin descontar anticipo): $${monto}`);
  }
}

const viaje = { kilometraje: 1200, tarifaPorKm: 15, anticipo: 500 };

console.log('--- Estado inicial del flag: OFF (comportamiento legacy, seguro) ---');
liquidarViaje(viaje);

console.log('\n--- Simulamos activar el flag remotamente para el PO/administrador ---');
setFlag('NEW_LIQUIDACIONES_ENGINE', true);
liquidarViaje(viaje);

console.log('\n--- Simulamos un rollback inmediato apagando el flag (sin republicar la app) ---');
setFlag('NEW_LIQUIDACIONES_ENGINE', false);
liquidarViaje(viaje);
