/**
 * Contexto del Patrón Strategy (P3)
 * 
 * Selecciona e invoca en tiempo de ejecución la estrategia adecuada
 * de validación según el tipo de gasto proporcionado.
 */
const DieselValidationStrategy = require('./DieselValidationStrategy');
const FluidosValidationStrategy = require('./FluidosValidationStrategy');
const ViaticosValidationStrategy = require('./ViaticosValidationStrategy');

class GastoValidationContext {
  constructor() {
    this.strategies = {
      diesel: new DieselValidationStrategy(),
      'diésel': new DieselValidationStrategy(),
      fluidos: new FluidosValidationStrategy(),
      viaticos: new ViaticosValidationStrategy(),
      'viáticos': new ViaticosValidationStrategy(),
    };
  }

  /**
   * Obtiene la estrategia para el tipo indicado.
   * @param {string} tipo 
   * @returns {BaseGastoValidationStrategy}
   */
  obtenerEstrategia(tipo) {
    if (!tipo) {
      return null;
    }
    const normalizado = String(tipo).toLowerCase().trim();
    return this.strategies[normalizado] || null;
  }

  /**
   * Valida un conjunto de datos según el tipo de gasto.
   * @param {Object} datos 
   * @returns {{ esValido: boolean, errores: string[] }}
   */
  validar(datos) {
    if (!datos || !datos.tipo) {
      return {
        esValido: false,
        errores: ['El tipo de insumo o gasto es obligatorio (Diésel, Fluidos o Viáticos)'],
      };
    }

    const estrategia = this.obtenerEstrategia(datos.tipo);
    if (!estrategia) {
      return {
        esValido: false,
        errores: [`Tipo de gasto no soportado: "${datos.tipo}". Opciones válidas: Diésel, Fluidos, Viáticos`],
      };
    }

    return estrategia.validar(datos);
  }
}

module.exports = new GastoValidationContext();
