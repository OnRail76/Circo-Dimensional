# Parches que diferencian la v1.1 de la v1.0

La referencia reproducible es [reconstruir_v1_1.py](reconstruir_v1_1.py).

El script verifica el SHA256 de entrada de la v1.0, conserva los bloques de la cinta que no requieren cambios, modifica la pantalla de título para mostrar **VS**, ajusta ligeramente los intervalos de descenso desde los cinco puntos, añade la rutina de **tic breve** y protege el **GAME OVER durante cinco segundos**.

Después calcula correctamente las sumas XOR de los bloques TAP y exige que el resultado tenga exactamente la huella SHA256 oficial:

`9105d9679319aae0f4de445142276c1bfe7c65df36993e6f86ad87ddfa03dac1`

No se han añadido versiones alternativas ni ejecutables experimentales a este directorio.

La pantalla de título real se puede regenerar con [extraer_titulo.py](extraer_titulo.py).

Para reconstruir ambas versiones desde el origen:

```bash
python3 -m pip install Pillow
python3 banco_de_trabajo/REBUILD_FINAL.py
```
