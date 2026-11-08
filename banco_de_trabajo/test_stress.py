"""Execute >1500 simulated 48K interrupt frames and audit the video memory.
Test uses the partial Z80 instruction interpreter in test_engine.py; it is
not a substitute for actual Spectrum/Fuse execution or cycle-exact verification.
"""
from pathlib import Path
import struct
P=Path(__file__).parent
src=(P/'test_engine.py').read_text()
script=r'''
print('RUNNING EXTENDED VIDEO STRESS TEST')
start_t=frame
max_shadow_mismatch=0
active=0
restarts=0
for target in range(start_t+1,1601):
 state_now=val('state')
 if state_now==0:
  keys={'space'} if target%4==0 else set()
 elif state_now==2:
  keys={'space'} if target%4==0 else set()
 else:
  # Alternating high-rate joystick movement and edge-triggered attacks.
  keys={'p'} if target%37 in range(0,9) else {'o'} if target%41 in range(0,8) else {'space'} if target%17==0 else set()
 run_to_frame(target)
 if val('state')==1:
  active+=1
  visible=mem[0x4000:0x5b00]
  shadow=mem[0x6000:0x7b00]
  if val('pending_active'):
   # One enemy has been fully painted in the offscreen buffer but is
   # intentionally scheduled for the next interrupt. No other lane,
   # stage detail or HUD cell may differ from visible memory.
   lane=val('pending_lane');c0=2+6*lane
   dirty_rows=set(range(val('pending_start'),val('pending_end')))
   for pos,(v,s) in enumerate(zip(visible,shadow)):
    if v==s:continue
    if pos>=6144:
     cell=pos-6144;row=cell//32;col=cell%32
    else:
     y=((pos>>8)&7)|((pos>>2)&0x38)|((pos>>5)&0xC0)
     row=y//8;col=pos%32
    assert row in dirty_rows and c0<=col<c0+3, (target,'changed cell outside pending enemy',row,col,lane)
  else:
   assert visible==shadow,f'frame {target}: visible buffer differs from offscreen composed image'
  playfield_clean(visible)
 elif val('state')==0:
  assert bytes(mem[0x4000:0x5b00])==(p/'title.scr').read_bytes(),f'frame {target} title mismatch'
print('PASS EXTENDED',frame,'interrupt frames total,',active,'gameplay screen audits')
'''
ns={'__file__':str(P/'test_engine.py')}
exec(compile(src+script,str(P/'test_stress.py'),'exec'),ns)
# separate independent tape integrity test
blob=(P/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap').read_bytes()
pos=0;blocks=[]
while pos < len(blob):
 assert pos+2<=len(blob)
 length=struct.unpack_from('<H',blob,pos)[0]; pos+=2
 block=blob[pos:pos+length];assert len(block)==length;pos+=length
 assert length>=2 and not (lambda xs:__import__('functools').reduce(lambda a,b:a^b,xs,0))(block),('invalid XOR block',len(block))
 blocks.append(block)
assert pos==len(blob) and len(blocks)==6
assert blocks[0][0]==0 and blocks[1][0]==255 and blocks[2][0]==0 and blocks[3][0]==255 and blocks[4][0]==0 and blocks[5][0]==255
assert len(blocks[3])==6914 and len(blocks[5])==len((P/'CIRCO_NAVIDAD85_V10.bin').read_bytes())+2
print('PASS tape integrity: all 6 Spectrum TAP blocks and checksums')
