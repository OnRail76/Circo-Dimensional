"""Extra V10 tests: pulpo stair-step painting, HUD digits/hearts, no leftover cells."""
from pathlib import Path
p=Path(__file__).parent
source=(p/'test_engine.py').read_text()
source=source[:source.index('# Real regressions test Z80 instructions')]
suite=r'''
from art import render_screen
from PIL import Image
run_to_frame(2)
keys={'space'};run_to_frame(4)
assert val('state')==1
keys=set()
def scr():return bytes(mem[0x4000:0x5b00])
def shadow():return bytes(mem[0x6000:0x7b00])
def byteoff(row,col,line=0):
 y=row*8+line
 return ((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|col
# Bitmapped custom digits 133 + 4*d, hearts 173 + indexes.
for pts in (0,7,49,108,255):
 mem[labels['score']]=pts
 run_to_frame(frame+3)
 assert val('pending_active')==0
 digits=[pts//100,pts//10%10,pts%10]
 for n,dig in enumerate(digits):
  col=10+2*n
  for quadrant,(dcol,drow) in enumerate(((0,0),(1,0),(0,1),(1,1))):
   bpos=labels['custom_font']+(133-128+4*dig+quadrant)*8
   for iy in range(8):
    assert mem[0x4000+byteoff(22+drow,col+dcol,iy)]==mem[bpos+iy],('big digit',pts,n,quadrant,iy)
 print('PASS large score',pts,digits)
for lives in (3,2,1,0,3):
 mem[labels['lives']]=lives
 run_to_frame(frame+3)
 assert val('pending_active')==0
 for n in range(3):
  col=25+2*n;base=173 if n<lives else 177
  for q,(dc,dr) in enumerate(((0,0),(1,0),(0,1),(1,1))):
   ofs=labels['custom_font']+(base-128+q)*8
   for iy in range(8):
    assert mem[0x4000+byteoff(22+dr,col+dc,iy)]==mem[ofs+iy],('big heart',lives,n,q)
 print('PASS big hearts',lives)
# Cancel all timers and keep other lanes empty; force each stair-step and disappearance.
bg=(p/'game.scr').read_bytes()
for lane in (0,1,3,4):
 for state in (1,2,3,4,0):
  mem[labels['enemies']+lane]=state
  mem[labels['step_cd']]=0;mem[labels['spawn_cd']]=0
  run_to_frame(frame+4)
  assert val('pending_active')==0,('pending after four frames',lane,state)
  assert scr()==shadow(),('compositor mismatch',lane,state)
  if state==0:
   for row in range(9,21):
    for col in range(2+6*lane,5+6*lane):
     assert scr()[6144+row*32+col]==bg[6144+row*32+col],('octopus attr residue',lane,row,col)
     for line in range(8):
      pos=byteoff(row,col,line)
      assert scr()[pos]==bg[pos],('octopus pixel residue',lane,row,col,line)
 print('PASS octopus entire staircase and cleanup, lane',lane)
# Adversarial five-at-once ascending and descending, still eventually caught up.
for state in (1,2,3,4,0):
 for lane in range(5):mem[labels['enemies']+lane]=state
 mem[labels['step_cd']]=0;mem[labels['spawn_cd']]=0
 run_to_frame(frame+16)
 assert val('pending_active')==0 and scr()==shadow(),('five lanes not synchronized',state)
 print('PASS five octopuses combined state',state)
print('ALL V10 CRITICAL VIDEO CHECKS PASSED',frame)
'''
exec(compile(source+suite,str(p/'test_v10_critical.py'),'exec'),{'__file__':str(p/'test_v10_critical.py')})
