---
tags: [proceso, git, convenciones]
status: permanente
date: 2026-09-08
---

# Convenciones git y commits

> Reglas de versionado en los repos del proyecto. Ver [[ADR-002 Estructura multi-repositorio]].

## Estructura

- El proyecto es un **monorepo único** `imagine-delivery` (ver [[ADR-008 Monorepo unico]]). Las apps móviles se agrupan en `mobile/` ([[ADR-007 Monorepo de apps moviles]]).

## Commits

- Mensajes en español (o inglés si el repo lo define), formato **Conventional Commits**:

```
feat(auth): login con refresh tokens
fix(orders): validar transición PICKED_UP solo para driver asignado
feat(customer): pantalla de detalle de pedido
feat(driver): aceptar pedido con realtime
feat(shared): cliente HTTP común con interceptor JWT
docs(infra): ADR-006 lambda order-timeout-canceller
test(auth): cobertura de rate limiting en login
chore(ci): job de lint en GitHub Actions
```

Tipos: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `ci`, `style`, `perf`, `build`.

- En `mobile/` los commits SIEMPRE llevan scope de app: `feat(customer)`, `fix(driver)`, `feat(shared)`.
- **Commits atómicos** (monorepo): un cambio de feature toca API + app + docs en un mismo commit; scopes por artefacto: `feat(backend)`, `feat(customer)`, `feat(driver)`, `feat(shared)`, `feat(infra)`, `docs(vault)`.
- No commitear secretos: `.env*`, credenciales → `.gitignore` (verificar con `git status` antes de commitear).

## Ramas y PR

- `main` siempre verde (CI pasa).
- Ramas por feature: `feat/auth-refresh`, `fix/ws-reconnect`.
- PRs con: descripción, checklist de calidad (tests, lint), link a la nota del vault si aplica.

## Releases

- Tags semver: `v0.1.0`, `v1.0.0` en cada repo.
- El README del repo refleja el estado actual.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Fases del proyecto]], [[Testing y calidad]]