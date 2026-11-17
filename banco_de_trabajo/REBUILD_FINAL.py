"""Reconstruye exclusivamente el TAP definitivo v1.1 desde el motor fuente.
El TAP intermedio de control por toques se genera localmente y no se publica.
Requiere Python 3 y Pillow.
"""
from pathlib import Path
import subprocess, sys, hashlib, importlib.util
P = Path(__file__).resolve().parent
REPO = P.parent
subprocess.run([sys.executable, str(P/'build.py')], cwd=P, check=True)
sys.path.insert(0, str(P/'Control_por_toques'))
import patch_control
generated_base=P/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap'
intermediate=P/'CIRCO_DIMENSIONAL_V1_0_RECONSTRUIDO.tap'
patch_control.build(input_tap=generated_base, output_tap=intermediate)
script=REPO/'publicacion'/'v1_1'/'reconstruir_v1_1.py'
spec=importlib.util.spec_from_file_location('reconstruir_v1_1',script)
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
make=getattr(mod,'rebuild',None) or getattr(mod,'build')
actual=make(intermediate.read_bytes())
official=REPO/'juego'/'CIRCO_DIMENSIONAL_48K_v1.1.tap'
assert actual==official.read_bytes(), 'La compilación no coincide con v1.1 oficial'
print(f'v1.1 correcta: {len(actual)} bytes; SHA256={hashlib.sha256(actual).hexdigest()}')
