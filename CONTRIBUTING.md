# Guía de Contribución — Control de Fletes

## Flujo de trabajo

Seguimos un **Gitflow ligero** (ver justificación completa en `docs/workflow-versionamiento.md`):

1. Crear rama a partir de `develop` bajo el formato `feature/nombre-modulo` (ej. `feature/captura-gastos-offline`) o `hotfix/descripcion` a partir de `main` para correcciones urgentes.
2. Realizar commits respetando el estándar **Conventional Commits**:
   - `feat:` nueva funcionalidad
   - `fix:` corrección de bug
   - `docs:` solo documentación
   - `test:` agrega o corrige pruebas
   - `chore:` / `refactor:` cambios internos sin afectar comportamiento
   - Ejemplo: `feat(offline): guardar gasto en cola local cuando no hay red`
3. Abrir un Pull Request:
   - `feature/*` → hacia `develop`
   - `hotfix/*` → hacia `main` (y luego replicar a `develop`)
4. El PR requiere:
   - Validación del CI en verde (lint + pruebas).
   - Al menos **1 aprobación** de un compañero.
   - Vínculo a la historia de usuario correspondiente (`Closes #N` o el ID de Jira en el título).
5. Al fusionar a `main` (cierre de Sprint), se crea un **tag semántico**.

## Versionado

Se emplea versionado semántico ligado al número de compilación interno:

```
vMayor.Menor.Parche (build)
```

- **Mayor:** cambios incompatibles o cierre de MVP (`v1.0.0`).
- **Menor:** nueva funcionalidad de Sprint compatible con lo anterior (`v0.2.0`, `v0.3.0`...).
- **Parche:** correcciones (`v0.2.1`).
- **(build):** número incremental de compilación (`versionCode` en Android / `buildVersion` en Flutter), ej. `v0.2.0 (14)`.

Referencia: primer prototipo funcional = `v0.1.0`; cada incremento de Sprint con valor demostrable sube el minor; `v1.0.0` al cierre del MVP (Sprint 10).

## Revisión de código

- Yair revisa cambios de `app/mobile`.
- Cristian revisa cambios de `app/backend`.
- Cambios que tocan ambas capas (ej. contratos de API) requieren revisión cruzada.
- Ver `.github/CODEOWNERS` para la asignación automática de revisores por carpeta.

## Pruebas antes de pedir revisión

- `flutter analyze` / `npm run lint` sin errores nuevos.
- Pruebas unitarias/widget agregadas o actualizadas para el cambio.
- Probado manualmente en un dispositivo/entorno real cuando aplica.

## Reporte de bugs y solicitudes de funcionalidad

Usar las plantillas de Issue en `.github/ISSUE_TEMPLATE/` (`bug_report.md` y `feature_request.md`).
