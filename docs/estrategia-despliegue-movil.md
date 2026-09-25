# Estrategia de despliegue móvil — Control de Fletes

## 1. Estrategias consideradas

| Estrategia | Descripción | Aplicabilidad a este proyecto |
|---|---|---|
| Corte directo (Big Bang) | 100% de usuarios reciben la versión nueva de inmediato | Alto riesgo para un equipo pequeño sin capacidad de respuesta 24/7 — descartado como estrategia principal |
| **Rollout escalonado** | Incremento porcentual gradual vía Play Console (1% → 5% → 20% → 50% → 100%) | **Elegida como estrategia principal** para releases a producción (Sprint 10 / cierre de curso) |
| Canales preview (alfa/beta) | Grupo cerrado prueba la versión antes que el resto | **Ya en uso** durante todo el desarrollo vía Firebase App Distribution (ver `docs/plan-devops.md`, Apartado 7) |
| Canario móvil (OTA) | Update a un grupo reducido para medir estabilidad antes de ampliar | Complementa el rollout escalonado: el primer 1-5% actúa como grupo canario |
| **Feature Flags** | Activar/desactivar funciones en tiempo de ejecución sin pasar por revisión de tienda | **Elegida como estrategia de contingencia**, ver Apartado 3 |
| Pruebas A/B | Comparar variantes de una pantalla con usuarios reales | No aplica al MVP (equipo y base de usuarios de prueba demasiado pequeños para significancia estadística) |

## 2. Estrategia principal: Rollout escalonado + canales preview

- **Alfa (interno, todo el desarrollo):** cada build de `develop` se distribuye al equipo vía Firebase App Distribution. Sin usuarios reales, solo validación funcional.
- **Beta (Sprints 6–9):** cada release a `main` se distribuye a un grupo cerrado (equipo + Product Owner) vía Firebase App Distribution — actúa como el "canal preview" equivalente a TestFlight.
- **Producción (Sprint 10 / cierre de curso):** publicación en Google Play Console con **rollout escalonado**:
  1. 1% de usuarios (o pista interna/cerrada, dado el contexto académico) — actúa como grupo canario.
  2. Si no hay incidentes en 24–48 h → 5% → 20% → 50% → 100%, con al menos 24 h de observación entre cada incremento.

## 3. Criterios de avance (gates)

Se avanza al siguiente porcentaje del rollout solo si, en la ventana de observación:

- **Crash-free rate ≥ 99.5%** (medido con Firebase Crashlytics).
- **Tasa de errores de red/sincronización < 2%** de los registros offline pendientes.
- **Sin incidentes de severidad alta** abiertos en `#ops` (ver `docs/guia-comunicacion.md`).
- **Tiempo de respuesta de la API p95 < 2 s** (RNF-02), sin degradación frente a la versión anterior.

Si cualquiera de estos criterios no se cumple, el rollout **se detiene** en el porcentaje actual (no se retrocede automáticamente el % ya distribuido, ya que Play Store no permite "desinstalar" remotamente, pero sí se congela el avance).

## 4. Protocolo de reversión (rollback)

Publicar una nueva versión en Play Store para revertir un cambio toma horas o días de revisión — no es una opción para una respuesta inmediata. Por eso el protocolo se apoya en dos mecanismos más rápidos:

1. **Feature Flag inmediato (primera línea de respuesta):** si el problema viene de una función específica y no de la app en general (ej. el motor de liquidaciones), se apaga el flag correspondiente de forma remota sin publicar una nueva versión. Ver el demostrador en `demo/feature-flag/`.
2. **Detener el rollout escalonado (segunda línea):** desde Google Play Console, se pausa el porcentaje de distribución actual para que no lleguen más usuarios a la versión con problemas, mientras se prepara un hotfix.
3. **Hotfix con revisión acelerada (tercera línea, si 1 y 2 no bastan):** rama `hotfix/*` desde `main` (ver `docs/workflow-versionamiento.md`), con revisión de 1 solo compañero para agilizar, tag de parche (`vX.Y.Z+1`) y nuevo rollout escalonado desde 1%.

## 5. Riesgos y mitigación específicos del rollout

- **Riesgo:** el equipo no monitorea activamente durante la ventana de 24–48 h entre incrementos → **Mitigación:** asignar responsable de guardia por rollout (rotativo) que revise Crashlytics y `#ops` al menos dos veces al día durante la ventana.
- **Riesgo:** cuenta de desarrollador de Play Console limitada al ser proyecto académico (sin pista de producción real) → **Mitigación:** simular el rollout usando la pista interna/cerrada de Play Console, que sí soporta porcentajes de distribución igual que producción.
