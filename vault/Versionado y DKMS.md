---
tags: [dkms, versionado, procedimiento]
fecha: 2026-08-22
---

# Versionado y DKMS

## Política del repo

La versión del paquete DKMS (`VER` en `install_manual.sh`) **es** el versionado del fork.
Bump semver: PATCH para build/compat, MINOR para comportamiento, MAJOR estructural.

Tres ficheros deben estar sincronizados (el job `sanity` del CI lo verifica):
`dkms.conf` (`PACKAGE_VERSION`), `install_manual.sh` (`VER`), changelog en `AGENTS.md`.

## Historial de esta sesión

| Versión | Qué |
|---|---|
| 1.6.4 | CI reparado (ver [[Reparación del CI]]) |
| 1.7.0 | [[Bitrate en NetworkManager y KDE]] — dump_station + tasas dinámicas |

Estado real encontrado: AGENTS.md decía "1.6.3 registrado en DKMS" pero el sistema
tenía **1.6.2** — documentación desactualizada, corregida durante las migraciones.

## Procedimiento de migración (documentado en AGENTS.md)

```bash
sudo mkdir -p /usr/src/rtl8192eu-NUEVA && \
sudo rsync -a --delete --exclude '.git' --exclude '*.o' --exclude '*.ko' \
  --exclude '*.cmd' --exclude '*.mod*' --exclude '.tmp_versions' \
  --exclude 'Module.symvers' --exclude 'modules.order' ./ /usr/src/rtl8192eu-NUEVA/
sudo dkms remove -m rtl8192eu -v VIEJA --all
sudo rm -rf /usr/src/rtl8192eu-VIEJA
sudo dkms add -m rtl8192eu -v NUEVA
sudo dkms build -m rtl8192eu -v NUEVA
sudo dkms install -m rtl8192eu -v NUEVA --force
```

## ⚠️ Trampa: caché de build de DKMS

Si se actualiza `/usr/src/rtl8192eu-<v>` con rsync pero la versión no cambió,
`dkms build` responde *"already built, skip"* e **instala el binario viejo**
aunque uses `install --force`. Forzar reconstrucción real:

```bash
sudo dkms remove -m rtl8192eu -v <v>   # borra /var/lib/dkms/.../build
sudo dkms build  -m rtl8192eu -v <v>
sudo dkms install -m rtl8192eu -v <v>
```

Verificación de que sí recompiló: comparar `srcversion` del `.ko`
(`strings ... | grep srcversion`) antes y después.

## Recarga del módulo en vivo

El módulo cargado en RAM no se actualiza solo. Opciones:
- `~/.local/bin/reload-wn8200nd-1ant` (corte ~10s, reconecta NM, reactiva debug EDCCA)
- reboot

Relacionado: [[Diagnóstico en vivo]] · [[Backlog]]
