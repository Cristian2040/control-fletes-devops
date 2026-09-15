# Guía de comunicación del equipo — Control de Fletes

**Herramienta:** Discord (ver `matriz-comunicacion.md` para el dictamen completo).

## Estructura del servidor

**Canales de texto:**

| Canal | Propósito |
|---|---|
| `#anuncios` | Solo lectura salvo Scrum Master/PO. Avisos de Sprint Planning, Review, cambios de prioridad. |
| `#dev` | Discusión técnica de mobile + backend, dudas de implementación, revisión de PRs. |
| `#qa` | Reporte y seguimiento de bugs, resultados de pruebas manuales (offline, seguridad, usabilidad). |
| `#ops` | Incidentes, despliegues, credenciales/cuotas, seguimiento del runbook. |
| `#dudas` | Preguntas generales del proyecto, dudas con la materia o con la profesora. |
| `#random` | Canal informal, no relacionado al proyecto. |

**Canales de voz:** `Daily Scrum` (uso diario, 10–15 min) y `Sprint Ceremonies` (Planning/Review/Retro los viernes/lunes).

**Bots/integraciones:**
- Webhook de **GitHub** → publica en `#dev` cada push a `develop`, cada PR abierto/cerrado y el resultado de cada corrida de CI.
- Webhook/bot con enlace fijado (pin) al **board de Jira** en `#anuncios`.
- App **GitHub for Jira** conectada al repositorio, para que cada commit/PR con el ID de la tarjeta (ej. `S0-01`) se enlace automáticamente en Jira.
- Evento recurrente (bot de calendario o mensaje anclado) con el horario del **Daily Scrum** y las fechas de Sprint Planning/Review/Retrospective.

## Normas de uso

- **SLA de respuesta:** mensajes en `#dev`, `#qa` y `#ops` se responden en un máximo de **4 horas en horario de clases/trabajo** (9:00–20:00, lunes a viernes); fuera de ese horario no se espera respuesta inmediata.
- **Horarios de trabajo síncrono:** Daily Scrum de lunes a viernes a la hora acordada por el equipo (10–15 min); Sprint Planning los lunes, Sprint Review y Retrospective los viernes (según lo definido en el Plan DevOps).
- **Formato para dudas técnicas:** al reportar un problema en `#dev` o `#qa`, incluir: *qué intentabas hacer → qué esperabas → qué obtuviste (log/captura) → rama o PR relacionado*.
- **Formato para incidentes en `#ops`:** título corto + severidad (alta/media/baja) + impacto + pasos ya intentados; si es severidad alta, mencionar directamente a Yair (mobile) o Cristian (backend) según el módulo afectado.
- **Uso de hilos (threads):** toda discusión que supere 3–4 mensajes debe moverse a un hilo para no saturar el canal principal; los hilos se cierran quienes los abrieron una vez resuelto el tema.
- **Uso de @menciones:** `@aquí`/`@everyone` reservado solo para Scrum Master en anuncios de Sprint; para pedir ayuda puntual, mencionar directamente a la persona responsable del módulo.
- **Idioma:** español para toda la comunicación del equipo; nombres de historias, commits y PRs en el idioma usado en el Product Backlog (español) para mantener consistencia.
