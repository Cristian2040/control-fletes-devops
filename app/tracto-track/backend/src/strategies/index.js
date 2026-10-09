/**
 * Índice de estrategias de validación de gastos (Patrón P3 Strategy)
 */
const BaseGastoValidationStrategy = require('./BaseGastoValidationStrategy');
const DieselValidationStrategy = require('./DieselValidationStrategy');
const FluidosValidationStrategy = require('./FluidosValidationStrategy');
const ViaticosValidationStrategy = require('./ViaticosValidationStrategy');
const gastoValidator = require('./GastoValidationContext');

module.exports = {
  BaseGastoValidationStrategy,
  DieselValidationStrategy,
  FluidosValidationStrategy,
  ViaticosValidationStrategy,
  gastoValidator,
};
