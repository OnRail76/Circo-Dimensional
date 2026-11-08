# Limpieza y archivo histórico del repositorio

La rama principal fue revisada tras publicar la edición definitiva v1.1.

## Principios

- Solo se distribuyen desde `juego/` los TAP oficiales **v1.0** y **v1.1**.
- Los TAP del banco de trabajo se regeneran mediante scripts y no se incluyen en Git.
- El historial de Git y las etiquetas de las Releases **no se reescriben**.
- Los archivos idénticos (fuentes, capturas, registros y BIN intermedios) dejan de duplicarse.
- Se conservan el listado de ensamblador base, los parches de teclado y v1.1 y las herramientas de pruebas.
- Los scripts generadores se prueban antes de eliminar sus resultados temporales.
- Las automatizaciones antiguas de publicación v1.0 se retiran para evitar reintroducir ficheros desfasados.

## Versiones originales

- [Release v1.0](https://github.com/OnRail76/Circo-Dimensional/releases/tag/v1.0)
- [Release v1.1](https://github.com/OnRail76/Circo-Dimensional/releases/tag/v1.1)

**Los juegos TAP de ambas versiones mantienen su SHA256 oficial.** La edición v1.1 conserva su jugabilidad tal como fue aprobada.

## Reconstruir

```bash
python3 -m pip install Pillow
python3 banco_de_trabajo/REBUILD_FINAL.py
```

El script contrasta los dos TAP locales con las dos versiones que figuran en `juego/`. No cambia ninguno de esos archivos oficiales.
