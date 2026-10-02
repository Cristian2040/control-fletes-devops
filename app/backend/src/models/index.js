/**
 * Índice de modelos Mongoose.
 * Exporta todos los modelos disponibles para uso centralizado.
 */
const Usuario = require('./Usuario');
const Camion = require('./Camion');
const Chofer = require('./Chofer');
const Cliente = require('./Cliente');

module.exports = {
  Usuario,
  Camion,
  Chofer,
  Cliente,
};
