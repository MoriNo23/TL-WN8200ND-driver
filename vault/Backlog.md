---
tags: [backlog, pendientes]
fecha: 2026-08-22
---

# Backlog

Pendientes detectados durante la sesión, sin resolver todavía.

## Cosméticos / bajo riesgo

- [ ] **Node 20 deprecado en GitHub Actions**: `actions/checkout@v4` y
  `actions/upload-artifact@v4` fuerzan Node 24 con warning en cada run.
  Subir a v5 cuando toque (no bloquea, solo ruido).
- [ ] **Labels desactualizados en `~/.local/bin/reload-wn8200nd-1ant`**: el paso 3
  dice "rxgain_offset_2g esperado 4" pero desde 2026-08-08 el valor correcto es 0
  (AGENTS.md). El script solo imprime; no rompe nada. Está fuera del repo (~/.local).

## Mejoras posibles del CI

- [ ] El job `build` compila contra los headers del runner (6.17/7.0 azure) pero el
  target real es Debian 6.12.x: considerar un job opcional en contenedor Debian.
- [ ] `ci/workflows/build.yml` es copia de staging de `.github/workflows/build.yml`
  — sincronizarlas si se edita una (o eliminarla y dejar solo la activa).

## Ideas

- [ ] Exponer también `NL80211_STA_INFO_SIGNAL_AVG`/beacon avg si las barras de
  señal de KDE quedaran estáticas (hoy se llena SIGNAL con signal_strength).
- [ ] Dump de estaciones completo en modo softAP (iterar asoc_list ya existe;
  falta llenar bitrate por estación).

Relacionado: [[Reparación del CI]] · [[Bitrate en NetworkManager y KDE]]
