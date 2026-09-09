# docs — Vault Obsidian

Vault Obsidian del proyecto: decisiones de diseño, documentación técnica, infraestructura y proceso.

> Carpeta dentro del monorepo `imagine-delivery` ([[ADR-008 Monorepo unico]]). Este vault es la **fuente de verdad** del proyecto (ver [[ADR-003 Vault Obsidian como fuente de verdad]]).

## Estructura

```
00 Inbox/           # MOC + captura rápida
10 Diseno/          # ADRs y decisiones (formato Nygard)
20 Tecnico/         # funcionalidades técnicas (API, modelo de datos, realtime...)
30 Infraestructura/ # AWS, RDS, S3, CloudFront, CloudWatch, Lambda, Docker
40 Proceso/         # fases, setup, checklist, convenciones
90 Recursos/        # plantillas (Nota, ADR)
assets/             # adjuntos y diagramas
```

## Uso

- Abrir la carpeta `docs/` como vault en Obsidian.
- Navegar desde `00 Inbox/MOC`.
- Notas nuevas: plantilla `90 Recursos/Templates/Nota` (comando `/nota`).
- ADRs nuevos: plantilla `90 Recursos/Templates/ADR` (comando `/adr`).

## Reglas

- Wikilinks por nombre de archivo sin extensión.
- Cada tarea de código: revisar la nota relacionada ANTES, actualizarla DESPUÉS.
- Toda decisión significativa → ADR numerado.
- MOC siempre al día.