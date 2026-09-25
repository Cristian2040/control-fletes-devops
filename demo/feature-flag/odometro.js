/**
 * Función de lógica pura (sin efectos secundarios, sin dependencias externas)
 * relacionada con la captura de gastos del chofer (US-03 del proyecto):
 * valida y formatea la lectura del odómetro antes de guardarla.
 */

/**
 * Valida que una lectura de odómetro sea un entero positivo razonable.
 * @param {number} lectura
 * @param {number|null} lecturaAnterior - última lectura conocida, si existe
 * @returns {{valido: boolean, error?: string}}
 */
function validarOdometro(lectura, lecturaAnterior = null) {
  if (typeof lectura !== 'number' || Number.isNaN(lectura)) {
    return { valido: false, error: 'La lectura debe ser un número' };
  }
  if (!Number.isInteger(lectura)) {
    return { valido: false, error: 'La lectura debe ser un número entero' };
  }
  if (lectura < 0) {
    return { valido: false, error: 'La lectura no puede ser negativa' };
  }
  if (lecturaAnterior !== null && lectura < lecturaAnterior) {
    return { valido: false, error: 'La lectura no puede ser menor a la anterior' };
  }
  return { valido: true };
}

/**
 * Formatea una lectura de odómetro con separador de miles para mostrarla en la UI.
 * @param {number} lectura
 * @returns {string}
 */
function formatearOdometro(lectura) {
  const { valido } = validarOdometro(lectura);
  if (!valido) {
    throw new Error('No se puede formatear una lectura inválida');
  }
  return `${lectura.toLocaleString('es-MX')} km`;
}

module.exports = { validarOdometro, formatearOdometro };
