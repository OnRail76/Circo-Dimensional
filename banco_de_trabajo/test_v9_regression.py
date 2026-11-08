"""V10 full Z80-state regression: sprite pixels, HUD, unlimited shots and TAP."""
from pathlib import Path
import struct
p=Path(__file__).parent
src=(p/'test_engine.py').read_text()
ns={'__file__':str(p/'test_engine.py')}
exec(compile(src[:src.index('# Real regressions test Z80 instructions')],str(p/'test_engine.py'),'exec'),ns)
mem=ns['mem'];lab=ns['labels'];run=ns['run_to_frame'];val=ns['val']
assert 'energy' not in lab and 'regen_cd' not in lab
base=(p/'game.scr').read_bytes();tamer=(p/'tamer.spr').read_bytes()
def off(y,c):return ((y&192)<<5)|((y&7)<<8)|((y&56)<<2)|c
def compare_sprite(player):
 for lane in range(5):
  col=2+6*lane
  for row in range(4):
   for scan in range(8):
    y=(17+row)*8+scan
    for xcol in range(3):
     address=off(y,col+xcol)
     actual=mem[0x4000+address]
     expected=tamer[row*24+scan*3+xcol] if lane==player else base[address]
     assert actual==expected,('sprite bitmap',ns['frame'],player,lane,row,scan,xcol,hex(actual),hex(expected))
   for xcol in range(3):
    address=6144+(17+row)*32+col+xcol
    actual=mem[0x4000+address]
    expected=tamer[96+row*3+xcol] if lane==player else base[address]
    assert actual==expected,('sprite attribute',ns['frame'],player,lane,row,xcol,hex(actual),hex(expected))
 assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),('shadow discrepancy',ns['frame'])

run(2)
ns['keys']={'space'};run(4)
assert val('state')==1 and val('lives')==3
ns['keys']=set();run(6)
compare_sprite(val('player'))
movement_count=0
for n in range(150):
 # Interleave holds and releases. This forces many transitions between all lanes.
 old=val('player')
 ns['keys']={'p'} if n%48<24 else {'o'}
 mem[lab['spawn_cd']]=0;mem[lab['step_cd']]=0
 run(ns['frame']+1)
 compare_sprite(val('player'))
 movement_count+=int(old!=val('player'))
assert movement_count>=20,movement_count
print('PASS',movement_count,'player movements over 150 frames: exact 24x32 sprite and background restoration; no stale colors')

# New HUD is two regions; original scoreboard text never damaged by runtime updates.
for y in range(176,192):
 for col in list(range(0,10))+list(range(15,24))+list(range(30,32)):
  b=off(y,col)
  assert mem[0x4000+b]==base[b],('HUD label corruption',y,col)
for col in (25,27,29):
 for y in range(176,184):
  b=off(y,col)
  assert mem[0x4000+b]!=base[b] or y in (176,177,182,183)
print('PASS static scoreboard labels, three red life glyphs and no energy indicator')

# Unlimited shots: hold/release as often as desired, maintain lives and score.
ns['keys']=set();run(ns['frame']+1)
oldscore=val('score')
for i in range(24):
 ns['keys']={'space'}
 # force enemy to exist in player's lane before each shot
 lane=val('player');mem[lab['enemies']+lane]=2
 run(ns['frame']+1)
 ns['keys']=set();run(ns['frame']+1)
 assert val('state')==1,('lost lives during repeated shots',i)
assert (val('score')-oldscore)%256==24,(val('score'),oldscore)
print('PASS 24 repeated unlimited attacks and 24 captured octopuses, no charge limit')

# Basic header/TAP and binary payload, no accidental breakage.
tape=(p/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap').read_bytes();pos=0;blocks=[]
while pos<len(tape):
 size=struct.unpack_from('<H',tape,pos)[0];pos+=2
 block=tape[pos:pos+size];pos+=size
 assert len(block)==size and size>=2
 chk=0
 for b in block:chk^=b
 assert chk==0
 blocks.append(block)
assert pos==len(tape) and len(blocks)==6
assert blocks[5][1:-1]==(p/'CIRCO_NAVIDAD85_V10.bin').read_bytes()
print('PASS TAP 6 blocks, XOR checksums and machine-code binary identical')
