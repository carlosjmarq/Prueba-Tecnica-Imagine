---
description: Crea un ADR (Architecture Decision Record) numerado en docs/10 Diseno con formato Nygard y wikilinks.
agent: docs
---

Crea un ADR en el vault Obsidian del proyecto.

Instrucciones:

1. Carga la skill `obsidian`.
2. Usa la plantilla `docs/90 Recursos/Templates/ADR.md`.
3. El usuario propone: $ARGUMENTS
   - Determina el siguiente número de ADR libre (revisa `docs/10 Diseno/`).
   - Nombre: `ADR-XXX Titulo descriptivo.md`.
4. Rellena con formato Nygard: Status (Propuesto por defecto), Context, Decision, Consequences.
5. Añade wikilinks a las notas afectadas (ej. `[[API Autenticacion]]`, `[[ADR-001 Eleccion de stack]]`).
6. Actualiza `docs/00 Inbox/MOC.md` y enlaza el ADR desde las notas relacionadas.
7. Reporta: número y ruta del ADR, notas enlazadas.