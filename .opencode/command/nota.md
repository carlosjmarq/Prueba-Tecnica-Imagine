---
description: Crea una nota nueva en el vault Obsidian usando la plantilla y la enlaza al MOC.
agent: docs
---

Crea una nota en el vault Obsidian del proyecto.

Instrucciones:

1. Carga la skill `obsidian`.
2. Usa la plantilla `docs/90 Recursos/Templates/Nota.md` como base.
3. El usuario quiere: $ARGUMENTS
   - Título de la nota (nombre de archivo sin extensión, sin caracteres especiales problemáticos).
   - Carpeta destino según el tipo:
     - Decisión de diseño → `docs/10 Diseno/`
     - Documentación técnica/funcional → `docs/20 Tecnico/`
     - Infraestructura → `docs/30 Infraestructura/`
     - Proceso/herramientas → `docs/40 Proceso/`
     - Captura rápida/pendiente → `docs/00 Inbox/`
4. Rellena el frontmatter (tags, status, date) y el cuerpo con contenido completo y en español.
5. Añade wikilinks relevantes: MOC, notas relacionadas, ADRs.
6. Actualiza `docs/00 Inbox/MOC.md` para incluir la nota nueva.
7. Reporta: ruta de la nota creada, wikilinks añadidos.