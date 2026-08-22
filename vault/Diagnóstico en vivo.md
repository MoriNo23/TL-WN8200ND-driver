---
tags: [diagnostico, comandos]
fecha: 2026-08-22
---

# Diagnóstico en vivo

Comandos usados para separar driver→kernel de kernel→NM→KDE en la máquina target.
Interfaz del adaptador: `wn8200nd`.

## Ver dónde se corta la cadena

```bash
# 1. ¿El driver entrega bitrate al kernel? (GET dirigido al BSSID)
sudo iw dev wn8200nd link            # muestra "tx bitrate"

# 2. ¿El dump funciona? (lo que usa NetworkManager)
sudo iw dev wn8200nd station dump    # ANTES: vacío / DESPUÉS: lista el AP con tx/rx bitrate

# 3. ¿NM expone el valor a los applets?
busctl get-property org.freedesktop.NetworkManager \
  /org/freedesktop/NetworkManager/Devices/10 \
  org.freedesktop.NetworkManager.Device.Wireless Bitrate
```

- `iw link` OK + `station dump` vacío ⇒ falta `.dump_station` (fue nuestro caso).
- `station dump` OK pero `Bitrate` D-Bus en 0 ⇒ NM aún no sondeó (sondea cada ~30s
  estando ACTIVATED) o no hay conexión activa.

Encontrar el path D-Bus del dispositivo si cambia:
```bash
busctl tree org.freedesktop.NetworkManager | grep Devices
```

Nota: `iw` requiere sudo en este equipo.

## Otros datos útiles

```bash
nmcli -f GENERAL device show wn8200nd
cat /proc/net/rtl8192eu/wn8200nd/rx_signal     # RSSI por path RF
cat /proc/net/rtl8192eu/wn8200nd/rx_stat       # incluye rx_bitrate_100kbps
lsusb                                          # 2357:0126 = TL-WN8200ND
modinfo /lib/modules/$(uname -r)/updates/dkms/8192eu.ko.xz   # versión instalada
strings <ko> | grep srcversion                 # identidad exacta del build
```

Relacionado: [[Bitrate en NetworkManager y KDE]] · [[Versionado y DKMS]]
