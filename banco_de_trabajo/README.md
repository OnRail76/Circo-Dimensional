# Banco de trabajo — herramientas de desarrollo

**Código MIT © 2026 Tony C. Ware.** Los sprites y los gráficos tienen derechos separados: [LICENCIA_GRAFICOS.md](../LICENCIA_GRAFICOS.md).

Este directorio reúne el generador original de arte y de código máquina Z80, las pantallas nativas, sprites, pruebas de regresión y una rutina para reconstruir las dos versiones publicadas.

Los archivos `.tap`, `.bin`, `.asm` y `.png` generados temporalmente **no se guardan aquí en Git**. Los archivos resultantes se pueden regenerar cuando hagan falta, sin conservar docenas de versiones antiguas.

## Reconstrucción completa, desde cero

Necesitas Python 3 y Pillow:

```bash
python3 -m pip install Pillow
python3 banco_de_trabajo/REBUILD_FINAL.py
```

El proceso es el siguiente:

1. `art.py` y `build.py` generan el código base, el TAP y las imágenes propias del motor.
2. `Control_por_toques/patch_control.py` produce la **v1.0** con O/P por pulsación.
3. `../publicacion/v1_1/reconstruir_v1_1.py` aplica las mejoras definitivas y obtiene la **v1.1**.
4. Se comprueba automáticamente que ambos TAP generados son **idénticos byte por byte** a los de `../juego/`.

La entrada local antigua del parche se reconstruye automáticamente, de modo que **no hace falta versionar los TAP intermedios**.

## Dónde está cada cosa

- `../juego/`: los **dos únicos TAP oficiales**, v1.0 y v1.1.
- `../fuente/`: un único listado ensamblador completo y BIN del motor base.
- `Control_por_toques/`: rutina de control por pulsaciones y parche.
- `../publicacion/v1_1/`: conversión reproducible de v1.0 a v1.1 y extracción del título.
- `../capturas/`: capturas publicadas, sin duplicarlas aquí.
- `../docs/`: manual, Atlas y notas técnicas de las versiones.

Los scripts de prueba conservados ejecutan verificaciones del motor base y de estados de memoria. Los registros `.log` generados por pruebas antiguas se han omitido por redundantes.

Los archivos históricos pueden consultarse en el **historial de Git** y en las Releases v1.0 y v1.1; la limpieza no ha reescrito ese historial.
