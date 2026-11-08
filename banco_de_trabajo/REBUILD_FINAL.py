"""Verifica que los TAP v1.0 y v1.1 son reproducibles desde sus fuentes.
Los intermedios generados en banco_de_trabajo/ no se suben a Git.
Requiere: Python 3 y Pillow (python3 -m pip install pillow).
"""
from pathlib import Path
import subprocess, sys, hashlib, importlib.util

P = Path(__file__).resolve().parent
REPO = P.parent

def require_equal(actual, official, name):
    assert actual == official.read_bytes(), f'{name}: no coincide con el archivo publicado'
    print(f'{name}: correcto ({len(actual)} bytes; SHA256={hashlib.sha256(actual).hexdigest()})')

subprocess.run([sys.executable, str(P/'build.py')], cwd=P, check=True)
sys.path.insert(0, str(P/'Control_por_toques'))
import patch_control

v10_generated=P/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap'
v10_official=REPO/'juego'/'CIRCO_DIMENSIONAL_48K_v1.0.tap'
v11_official=REPO/'juego'/'CIRCO_DIMENSIONAL_48K_v1.1.tap'
v10_patched=P/'CIRCO_DIMENSIONAL_V1_0_RECONSTRUIDO.tap'
patch_control.build(input_tap=v10_generated, output_tap=v10_patched)
require_equal(v10_patched.read_bytes(), v10_official, 'v1.0')

script=REPO/'publicacion'/'v1_1'/'reconstruir_v1_1.py'
spec=importlib.util.spec_from_file_location('reconstruir_v1_1',script)
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
make=getattr(mod, 'rebuild', None) or getattr(mod, 'build')
require_equal(make(v10_official.read_bytes()), v11_official, 'v1.1')
print('VERIFICACIÓN COMPLETA — TAP oficiales intactos')
