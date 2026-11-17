# Banco de trabajo — herramientas de desarrollo

**Código MIT © 2026 Tony C. Ware.** Los sprites y los gráficos tienen derechos separados: [LICENCIA_GRAFICOS.md](../LICENCIA_GRAFICOS.md).

Este directorio reúne el generador original de arte y de código máquina Z80, las pantallas nativas, sprites, pruebas de regresión y una rutina para reconstruir la edición definitiva v1.1.

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
4. Se comprueba automáticamente que el TAP 1.1 generado es **idéntico byte por byte** al oficial de `../juego/`.

La entrada local antigua del parche se reconstruye automáticamente, de modo que **no hace falta versionar los TAP intermedios**.

## Dónde está cada cosa

- `../juego/`: el **único TAP oficial**, v1.1.
- `../fuente/`: un único listado ensamblador completo y BIN del motor base.
- `Control_por_toques/`: rutina de control por pulsaciones y parche.
- `../publicacion/v1_1/`: conversión reproducible de v1.0 a v1.1 y extracción del título.
- `../capturas/`: capturas publicadas, sin duplicarlas aquí.
- `../docs/`: manual, Atlas y notas técnicas de las versiones.

Los scripts de prueba conservados ejecutan verificaciones del motor base y de estados de memoria. Los registros `.log` generados por pruebas antiguas se han omitido por redundantes.

No se distribuyen TAP antiguos en la rama principal. Los artefactos intermedios se regeneran localmente para construir v1.1.
