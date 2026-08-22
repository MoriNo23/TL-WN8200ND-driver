---
tags: [auditoria, apis, modernizacion, backlog-tecnico]
fecha: 2026-08-22
---

# Auditoría de APIs viejas

Motivación: los 4 bugs de hoy compartían patrón — código adaptado a APIs que el
stack moderno ya no usa igual ([[Bitrate en NetworkManager y KDE]], [[Herramientas pentest]]).
Sweep sistemático del árbol buscando más instancias del mismo mal.

## Hallazgos priorizados

| # | Hallazgo | Impacto | Riesgo del fix | Prioridad |
|---|---|---|---|---|
| 1 | **Doble API WEXT+cfg80211 con lógica duplicada divergente** — `iw_handler_def` sigue registrado junto a cfg80211; cada handler duplica lógica con variaciones (hoy: monitor TX gate, canal fantasma) | clase entera de bugs como los de hoy | alto (refactor a capa común) | media — documentado, actuar por síntomas |
| 2 | **Estado de canal multi-verdad**: 21 escritores de `mlmeextpriv.cur_channel`, 3 de `oper_ch`, 9 de `hal_data.current_channel` (+ DSConfig) | síntomas tipo "canal fantasma" en cualquier path nuevo | medio — unificar en `dvobj->oper_channel` con coccinelle | media |
| 3 | **407 shims de kernels <3.x/3.x** muertos sobre 6.12 | tamaño, superficie de error, legibilidad | bajo pero masivo — poda iterativa con unifdef/coccinelle versionada | baja continua |
| 4 | **Android-ismos compilados siempre**: `rtw_cfgvendor.o` (156 refs vendor-netlink de Google), `rtw_android.o`, `nlrtw.o` van al build desktop sin uso | KBs muertos + confusión | bajo-medio — poda estilo AUDIT 2.1 tras verificar referencias con cscope | alta (próxima sesión) |
| 5 | Ops cfg80211 ausentes menores: `.set_bitrate_mask`, `.set_cqm_rssi_config`, `.probe_client` | -EOPNOTSUPP aceptable hoy | bajo, agregar según demanda real | baja |

## Verificado SIN problema (no tocar)

- `reg_notifier` registrado vía `wifi_regd.c` + `WIPHY_FLAG_CUSTOM_REGULATORY` ✓
- WPA3-SAE: flag `NL80211_FEATURE_SAE` + `external_auth` + compat check ✓
- wiphy `.suspend` / `.resume` implementados ✓
- Private ioctls legacy: solo 3 referencias ✓
- Tabla ops: 68 entradas (dump_station/dump_survey/sched_scan incluidos) ✓

## Lección metodológica del día

Los bugs salieron de comparar **dos fuentes de verdad** que debían ser una:
- `WIFI_MONITOR_STATE` lo pone WEXT pero el gate de TX lo lee cfg80211
- `cur_channel` lo escribe el camino STA, el monitor lo lee WEXT
- `get_station` lo llenaba el driver, NM leía `dump_station`

Regla práctica para el fork: **cada vez que una herramienta moderna falle,
buscar primero si hay dos caminos (viejo/nuevo) con estados separados.**

Relacionado: [[Reparación del CI]] · [[Backlog]] · [[Versionado y DKMS]]
