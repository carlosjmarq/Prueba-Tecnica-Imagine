---
tags: [tecnico, diseno, uiux, flutter, tema]
status: implementado
date: 2026-09-09
---

# Design System de las apps

> Sistema de diseño de las apps móviles generado con la skill `ui-ux-pro-max` (estilo Vibrant & block-based). Aplicado en `mobile/packages/shared` y consumido por [[ADR-004 Estado de las apps]] → apps customer/driver.

## Decisiones clave

- **Estilo**: Vibrant & block-based — bold, energético, alto contraste. Ideal para una app de delivery de consumo masivo.
- **Colores**: naranja apetitoso `#EA580C` (primario, marca) + azul de confianza `#2563EB` (CTA/accent). Fondo cálido `#FFF7ED`.
- **Tipografía**: Playfair Display SC (headings) + Karla (body). En Flutter se cargan con `google_fonts`.
- **Spacing**: escala 4–64px (xs a 3xl). Botones ≥ 44px de alto (touch targets WCAG).
- **Feedback**: transiciones 200–300ms, estados de carga/error siempre presentes (UX async).
- **Navegación**: bottom nav ≤ 5 items; rutas nombradas.
- **Iconos**: Material Icons (SVG nativo de Flutter) — nunca emojis como iconos.

## Tokens

| Rol | Color | Uso |
| --- | ----- | --- |
| Primary | `#EA580C` | Marca, botones primarios, estados activos |
| On Primary | `#FFFFFF` | Texto sobre primary |
| Secondary | `#F97316` | Acentos secundarios |
| Accent/CTA | `#2563EB` | Acciones de conversión, links |
| Background | `#FFF7ED` | Fondo de pantallas |
| Foreground | `#0F172A` | Texto principal |
| Muted/Surface | `#FDF4F0` | Cards, superficies |
| Border | `#FCEAE1` | Bordes suaves |
| Destructive | `#DC2626` | Errores, cancelar, logout |

## Estados de pedido → color

| Estado | Color sugerido | Motivo |
| ------ | -------------- | ------ |
| PENDING | `#EA580C` (primary) | En espera, atención |
| ACCEPTED | `#2563EB` (accent) | Confirmado, avanza |
| PICKED_UP | `#F97316` (secondary) | En camino |
| DELIVERED | `#16A34A` (verde éxito) | Completado |
| CANCELLED | `#DC2626` (destructive) | Anulado |

## Fuente de verdad

Generado y persistido en `design-system/imagine-delivery/MASTER.md` (no se versiona el código, solo se referencia aquí). Las reglas por página estarían en `design-system/.../pages/` si existieran.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[ADR-004 Estado de las apps]], [[Realtime]]
- **Repo:** `mobile/packages/shared` (`lib/theme/`)