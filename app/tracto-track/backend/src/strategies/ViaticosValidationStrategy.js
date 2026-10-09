const BaseGastoValidationStrategy = require('./BaseGastoValidationStrategy');

/**
 * Estrategia de validación para gastos de tipo Viáticos (alimentos, hospedaje) (RF-02, P3).
 * Regla de negocio:
 *   - La lectura de odómetro NO es obligatoria (es opcional, per P3 Strategy).
 *   - Requiere fotografía del comprobante.
 *   - Requiere monto > 0 y proveedor.
 */
class ViaticosValidationStrategy extends BaseGastoValidationStrategy {
  validar(datos) {
    const errores = [];

    this.validarMonto(datos, errores);
    this.validarFotografia(datos, errores);
    this.validarProveedor(datos, errores);

    // Odómetro es opcional en viáticos, pero si se envía debe ser un número >= 0
    if (datos.odometro !== undefined && datos.odometro !== null && datos.odometro !== '') {
      const odometro = Number(datos.odometro);
      if (isNaN(odometro) || odometro < 0) {
        errores.push('Si se proporciona lectura de odómetro, debe ser un valor numérico no negativo');
      }
    }

    return {
      esValido: errores.length === 0,
      errores,
    };
  }
}

module.exports = ViaticosValidationStrategy;
