from pathlib import Path
import subprocess,sys,shutil
p=Path(__file__).resolve().parent
subprocess.check_call([sys.executable,str(p/'build.py')],cwd=p)
shutil.copyfile(p/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap',p/'CIRCO_DIMENSIONAL_NAVIDAD85_V12_CREDITOS.tap')
shutil.copyfile(p/'CIRCO_NAVIDAD85_V10.bin',p/'CIRCO_NAVIDAD85_V12_CREDITOS.bin')
shutil.copyfile(p/'CIRCO_NAVIDAD85_V10.asm',p/'CIRCO_NAVIDAD85_V12_CREDITOS.asm')
print('Recompilacion completa, pantalla con 2026 Tony C. Ware')
