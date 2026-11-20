/**
 * Servicio de Almacenamiento y Optimización de Evidencia Fotográfica (S-04, US-09comp — Sprint 9).
 *
 * Implementa el adaptador de almacenamiento local (`backend/uploads/`) y
 * procesamiento de imágenes en Base64 recibidas desde la app móvil tras
 * la compresión en cliente (S9-01 / S9-02 / S9-03).
 */
const fs = require('fs');
const path = require('path');

const UPLOADS_DIR = path.join(__dirname, '..', '..', 'uploads');

/**
 * Procesa la evidencia fotográfica recibida (Base64 o URL), calcula el tamaño en bytes
 * del archivo comprimido y, si `persistirDisco` está activo, guarda el archivo JPEG
 * en `backend/uploads/` devolviendo su ruta pública `/uploads/<archivo>.jpg`.
 *
 * @param {Object} params
 * @param {string} params.folio - Folio del gasto (ej. #TT-000145)
 * @param {string} [params.fotografiaBase64] - Cadena Base64 (con o sin prefijo data:image/...)
 * @param {string} [params.fotografiaUrl] - URL o nombre de archivo enviado por el cliente
 * @param {boolean} [params.persistirDisco] - Si se debe guardar en backend/uploads/
 * @returns {{ fotografiaUrl: string, fotografiaBase64: string, tamanoBytes: number, compresionOptimizada: boolean }}
 */
function procesarEvidenciaFotografica({
  folio = '#TT-000000',
  fotografiaBase64 = '',
  fotografiaUrl = '',
  persistirDisco = process.env.NODE_ENV !== 'test',
}) {
  const b64Str = fotografiaBase64 ? String(fotografiaBase64).trim() : '';
  const urlInput = fotografiaUrl ? String(fotografiaUrl).trim() : '';

  if (!b64Str) {
    return {
      fotografiaUrl: urlInput,
      fotografiaBase64: '',
      tamanoBytes: 0,
      compresionOptimizada: true,
    };
  }

  // Extraer payload puro en base64 si incluye cabecera data:image/...;base64,
  const partes = b64Str.split(',');
  const payloadBase64 = partes.length > 1 ? partes[1].trim() : partes[0].trim();
  const dataUriNormalizado = b64Str.startsWith('data:image/')
    ? b64Str
    : `data:image/jpeg;base64,${payloadBase64}`;

  let bufferImagen = Buffer.alloc(0);
  try {
    bufferImagen = Buffer.from(payloadBase64, 'base64');
  } catch (_) {}

  const tamanoBytes = bufferImagen.length;
  const folioLimpio = String(folio).replace(/[^a-zA-Z0-9_-]/g, '');
  const nombreArchivo = `ticket_${folioLimpio}_${Date.now()}.jpg`;
  let urlFinal = urlInput || `/uploads/${nombreArchivo}`;

  if (persistirDisco && tamanoBytes > 16) {
    try {
      if (!fs.existsSync(UPLOADS_DIR)) {
        fs.mkdirSync(UPLOADS_DIR, { recursive: true });
      }
      const rutaCompleta = path.join(UPLOADS_DIR, nombreArchivo);
      fs.writeFileSync(rutaCompleta, bufferImagen);
      urlFinal = `/uploads/${nombreArchivo}`;
    } catch (_) {
      // Si el entorno es de solo lectura, conservar la URL lógica y el Base64
    }
  }

  return {
    fotografiaUrl: urlFinal,
    fotografiaBase64: dataUriNormalizado,
    tamanoBytes,
    compresionOptimizada: true,
  };
}

module.exports = {
  procesarEvidenciaFotografica,
  UPLOADS_DIR,
};
