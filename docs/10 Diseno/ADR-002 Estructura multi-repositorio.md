---
tags: [adr, decision, repositorios]
status: Aceptado
date: 2026-09-08
---

# ADR-002: Estructura multi-repositorio

## Status

**Superseded por [[ADR-008 Monorepo unico]]**

## Contexto

> Decisión original (2026-09-08). Fue reemplazada por el monorepo único al migrar a `imagine-delivery`. Se conserva como registro histórico de la evaluación inicial.

El proyecto tiene 4 entregables independientes (backend, dos apps móviles, infraestructura) más documentación. La prueba exige "Repositorio Git" como entregable y cada artefacto tiene ciclos de vida y equipos de interés distintos.

## Decisión

~~Usar un **workspace de coordinación** (meta-repo, sin git en la raíz salvo config) que contiene **repos git independientes**:~~

> **Ya no vigente.** Ver [[ADR-008 Monorepo unico]]. La migración movió `repos/delivery-api` → `backend/`, `repos/mobile` → `mobile/` y `repos/infra` → `infra/` dentro de un único repo git.

Reglas (históricas):
- Cada repo tenía su propio `AGENTS.md` y su historial.
- Nunca mezclar cambios entre repos en un mismo commit.
- El meta-repo solo versionaba: `.opencode/`, `opencode.json`, `AGENTS.md`, `scripts/`, `README.md`.

## Consecuencias

- **A favor (histórico):** entregables independientes, historiales limpios.
- **En contra (por eso se reemplazó):** commits cruzados, revisión dispersa, CI por repo — sin beneficio real para una prueba en solitario.