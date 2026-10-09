const BaseGastoValidationStrategy = require('./BaseGastoValidationStrategy');

/**
 * Estrategia de validación para gastos de tipo Diésel (RF-02, US-03, P3).
 * Regla de negocio:
 *   - Requiere obligatoriamente lectura del odómetro (en KM, número >= 0).
 *   - Requiere fotografía del comprobante.
 *   - Requiere monto > 0 y proveedor.
 */
class DieselValidationStrategy extends BaseGastoValidationStrategy {
  validar(datos) {
    const errores = [];

    this.validarMonto(datos, errores);
    this.validarFotografia(datos, errores);
    this.validarProveedor(datos, errores);

    // Validación específica de Diésel: Odómetro estrictamente obligatorio
    const odometro = Number(datos.odometro);
    if (datos.odometro === undefined || datos.odometro === null || datos.odometro === '' || isNaN(odometro)) {
      errores.push('La lectura de odómetro es obligatoria para gastos de combustible (Diésel)');
    } else if (odometro < 0) {
      errores.push('La lectura de odómetro no puede ser negativa');
    }

    return {
      esValido: errores.length === 0,
      errores,
    };
  }
}

module.exports = DieselValidationStrategy;
