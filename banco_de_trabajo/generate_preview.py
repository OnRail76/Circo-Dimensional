from pathlib import Path
p=Path(__file__).parent
s=(p/'test_engine.py').read_text().split('# Real regressions')[0]
tail=r'''
from PIL import Image
from art import render_screen
run_to_frame(2)
keys={'space'};run_to_frame(4)
keys=set();run_to_frame(8)
mem[labels['score']]=41
for lane,step in ((0,2),(2,1),(3,3),(4,4)):
 mem[labels['enemies']+lane]=step
mem[labels['step_cd']]=0;mem[labels['spawn_cd']]=0
run_to_frame(frame+17)
assert val('state')==1
assert val('pending_active')==0
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00])
render_screen(bytes(mem[0x4000:0x5b00])).resize((768,576),Image.Resampling.NEAREST).save(p/'PREVIA_V10_JUEGO.png')
print('Preview confirmed: 4 enemies, 41 points and no pending frame')
'''
exec(compile(s+tail,str(p/'generate_preview.py'),'exec'),{'__file__':str(p/'generate_preview.py')})
