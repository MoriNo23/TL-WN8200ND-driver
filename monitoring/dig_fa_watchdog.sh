#!/usr/bin/env bash
# dig_fa_watchdog.sh — muestreo pasivo de falsas alarmas (fa_cnt) e IGI del DIG
#
# Uso: ./dig_fa_watchdog.sh          (cron cada 30min o manual)
#
# Qué hace:
#   1. Habilita DBG_DIG (dbg 0 1) vía procfs odm/cmd
#   2. Espera ~6s para que el PHYDM loguee 2-3 ciclos de ajuste de IGI
#   3. Extrae el último fa_cnt e IGI del dmesg (requiere sudo para dmesg)
#   4. Deshabilita el debug y escribe una fila CSV con fecha-hora
#
# NO toca la red: la interfaz sigue conectada y operando normalmente.
# El debug solo agrega ~2s de mensajes en dmesg por ejecución.
#
# Archivos de log: monitoring/dig_fa_monitor_YYYY-MM-DD_HHMMSS.csv
# Columnas: timestamp, fa_cnt, igi_anterior, igi_nueva, igi_dyn_up_hit
#
# Interpretación:
#   fa_cnt alto (>500 por ciclo de ~2s) = tormenta de falsas alarmas =
#   ruido vecinal fuerte; el DIG sube IGI (desensibiliza) = episodio de sordera.
#   Con el tiempo el CSV muestra a qué horas pega cada vecino.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MONITOR_DIR="$REPO_DIR/monitoring"
NOW_FILE=$(date '+%Y-%m-%d_%H%M%S')
LOG_FILE="$MONITOR_DIR/dig_fa_monitor_${NOW_FILE}.csv"
ODM_CMD="/proc/net/rtl8192eu/wn8200nd/odm/cmd"
SAMPLE_SECS=6

if [[ ! -w /proc/net/rtl8192eu/wn8200nd/odm/cmd && $EUID -ne 0 ]]; then
    echo "ERROR: sin permiso para $ODM_CMD (usar sudo) o driver no cargado" >&2
    exit 1
fi

echo "timestamp,fa_cnt,igi_anterior,igi_nueva,igi_dyn_up_hit" > "$LOG_FILE"

# 1. habilitar DBG_DIG (bit 0)
echo "dbg 0 1" | sudo tee "$ODM_CMD" > /dev/null

# 2. muestrear
sleep "$SAMPLE_SECS"

# 3. extraer último ciclo reportado por phydm_dig
LAST=$(sudo dmesg | grep -E '\[PHYDM\] fa_cnt' | tail -1 || true)
if [[ -n "$LAST" ]]; then
    FA=$(echo "$LAST"    | grep -oE 'fa_cnt = [0-9]+'  | grep -oE '[0-9]+')
    IGI_A=$(echo "$LAST" | grep -oE 'IGI: 0x[0-9a-f]+ -> 0x[0-9a-f]+' | grep -oE '0x[0-9a-f]+' | head -1)
    IGI_N=$(echo "$LAST" | grep -oE 'IGI: 0x[0-9a-f]+ -> 0x[0-9a-f]+' | grep -oE '0x[0-9a-f]+' | tail -1)
    HIT=$(sudo dmesg | grep 'igi_dyn_up_hit' | tail -1 | grep -oE 'hit=[0-9]+' | cut -d= -f2)
    ROW="$(date '+%Y-%m-%d %H:%M:%S'),${FA:-NA},${IGI_A:-NA},${IGI_N:-NA},${HIT:-NA}"
else
    ROW="$(date '+%Y-%m-%d %H:%M:%S'),NO_SAMPLE,,, "
fi

# 4. deshabilitar debug
echo "dbg 0 2" | sudo tee "$ODM_CMD" > /dev/null

echo "$ROW" >> "$LOG_FILE"
echo "$ROW"

# alerta simple si la tormenta supera umbral arbitrario
FA_NUM=$(echo "$ROW" | cut -d, -f2 | grep -oE '^[0-9]+$' || echo 0)
if (( FA_NUM > 800 )); then
    echo ">> TORMENTA DE FA ($FA_NUM): episodio de desensibilizacion DIG probable"
fi
