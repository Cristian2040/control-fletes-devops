const BaseGastoValidationStrategy = require('./BaseGastoValidationStrategy');

/**
 * Estrategia de validación para gastos de tipo Fluidos (aceite, anticongelante, etc.) (RF-02, P3).
 * Regla de negocio:
 *   - Requiere obligatoriamente lectura del odómetro para control de mantenimiento preventivo.
 *   - Requiere fotografía del comprobante.
 *   - Requiere monto > 0 y proveedor.
 */
class FluidosValidationStrategy extends BaseGastoValidationStrategy {
  validar(datos) {
    const errores = [];

    this.validarMonto(datos, errores);
    this.validarFotografia(datos, errores);
    this.validarProveedor(datos, errores);

    // Validación específica de Fluidos: Odómetro obligatorio
    const odometro = Number(datos.odometro);
    if (datos.odometro === undefined || datos.odometro === null || datos.odometro === '' || isNaN(odometro)) {
      errores.push('La lectura de odómetro es obligatoria para insumos de fluidos (aceite, anticongelante)');
    } else if (odometro < 0) {
      errores.push('La lectura de odómetro no puede ser negativa');
    }

    return {
      esValido: errores.length === 0,
      errores,
    };
  }
}

module.exports = FluidosValidationStrategy;
