"""Audit the 24x32 player graphic after every move + beam across 300 Z80 frames."""
from pathlib import Path
p=Path(__file__).parent
src=(p/'test_engine.py').read_text()
ns={'__file__':str(p/'test_engine.py')}
exec(compile(src[:src.index('# Real regressions test Z80 instructions')],str(p/'test_engine.py'),'exec'),ns)
mem=ns['mem']; lab=ns['labels'];run=ns['run_to_frame'];val=ns['val'];base=(p/'game.scr').read_bytes()
spr={False:(p/'tamer.spr').read_bytes(), True:(p/'tamer_fire.spr').read_bytes()}
def off(y,c):return ((y&192)<<5)|((y&7)<<8)|((y&56)<<2)|c
def inspect():
 pl=val('player'); fired=val('beam_cd')>0 and val('beam_lane')==pl
 for lane in range(5):
  col=2+6*lane;art=spr[fired]
  for row in range(4):
   for scan in range(8):
    y=(row+17)*8+scan
    for dx in range(3):
     o=off(y,col+dx)
     expected=art[row*24+scan*3+dx] if lane==pl else base[o]
     actual=mem[0x4000+o]
     assert actual==expected,('pixel',ns['frame'],pl,lane,fired,row,scan,dx,expected,actual)
   for dx in range(3):
    o=6144+(row+17)*32+col+dx
    expected=art[96+row*3+dx] if lane==pl else base[o]
    actual=mem[0x4000+o]
    assert actual==expected,('attribute',ns['frame'],pl,lane,fired,row,dx,expected,actual)
 assert mem[0x4000:0x5b00]==mem[0x6000:0x7b00]

run(2);ns['keys']={'space'};run(4);ns['keys']=set();run(6)
changes=0;fired_count=0
for i in range(300):
 prev=val('player')
 ks={'p'} if i%40<20 else {'o'}
 if i%11==0:ks.add('space')
 ns['keys']=ks
 mem[lab['spawn_cd']]=0;mem[lab['step_cd']]=0
 run(ns['frame']+1)
 inspect()
 changes+=int(val('player')!=prev)
 fired_count+=int(val('beam_cd')>0)
assert changes>=40,(changes,fired_count)
assert fired_count>=20,fired_count
print('PASS',300,'consecutive move/fire Z80 frames,',changes,'lane transitions,',fired_count,'active beam frames; every tamer pixel and color correct')
