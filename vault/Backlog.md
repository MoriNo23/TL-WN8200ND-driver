---
tags: [backlog, pendientes]
fecha: 2026-08-22
---

# Backlog

Pendientes detectados durante la sesión, sin resolver todavía.

## Cosméticos / bajo riesgo

- [x] **Node 20 deprecado en GitHub Actions**: `actions/checkout@v4` y
  `actions/upload-artifact@v4` fuerzan Node 24 con warning en cada run.
  Subir a v5 cuando toque (no bloquea, solo ruido). *(pendiente de bump v5)*
- [x] **Labels del reload script**: corregido al versionarlo en
  `scripts/reload-wn8200nd-1ant` (`rxgain esperado 0`). Resuelto 2026-08-22.

## Scripts consolidados (2026-08-22)

Quedó UN solo script: `install_manual.sh` (v4) — instala driver vía DKMS,
instala el reload script en `~/.local/bin`, recarga y reinicia NM.
`wifi_manager.sh` eliminado (redundante). El reload vive ahora versionado
en `scripts/reload-wn8200nd-1ant`. Procedimiento manual paso a paso en README.

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
