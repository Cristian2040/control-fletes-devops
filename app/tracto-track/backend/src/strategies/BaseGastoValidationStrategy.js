/**
 * Patrón de diseño P3: Strategy
 * 
 * Clase base abstracta para la estrategia de validación de gastos.
 * Define la interfaz que deben implementar todas las estrategias concretas
 * (Diésel, Fluidos, Viáticos).
 */
class BaseGastoValidationStrategy {
  /**
   * Valida los datos del gasto.
   * @param {Object} datos - Objeto con monto, odometro, fotografia, proveedor, etc.
   * @returns {{ esValido: boolean, errores: string[] }}
   */
  validar(datos) {
    throw new Error('El método validar() debe ser implementado por la subclase');
  }

  /**
   * Valida que la fotografía del comprobante esté presente (obligatoria en todos según US-03).
   */
  validarFotografia(datos, errores) {
    const foto = datos.fotografiaUrl || datos.fotografiaBase64 || datos.fotografia;
    if (!foto || (typeof foto === 'string' && foto.trim() === '')) {
      errores.push('La fotografía del comprobante es obligatoria para registrar el gasto');
    }
  }

  /**
   * Valida que el monto sea un número válido mayor a 0.
   */
  validarMonto(datos, errores) {
    const monto = Number(datos.monto);
    if (datos.monto === undefined || datos.monto === null || isNaN(monto) || monto <= 0) {
      errores.push('El monto del comprobante debe ser un valor numérico mayor a 0');
    }
  }

  /**
   * Valida que el proveedor o estación esté presente.
   */
  validarProveedor(datos, errores) {
    if (!datos.proveedor || (typeof datos.proveedor === 'string' && datos.proveedor.trim() === '')) {
      errores.push('El proveedor o estación de carga es obligatorio');
    }
  }
}

module.exports = BaseGastoValidationStrategy;
