# Matriz comparativa y dictamen — Herramienta de comunicación

## Candidatas evaluadas

Slack, Microsoft Teams, Discord y Google Chat — las 4 opciones sugeridas en la práctica, evaluadas para un equipo de **4 personas** en un proyecto académico (10 Sprints semanales) con fuerte dependencia de GitHub.

## Matriz comparativa (1–5, 5 = mejor)

| Criterio | Slack | Teams | Discord | Google Chat |
|---|---|---|---|---|
| Canales/hilos | 5 | 4 | 4 | 3 |
| Reuniones/calendario | 3 | 5 | 3 | 3 |
| Llamadas de voz | 4 | 5 | 5 | 3 |
| Screen sharing | 4 | 5 | 5 | 3 |
| Bots/automatización | 5 | 3 | 5 | 2 |
| Integraciones dev (GitHub/Actions) | 5 | 4 | 4 | 3 |
| Permisos y roles | 4 | 5 | 4 | 3 |
| Seguridad/compliance | 4 | 5 | 3 | 4 |
| Límite de historial (plan gratuito) | 2 | 4 | 5 | 4 |
| Costo educativo (equipo de 4) | 4 | 4 | 5 | 5 |
| Facilidad móvil | 4 | 3 | 5 | 4 |
| Grabaciones de reuniones | 3 | 5 | 2 | 3 |
| **Total (máx. 60)** | **47** | **54** | **50** | **40** |

*Nota sobre los puntajes:* Slack pierde puntos por el límite de 90 días/10,000 mensajes en su plan gratuito, crítico para un proyecto de 10 semanas. Teams obtiene el mejor puntaje agregado gracias a que muchos estudiantes ya cuentan con licencia institucional (Microsoft 365 Educación) con historial y grabaciones sin límite, pero sus bots/automatización son más rígidos para integrarse con GitHub Actions. Discord es el más fuerte en costo, historial gratuito ilimitado, facilidad móvil y bots (webhooks nativos para CI), aunque más débil en compliance formal.

## Dictamen

Se elige **Discord** como herramienta de comunicación del equipo.

Los tres criterios que más pesaron en la decisión: **(1) costo educativo**, ya que el equipo no depende de licencias institucionales y Discord es gratuito sin límite de historial para 4 usuarios; **(2) bots/automatización**, porque Discord permite conectar un *webhook* directo de GitHub Actions a un canal para recibir notificaciones de builds, PRs e issues sin configuración compleja; y **(3) facilidad móvil**, relevante porque el equipo necesita coordinarse fuera de clase y la app cliente de Discord es ligera y confiable en Android/iOS. Microsoft Teams quedó como segunda opción muy cercana (mejor en reuniones/calendario y compliance) y se reconsiderará si el equipo obtiene licencia institucional durante el curso.

**Riesgos y mitigaciones:**
- *Discord no es percibido como "profesional" por todos los docentes/clientes* → se documentan las normas de uso (ver `guia-comunicacion.md`) para mantener un canal serio de trabajo, separado de lo informal.
- *Menor robustez de compliance frente a Teams/Slack* → no se comparte información sensible real (credenciales, datos de clientes) por Discord; los *secrets* viven únicamente en GitHub Actions.
- *Dependencia de que todo el equipo instale y mantenga activa la cuenta* → se define el canal `#anuncios` con notificaciones obligatorias y un SLA de respuesta (ver guía de comunicación).
