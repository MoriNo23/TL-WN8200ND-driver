---
tags: [nl80211, cfg80211, networkmanager, kde]
fecha: 2026-08-22
estado: resuelto
---

# Bitrate en NetworkManager y KDE

## Síntoma

El applet de KDE (plasma-nm) mostraba la velocidad de conexión vacía/0 con este
adaptador; con otros adaptadores sí flotaba. `iwconfig` y `iw link` sí veían bitrate.

## Cadena completa: quién pide qué a quién

```
KDE plasma-nm → D-Bus Device.Wireless.Bitrate
             ← NetworkManager periodic_update()
             ← nm_platform_wifi_get_station()
             ← NL80211_CMD_GET_STATION con NLM_F_DUMP   ← ¡DUMP, no GET dirigido!
             ← kernel: nl80211_dump_station() → requiere ops->dump_station
             ← driver: cfg80211_rtw_dump_station()
```

Claves verificadas en el código fuente de NM 1.52.1 (`nm-wifi-utils-nl80211.c`):
- NM hace **dump** de estaciones, no un GET dirigido al BSSID.
- Sin `.dump_station` en `cfg80211_ops`, el kernel responde `-EOPNOTSUPP`.
- Con la callback, el kernel itera `idx=0,1,...`; corta con `-ENOENT`.
- Solo lee `NL80211_STA_INFO_TX_BITRATE` (y SIGNAL para las barras).

## Por qué fallaba este driver

1. La callback existía pero **no estaba registrada** salvo bajo `#ifdef CONFIG_AP_MODE`.
2. Aun registrada, solo recorre la lista de estaciones asociadas **a nosotros**
   (rol AP). En modo cliente esa lista está vacía → `-ENOENT` en idx=0 → dump vacío.
3. `get_station` (la consulta dirigida) sí funcionaba — por eso `iw link` mostraba bitrate.

## Fix aplicado

En `cfg80211_rtw_dump_station`: rama cliente que reporta como único peer al BSSID
actual delegando en `cfg80211_rtw_get_station`. Registro movido junto a `.get_station`.

Patrón de referencia mainline (drivers full-MAC): brcmfmac / wilc1000.

## Segunda parte: tasas dinámicas vs techo negociado

Primer intento reportaba `rtw_get_cur_max_rate()` = **techo negociado** (72.2 fijo).
Los drivers mainline fluctúan porque usan la decisión del rate control. Este árbol ya
tenía todo para hacerlo:

| Qué | Fuente |
|---|---|
| TX real | `psta->cmn.ra_info.curr_tx_rate` — el firmware la empuja vía C2H RA report |
| SGI actual | helper `rtw_get_current_tx_sgi()` |
| RX real | `psta->curr_rx_rate` — actualizada por paquete en `rtw_recv.c` |
| Conversión | `rtw_desc_rate_to_bitrate(bw, rate&0x7f, sgi)` → unidades 100 Kbps |

Unidades de nl80211: `rate_info.legacy` va en **100 kbit/s**.

Cambios:
- `get_station` llena `TX_BITRATE` y ahora también `RX_BITRATE` con tasas reales.
- `rtw_wx_get_rate` (wext/iwconfig) usa lo mismo con fallback al techo si aún no hay
  reporte del firmware.
