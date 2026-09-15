# Control de Fletes — Práctica DevOps

![CI](https://img.shields.io/badge/CI-configurar_URL_del_repo-lightgrey)
![Versión](https://img.shields.io/badge/versión-v0.1.0--Sprint0-blue)

App móvil offline-first (Flutter) + API REST (Node.js/Express + MongoDB) para el control de gastos, viajes y liquidaciones de empresas de autotransporte de carga. Proyecto de la materia **Desarrollo Móvil Integral** — UTSJdR.

> Nota: el badge de CI de arriba es un placeholder; al subir este repo a GitHub, reemplazar la URL por la del workflow real: `https://github.com/<usuario_u_org>/<repo>/actions/workflows/ci.yml/badge.svg`.

## Equipo

| Integrante | Rol |
|---|---|
| Yair Barrios | Scrum Master & Dev Lead Mobile |
| Cristian Hernández | Backend, Arquitecto de Datos & QA |
| Felipe Estrella | Product Owner & Analista de Negocio |
| Yaneli Mendoza | Diseñadora UX/UI & Frontend |

## Estructura del repositorio

```
/docs
  plan-devops.md          # Plan DevOps del Proyecto Móvil (10 secciones)
  matriz-comunicacion.md  # Matriz comparativa + dictamen de herramienta de comunicación
  guia-comunicacion.md    # Canales, normas e integraciones del equipo
  sprint0-board.md        # Backlog Sprint 0 (INVEST + MoSCoW) y definición del board
/app
  mobile/                 # App Flutter (a crear en Sprint 0/1)
  backend/                # API Node.js/Express (a crear en Sprint 0/1)
/ci
  README.md               # Scripts auxiliares de CI/CD
/.github
  workflows/ci.yml        # Workflow de CI: lint + test en push a develop y PR a main
  ISSUE_TEMPLATE/          # Plantillas de bug y feature
  pull_request_template.md
```

## Cómo construir/ejecutar (una vez creados los proyectos en Sprint 0/1)

```bash
# App móvil
cd app/mobile
flutter pub get
flutter run

# Backend
cd app/backend
npm install
npm run dev
```

## Documentación clave

- 📋 [Plan DevOps del Proyecto Móvil](docs/plan-devops.md)
- 💬 [Matriz y dictamen de herramienta de comunicación](docs/matriz-comunicacion.md)
- 📖 [Guía de comunicación del equipo](docs/guia-comunicacion.md)
- 🗂️ [Backlog y board de Sprint 0](docs/sprint0-board.md)

## Board y comunicación

- **Board:** Jira (proyecto tipo Scrum) — columnas Backlog / To-Do / In-Progress / Review / Done. (Enlace: completar con la URL del proyecto Jira).
- **Comunicación:** Discord — canales `#anuncios`, `#dev`, `#qa`, `#ops`, `#dudas`, `#random` (ver `docs/guia-comunicacion.md`).

## Ramas y flujo de trabajo

`main` (estable, protegida) ← `develop` (integración) ← `feature/*` / `hotfix/*`. Commits con Conventional Commits, tags semánticos (`v0.1.0`, `v0.2.0`…). Detalle completo en `docs/plan-devops.md` (Apartado 4).
