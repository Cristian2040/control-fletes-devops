/**
 * Feature Flags — implementación mínima local (sin proveedor externo).
 * En este demostrador el estado vive en un objeto en memoria / variables de entorno,
 * simulando cómo se apagaría remotamente una función sin publicar una nueva versión
 * (Ruta 1 de la Parte F: Feature Flag en la aplicación).
 */

const flags = {
  // Motor de liquidaciones automatizadas (US-13) — la historia de mayor riesgo/esfuerzo
  // del proyecto (8 story points). Se controla con flag para poder apagarla en caliente
  // si se detecta un problema de cálculo en producción, sin esperar una nueva publicación
  // en la tienda (ver docs/estrategia-despliegue-movil.md, Apartado 4).
  NEW_LIQUIDACIONES_ENGINE: process.env.FEATURE_NEW_LIQUIDACIONES === 'true' || false,
};

/**
 * @param {keyof typeof flags} nombre
 * @returns {boolean}
 */
function isEnabled(nombre) {
  if (!(nombre in flags)) {
    throw new Error(`Feature flag desconocida: ${nombre}`);
  }
  return flags[nombre];
}

/** Permite cambiar un flag en caliente (simula un panel remoto de administración). */
function setFlag(nombre, valor) {
  if (!(nombre in flags)) {
    throw new Error(`Feature flag desconocida: ${nombre}`);
  }
  flags[nombre] = Boolean(valor);
}

module.exports = { isEnabled, setFlag };
