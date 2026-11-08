# Control por toques de Dom

El control definitivo se introdujo en la **v1.0**. Una pulsación nueva de O/P mueve un solo carril, aunque se mantenga pulsada.

El archivo `patch_control.py` aplica exclusivamente el parche de movimiento al TAP **base generado**, que se llama `../CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap`. No uses como entrada el TAP v1.0 (ya está parcheado).

Para reproducir todo de manera segura, desde la raíz del repositorio ejecuta:

```bash
python3 -m pip install Pillow
python3 banco_de_trabajo/REBUILD_FINAL.py
```

No hace falta guardar ni subir el TAP base: `REBUILD_FINAL.py` lo genera, aplica el parche y comprueba la v1.0 y v1.1 oficiales byte por byte.

**Créditos:** © 2026 Tony C. Ware. Código MIT; gráficos con derechos separados.
