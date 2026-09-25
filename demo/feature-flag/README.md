# Demostrador — Feature Flag (Ruta 1)

Producto F de la práctica de investigación: implementación de una bandera local
(`FEATURE_NEW_LIQUIDACIONES_ENGINE`) que activa o desactiva el motor de liquidaciones
nuevo (US-13) **sin recompilar ni republicar la app**, y su uso como mecanismo de
**rollback inmediato** (ver `docs/estrategia-despliegue-movil.md`, Apartado 4).

No depende del proyecto Flutter/Node aún por crear — corre con el Node.js del sistema,
sin instalar nada.

## Archivos

- `odometro.js` — función de lógica pura (validador + formateador de la lectura del odómetro, ligado a US-03).
- `odometro.test.js` — pruebas unitarias de esa función (7 casos), usando el test runner nativo de Node.
- `featureFlag.js` — módulo mínimo de feature flags (encender/apagar en memoria, simulando un panel remoto).
- `demo.js` — script que simula la liquidación de un viaje con el flag apagado, encendido y apagado de nuevo (rollback simulado).

## Cómo correrlo

Requiere Node.js 18 o superior (trae el test runner integrado, no hace falta instalar Jest).

```bash
cd demo/feature-flag

# 1. Correr las pruebas unitarias de la función pura
node --test odometro.test.js

# 2. Correr la simulación del feature flag
node demo.js
```

## Qué deberías ver

**Pruebas (`node --test odometro.test.js`):** 7 casos, todos `ok`, resumen final `# pass 7 / # fail 0`.

**Demo (`node demo.js`):**
```
--- Estado inicial del flag: OFF (comportamiento legacy, seguro) ---
Odómetro del viaje: 1,200 km
[flag OFF] Motor legacy -> liquidación (sin descontar anticipo): $18000

--- Simulamos activar el flag remotamente para el PO/administrador ---
Odómetro del viaje: 1,200 km
[flag ON]  Motor nuevo -> liquidación (con anticipo descontado): $17500

--- Simulamos un rollback inmediato apagando el flag (sin republicar la app) ---
Odómetro del viaje: 1,200 km
[flag OFF] Motor legacy -> liquidación (sin descontar anticipo): $18000
```

Esto evidencia el punto central del Producto F: **el mismo código, sin recompilar,
cambia de comportamiento según el valor del flag** — así es como se haría un rollback
en segundos ante un bug del motor de liquidaciones, en vez de esperar horas/días
a que Play Store apruebe una nueva versión.

> Captura de pantalla de esta salida en tu terminal = evidencia para el Producto F.
