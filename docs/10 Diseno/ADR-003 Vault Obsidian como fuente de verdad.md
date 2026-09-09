---
tags: [adr, decision, documentacion]
status: Aceptado
date: 2026-09-08
---

# ADR-003: Vault Obsidian como fuente de verdad

## Status

**Aceptado**

## Contexto

La prueba pide explicar decisiones (RDS, CloudFront, Lambda), funcionalidades e infraestructura. Sin un lugar canónico, la documentación se dispersa en READMEs sueltos y se pierde el "por qué".

## Decisión

Todo el conocimiento del proyecto vive en un **vault Obsidian** (`docs/`) con:

- **Wikilinks** `[[Nota]]` para grafos navegables.
- **ADRs** numerados en `10 Diseno/` (formato Nygard).
- **Map of Content** en `00 Inbox/MOC.md` como índice raíz.
- **Plantillas** en `90 Recursos/Templates/` (`Nota.md`, `ADR.md`).
- Estructura por carpetas: `00 Inbox`, `10 Diseno`, `20 Tecnico`, `30 Infraestructura`, `40 Proceso`, `90 Recursos`, `assets`.

Regla operativa: **antes de implementar**, revisar la nota relacionada; **después**, actualizarla. Toda decisión significativa genera un ADR.

## Consecuencias

### Positivas

- Fuente única de verdad, navegable y persistente.
- Reproducibilidad: la IA y el equipo consultan el mismo conocimiento.
- Cumple el requisito de "explicar" decisiones de la prueba (RDS, CloudFront, Lambda…).

### Negativas / Trade-offs

- Mantenimiento continuo (deuda si se omite).
- `docs/` es un repo git más que mantener.

### Neutrales

- Los READMEs de cada repo siguen siendo la puerta de entrada; el vault es el detalle profundo.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Afecta a:** [[Fases del proyecto]], todos los ADRs y notas técnicas