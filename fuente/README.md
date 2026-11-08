# Fuentes Z80 y binario base

- `CIRCO_NAVIDAD85_FINAL_2026.asm`: **listado completo del motor base** (sin el parche de control por toques ni las cuatro mejoras de v1.1).
- `CIRCO_NAVIDAD85_FINAL_2026.bin`: binario correspondiente al motor base.

**Importante:** estos dos archivos se mantienen como referencia del diseño original y **no equivalen por sí solos al ejecutable v1.1**. El resultado actual se obtiene aplicando en orden:

1. `banco_de_trabajo/Control_por_toques/patch_control.py` para el control por pulsaciones de la v1.0.
2. `publicacion/v1_1/reconstruir_v1_1.py` para la v1.1.

Usa `python3 banco_de_trabajo/REBUILD_FINAL.py` desde la raíz para reproducir y verificar las dos versiones.

**Código MIT, © 2026 Tony C. Ware. Los gráficos integrados se rigen por [LICENCIA_GRAFICOS.md](../LICENCIA_GRAFICOS.md).**
