---
tags: [rf, dig, igi, edcca, interferencia]
fecha: 2026-08-22
---

# Sordera por momentos — mecanismo DIG/FA

Medición en vivo (`dbg 0 1` = DBG_DIG): `fa_cnt=1667` en ~2s, IGI oscilando
{0x26, 0x2c, 0x2a, 0x2c}. Mecanismo: ruido vecinal → tormenta de falsas alarmas
→ DIG sube IGI (desensibiliza) → el AP cae bajo el umbral de demodulación un
instante → silencio momentáneo → IGI baja y vuelve todo.

## Veredicto por ajuste propio

- `rxgain_offset_2g=0`: parcial — LNA a fondo maximiza sensibilidad Y las FA
- `th_l2h_ini=15 / hl_diff=5`: NO afecta recepción (solo CCA/TX deferral)
- 1T1R (`0x11`): parcial — sin diversidad para escapar nulos/golpes directos
- `smart_ps=0`, `enusbss=0`, parches USB: protectores (eliminan sorderas autoinfligidas)

## Raíz probable

Sangrado de canal adyacente: NAVI en ch11 rodeado por ch10 (COMPUTER -63dBm,
Rod) y ch12. Bleed comprobado hoy: beacon de un AP de ch10 capturado a
-64dBm estando sintonizado en ch11. La energía adyacente fabrica las FA.

## Caminos de mitigación (pendientes)

1. Mover NAVI al canal menos contaminado según survey completo de beacons
2. Experimento controlado `rxgain_offset_2g` 0 vs 4 en horas pico
   (throughput vs frecuencia de episodios de sordera)
3. Vigilar `fa_cnt` con `echo "dbg 0 1" > odm/cmd` activo durante un episodio real

Relacionado: [[Herramientas pentest]] · [[Auditoría de APIs viejas]]
