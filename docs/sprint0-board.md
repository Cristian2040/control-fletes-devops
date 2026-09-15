# Tablón de trabajo — Sprint 0 (DevOps)

## Definición de Sprint 0

Sprint 0 es un **sprint técnico de arranque**, previo/paralelo al Sprint 1 de desarrollo funcional (definido en la planeación Scrum del proyecto). Su objetivo no es entregar funcionalidad de negocio, sino dejar lista la **infraestructura DevOps**: repositorio, CI, tablero, canales de comunicación y convenciones, para que los 10 Sprints funcionales puedan ejecutarse sin fricción. Duración: **hasta 1 semana**, en paralelo a la fase de wireframes de Sprint 1.

## Board (Jira)

Columnas: **Backlog → To-Do → In-Progress → Review → Done**

Estado inicial del board al arrancar Sprint 0 — todas las historias comienzan en **Backlog**; el equipo mueve a **To-Do** las que se compromete a trabajar esta semana (todas, dado el alcance reducido de Sprint 0).

## Backlog de Sprint 0 — Historias de usuario (INVEST)

Cada historia cumple **I**ndependent, **N**egotiable, **V**aluable, **E**stimable, **S**mall, **T**estable.

| ID | Historia | Prioridad (MoSCoW) | Story Points |
|---|---|---|---|
| S0-01 | Como equipo, quiero un repositorio Git con estructura base (`/docs`, `/app`, `/ci`, README) para tener un único punto de verdad del código y la documentación. | Must | 2 |
| S0-02 | Como Scrum Master, quiero ramas `main`/`develop` protegidas y convención de `feature/*`/`hotfix/*` para evitar que código sin revisar llegue a `main`. | Must | 2 |
| S0-03 | Como desarrollador, quiero un workflow de CI que corra build/lint/test en cada push a `develop` y PR a `main`, para detectar errores antes del merge. | Must | 3 |
| S0-04 | Como equipo, quiero plantillas de Issue y Pull Request para reportar bugs/features y revisar código de forma consistente. | Should | 2 |
| S0-05 | Como Product Owner, quiero un board en Jira con columnas Backlog/To-Do/In-Progress/Review/Done y el Product Backlog cargado, para dar seguimiento visual al proyecto. | Must | 2 |
| S0-06 | Como equipo, quiero elegir y configurar una herramienta de comunicación (canales, normas, integraciones con GitHub) para coordinar el trabajo diario y los Sprints. | Must | 3 |
| S0-07 | Como equipo, quiero un documento de Plan DevOps con el ciclo Plan→Feedback aplicado a este proyecto, para saber qué herramienta y criterio aplica en cada fase. | Must | 3 |
| S0-08 | Como Scrum Master, quiero conectar notificaciones de CI/GitHub al canal de comunicación del equipo, para enterarnos de builds rotos o PRs pendientes sin revisar GitHub manualmente. | Could | 2 |

**Total Sprint 0:** 19 story points.

### Criterios de aceptación (resumen)

- **S0-01:** repo creado en GitHub, estructura de carpetas visible, README con descripción mínima del proyecto.
- **S0-02:** `main` marcada como protegida (require PR + 1 review + checks), `develop` creada desde `main`.
- **S0-03:** workflow visible en pestaña Actions, se dispara en push a `develop` y en PR hacia `main`, termina en verde con un proyecto vacío/base.
- **S0-04:** archivos de plantilla en `.github/ISSUE_TEMPLATE/` y `.github/pull_request_template.md`, visibles al crear un Issue/PR nuevo.
- **S0-05:** board publicado con las 5 columnas y al menos las historias de Sprint 0 y del Product Backlog original cargadas.
- **S0-06:** servidor/canal creado, 6 canales nombrados según la guía de comunicación, normas publicadas en un canal fijado.
- **S0-07:** documento `plan-devops.md` con las 10 secciones completas, accesible desde el README.
- **S0-08:** mensaje de prueba (push o PR de ejemplo) llega correctamente al canal `#dev`.

## Priorización (MoSCoW)

- **Must have:** S0-01, S0-02, S0-03, S0-05, S0-06, S0-07 (bloquean el arranque de Sprint 1).
- **Should have:** S0-04 (mejora la calidad del flujo, no bloquea).
- **Could have:** S0-08 (automatización deseable, puede quedar para inicio de Sprint 1 si falta tiempo).
- **Won't have (este Sprint):** cualquier historia funcional del producto (US-01 a US-13 del Product Backlog original) — se atienden a partir de Sprint 1.
