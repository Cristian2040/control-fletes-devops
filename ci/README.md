# /ci

Scripts auxiliares de CI/CD que no forman parte del workflow declarativo de GitHub Actions (el cual vive en `.github/workflows/ci.yml`, ubicación estándar requerida por GitHub).

Ejemplos de lo que puede vivir aquí conforme avance el proyecto:
- `bump-version.sh` — script para actualizar el número de versión en `pubspec.yaml` antes de un tag.
- `check-coverage.sh` — script que valida el umbral mínimo de cobertura definido en `docs/plan-devops.md` (Apartado 6).
- Scripts de despliegue a Firebase App Distribution (Fastlane lanes o CLI de Firebase), cuando se automatice el paso de **Deploy** descrito en el Plan DevOps.

Por ahora (Sprint 0) esta carpeta queda como base para esos scripts futuros.
