# Tracto Trak — Sistema de Gestión para el Autotransporte de Carga (SPF)

Aplicación móvil multiplataforma (Android/iOS) desarrollada en **Flutter** con backend **Node.js/Express** y base de datos **MongoDB**, diseñada para digitalizar el control operativo y financiero del autotransporte de carga federal.

## Módulos principales

| Módulo | Rol | Pantallas |
|--------|-----|-----------|
| Chofer en Ruta | Operador | C-01 a C-06 |
| Panel Administrativo | Dueño de Flota | A-01 a A-17 |

## Stack tecnológico

- **Frontend:** Flutter (Dart) — Android e iOS
- **Backend:** Node.js + Express (API REST)
- **Base de datos:** MongoDB con Mongoose
- **Autenticación:** JWT + HTTPS
- **Offline:** Base de datos local embebida (sqflite/Hive)
- **Imágenes:** Almacenamiento externo (Firebase Storage / S3)

## Estructura del proyecto

```
├── backend/          # API REST (Node.js + Express + MongoDB)
├── frontend/         # App móvil (Flutter/Dart)
└── docs/             # Documentación técnica
    └── context/      # PDFs fuente (NO modificar)
```

## Inicio rápido

### Backend
```bash
cd backend
cp .env.example .env          # Configurar variables de entorno
npm install
npm start                     # Inicia el servidor en el puerto configurado
npm test                      # Ejecuta las pruebas con Jest
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run                   # Ejecuta la app en el dispositivo/emulador
flutter test                  # Ejecuta las pruebas
```

## Documentación

Consulta el [índice de documentación](docs/README.md) para acceder a la arquitectura, API, modelos de datos, trazabilidad y más.

## Control de versiones

- **Estrategia:** Gitflow simplificado (`main`, `develop`, `feature/*`, `release/*`, `fix/*`)
- **Commits:** Conventional Commits (`tipo(alcance): descripción`)
- **Repositorio:** [Pendiente: completar con el enlace real del repositorio]
