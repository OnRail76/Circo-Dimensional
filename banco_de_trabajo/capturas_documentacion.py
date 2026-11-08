"""Generate truthful documentation captures from 48K bitmap produced by Z80 partial simulator.
Test scenario may force enemy positions and beam clock to ensure visible state;
never alters game binary. """
from pathlib import Path
p=Path(__file__).parent
source=(p/'test_engine.py').read_text().split('# Real regressions test Z80 instructions')[0]
code=r'''
from PIL import Image
from art import render_screen

def shot(name):
 raw=bytes(mem[0x4000:0x5b00])
 render_screen(raw).resize((768,576),Image.Resampling.NEAREST).save(p/name)
 return raw

run_to_frame(2)
keys={'space'};run_to_frame(4)
keys=set();run_to_frame(8)
assert val('state')==1
mem[labels['score']]=41
for lane,step in ((0,2),(1,1),(3,3),(4,4)):
 mem[labels['enemies']+lane]=step
mem[labels['spawn_cd']]=0;mem[labels['step_cd']]=0
run_to_frame(frame+20)
assert val('pending_active')==0
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00])
shot('DOC_PULPOS_Z80.png')
# Controlled test of the real beam painter: keep its timer active long enough to
# allow low-priority beam band to publish from hidden RAM.
mem[labels['beam_lane']]=2
mem[labels['beam_cd']]=26
mem[labels['spawn_cd']]=0;mem[labels['step_cd']]=0
run_to_frame(frame+17)
assert val('beam_cd')>0 and val('pending_active')==0
shot('DOC_LATIGAZO_Z80.png')
print('GENERATED DOC SHOTS frame',frame,'beam_cd',val('beam_cd'))
'''
exec(compile(source+code,str(p/'capturas_documentacion.py'),'exec'),{'__file__':str(p/'capturas_documentacion.py')})
