# /app

Aquí vive el código fuente del producto, separado por capa:

```
/app
  /mobile     # App Flutter (módulo Operador + módulo Administrador)
  /backend    # API REST en Node.js/Express
```

El workflow de CI (`.github/workflows/ci.yml`) espera esta estructura:
- `app/mobile` con un proyecto Flutter válido (`pubspec.yaml` en la raíz de esa carpeta).
- `app/backend` con un proyecto Node.js válido (`package.json` en la raíz de esa carpeta).

Durante Sprint 0 estas carpetas se crean vacías (con un `flutter create .` y un `npm init` respectivamente) para que el pipeline de CI tenga algo que compilar/probar desde el primer Sprint funcional.
