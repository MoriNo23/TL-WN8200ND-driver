---
tags: [ci, github-actions]
fecha: 2026-08-22
estado: resuelto
---

# Reparación del CI

El CI de `main` estaba roto en **cuatro capas encadenadas**. Cada una se
descubrió al arreglar la anterior (run 32590552467 → 32592275565 verde).

## 1. Workflow viejo con paquetes inexistentes

El workflow original instalaba `linux-headers-6.8/6.11/6.14-generic`, paquetes que
ya no existen en el runner: los jobs morían en `apt-get` sin compilar nunca.

- La solución ya estaba escrita pero **estacionada** en `ci/workflows/build.yml`
  (el PR #2 no podía tocar `.github/workflows/` por falta del permiso `workflows`).
- Activación = copiar a `.github/workflows/build.yml` + commit.
- El nuevo usa triggers `push`+`pull_request`+`dispatch`, job `sanity` rápido,
  `build` con KVER autodetectado y `bt-toggle`.

## 2. Sanity: parseo de la rama Kbuild

`make -C driver -f driver/Makefile ...` fallaba dos veces:
1. `-C driver` cambia el cwd → la ruta relativa buscaba `driver/driver/Makefile`.
2. Aunque la ruta sea correcta, la rama `ifneq ($(KERNELRELEASE),)` **no define
   targets** (la incluye el kbuild del kernel) → "No hay objetivos" exit 2.

Fix: target vacío inyectado:
```bash
make -C driver -f Makefile -n --eval='__sanity_parse:' __sanity_parse KERNELRELEASE=1 src=.
```
Makefile válido → 0; makefile roto → 2 (el chequeo sigue sirviendo).

## 3. modpost: símbolos indefinidos

Tras la poda AUDIT 2.1, tres símbolos quedaron sin definición:

| Símbolo | Causa | Fix |
|---|---|---|
| `PHY_CalculateBitShift` | `hal_phy.o` condicional a `CONFIG_RF_SHADOW_RW` (variable **sin asignar**) con 6 llamadores sin guard | compilar incondicional (`$(MODULE_NAME)-y`) |
| `phydm_psd_init/debug` | macro `CONFIG_PSD_TOOL` viene definido desde `phydm_features_iot.h` pero la variable de make nunca se puso a `y` | `CONFIG_PSD_TOOL = y` en el Makefile |

Lección: la poda AUDIT 2.1 asumió "contenido bajo ifdef desactivado" revisando solo
los guards de C, pero PHYDM define sus macros en **headers de features**, no en el
Makefile. Dos fuentes de verdad.

Diagnóstico hecho con [[cscope]] (`cscope -dL -3` + grep textual) según la skill del repo.

## 4. Aserciones con símbolos inventados

El step "Parámetros y features" exigía `rtw_ap_mode_sta_assoc_state_notify` y
`rtw_ap_br_port_control`: **no existen en el árbol** (nombres inventados por el
agente del PR #2). Reemplazados por globales reales de `core/rtw_ap.c`
(`rtw_check_beacon_data`, `init_mlme_ap_info`, `rtw_macaddr_acl_init`) — todo el
fichero vive bajo `#ifdef CONFIG_AP_MODE`, así que su presencia acredita AP mode.

## 5. Artefacto que nunca subía

El upload corría **después** de `make clean` → `.ko` inexistente → warning.
Reordenado: subir antes del clean.

## Estado final

Verde: sanity + build×2 (kernels 6.17/7.0 del runner) + bt-toggle.
Avisos cosméticos pendientes: deprecación Node 20 en actions@v4 (ver [[Backlog]]).

Relacionado: [[Versionado y DKMS]]
