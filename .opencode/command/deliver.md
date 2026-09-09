---
description: Fase 5 - Entrega: READMEs finales, checklist de la prueba técnica y preparación del video.
agent: build
---

Ejecuta la Fase 5 — Entrega del proyecto aplicando el ciclo RPI (Research → Plan → Implement, ver `docs/40 Proceso/RPI Research Plan Implement`).

Instrucciones:

1. **Research**: revisa el checklist completo ([[Checklist de la prueba]]) y el estado de las fases anteriores.
2. **Plan**: define qué falta y prioriza; planifica los READMEs y el guion de video.
3. **Implement**: actualiza READMEs, checklist y guion.

1. Revisa cada repo contra el checklist de la prueba técnica (`docs/40 Proceso/Checklist de la prueba`):
   - Backend: JWT, pedidos, estados, realtime, migraciones, dockerizado, tests, Swagger, rate limiting, refresh tokens, logging.
   - Apps: Customer (login, registro, crear, listar/detalle, realtime) y Driver (login, listar, aceptar, actualizar estado).
   - Infra: RDS explicado (instancia/backups/HA), StorageService S3-ready, diagrama de arquitectura, docker, puntos extra (Lambda justificado, CloudFront explicado, CloudWatch, GitHub Actions, deploy, S3 real).
2. Actualiza el README de cada repo con instrucciones claras de instalación y uso.
3. Verifica que el vault esté completo y coherente (sin notas huérfanas, MOC actualizado).
4. Crea el checklist final en `docs/40 Proceso/Checklist de la prueba` con estado ✅/❌ por requisito.
5. Prepara material para el video opcional (máx. 5 min): guión breve en `docs/40 Proceso/Guion video`.
6. Reporta al usuario: estado de cada requisito del checklist y qué faltaría para un 100%.