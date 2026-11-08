from pathlib import Path
import runpy
p=Path(__file__).parent
v=runpy.run_path(str(p/'build.py'))
labels=v['a'].lab
class ScreenTrackedMemory(bytearray):
 def __init__(self, n):
  super().__init__(n)
  self.visible_writes = 0
  self.shadow_writes = 0
  self.peak_block = 0
 def __setitem__(self, key, value):
  if isinstance(key, slice):
   start,stop,step=key.indices(len(self))
   if step==1:
    self.visible_writes += max(0,min(stop,0x5b00)-max(start,0x4000))
    self.shadow_writes += max(0,min(stop,0x7b00)-max(start,0x6000))
    self.peak_block = max(self.peak_block,max(0,min(stop,0x5b00)-max(start,0x4000)))
  else:
   if 0x4000<=key<0x5b00:self.visible_writes+=1
   if 0x6000<=key<0x7b00:self.shadow_writes+=1
  super().__setitem__(key,value)
mem=ScreenTrackedMemory(65536)
mem[32768:32768+len(v['code'])]=v['code']
from PIL import Image,ImageDraw,ImageFont
for i in range(0x3c00,0x4000):mem[i]=0
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf',8)
for digit in range(48,58):
 im=Image.new('1',(8,8),0);dr=ImageDraw.Draw(im);dr.text((0,-1),chr(digit),1,font=f)
 for y in range(8):
  mem[0x3c00+digit*8+y]=sum((1<<(7-x)) for x in range(8) if im.getpixel((x,y)))
r={x:0 for x in 'abcdehl'}
pc=32768;sp=0xff00;zf=False;cf=False;halted=0;instructions=0;frame=0;keys=set()

def rd():
 global pc
 x=mem[pc];pc=(pc+1)&65535;return x

def word():return rd()|(rd()<<8)
def hl():return r['h']*256+r['l']
def de():return r['d']*256+r['e']
def bc():return r['b']*256+r['c']
def sethl(n):r['h']=(n>>8)&255;r['l']=n&255
def setde(n):r['d']=(n>>8)&255;r['e']=n&255
def setbc(n):r['b']=(n>>8)&255;r['c']=n&255
def push(x):
 global sp
 sp=(sp-1)&65535;mem[sp]=(x>>8)&255;sp=(sp-1)&65535;mem[sp]=x&255
def pop():
 global sp
 x=mem[sp]|(mem[(sp+1)&65535]<<8);sp=(sp+2)&65535;return x

def do(op):
 global pc,sp,zf,cf,halted,frame
 if op==0xed:
  op=rd()
  if op==0x56:return
  if op==0x5f:r['a']=(instructions>>5)&255;return
  if op==0x53:
   addr=word();mem[addr]=r['e'];mem[addr+1]=r['d'];return
  if op==0x5b:
   addr=word();setde(mem[addr]|mem[addr+1]<<8);return
  if op==0xb0:
   n=bc();src=hl();dst=de();mem[dst:dst+n]=mem[src:src+n];sethl(src+n);setde(dst+n);setbc(0);return
  raise Exception('unknown ed '+hex(op))
 if op in (0xf3,0xfb):return
 if op==0x76:halted+=1;frame+=1;return
 if op==0x00:return
 if op==0xc9:pc=pop();return
 if op==0xc0:
  if not zf:pc=pop()
  return
 if op==0xc8:
  if zf:pc=pop()
  return
 if op==0xd0:
  if not cf:pc=pop()
  return
 if op==0xd8:
  if cf:pc=pop()
  return
 if op==0xcd:
  dest=word();push(pc);pc=dest;return
 if op==0xc3:pc=word();return
 if op in (0xc2,0xca,0xd2,0xda):
  dest=word()
  if {0xc2:not zf,0xca:zf,0xd2:not cf,0xda:cf}[op]:pc=dest
  return
 if op in (0x18,0x20,0x28,0x30,0x38,0x10):
  d=rd();d=d if d<128 else d-256
  if op==0x10:r['b']=(r['b']-1)&255
  ok=op==0x18 or op==0x20 and not zf or op==0x28 and zf or op==0x30 and not cf or op==0x38 and cf or op==0x10 and r['b']!=0
  if ok:pc=(pc+d)&65535
  return
 if op in (0x21,0x11,0x01,0x31):
  n=word()
  if op==0x21:sethl(n)
  elif op==0x11:setde(n)
  elif op==0x01:setbc(n)
  else:sp=n
  return
 if op==0x3a:r['a']=mem[word()];return
 if op==0x32:mem[word()]=r['a'];return
 if op==0x3e:r['a']=rd();return
 if op==0x06:r['b']=rd();return
 if op==0x0e:r['c']=rd();return
 if op==0x16:r['d']=rd();return
 if op==0x1e:r['e']=rd();return
 if op==0x26:r['h']=rd();return
 if op in (0x47,0x4f,0x57,0x5f,0x6f,0x7a,0x78,0x79,0x7c,0x7d,0x7e,0x5e,0x56,0x59,0x7b):
  assignments={0x47:('b','a'),0x4f:('c','a'),0x57:('d','a'),0x5f:('e','a'),0x6f:('l','a'),0x7a:('a','d'),0x78:('a','b'),0x79:('a','c'),0x59:('e','c'),0x7b:('a','e'),0x7c:('a','h'),0x7d:('a','l')}
  if op==0x7e:r['a']=mem[hl()]
  elif op==0x5e:r['e']=mem[hl()]
  elif op==0x56:r['d']=mem[hl()]
  else:
   dest,src=assignments[op];r[dest]=r[src]
  return
 if op==0xeb:
  x=hl();sethl(de());setde(x);return
 if op==0x77:mem[hl()]=r['a'];return
 if op==0x36:mem[hl()]=rd();return
 if op==0x12:mem[de()]=r['a'];return
 if op==0x23:sethl((hl()+1)&65535);return
 if op==0x19:sethl((hl()+de())&65535);return
 if op==0x29:
  x=hl()*2;sethl(x&65535);cf=x>65535;return
 if op==0x14:r['d']=(r['d']+1)&255;zf=r['d']==0;return
 if op==0x1d:r['e']=(r['e']-1)&255;zf=r['e']==0;return
 if op==0x04:r['b']=(r['b']+1)&255;zf=r['b']==0;return
 if op==0x0c:r['c']=(r['c']+1)&255;zf=r['c']==0;return
 if op==0x3c:r['a']=(r['a']+1)&255;zf=r['a']==0;return
 if op==0x3d:r['a']=(r['a']-1)&255;zf=r['a']==0;return
 if op==0x87:
  x=r['a']*2;cf=x>255;r['a']=x&255;zf=r['a']==0;return
 if op==0x83:
  x=r['a']+r['e'];cf=x>255;r['a']=x&255;zf=r['a']==0;return
 if op==0x81:
  x=r['a']+r['c'];cf=x>255;r['a']=x&255;zf=r['a']==0;return
 if op==0x80:
  x=r['a']+r['b'];cf=x>255;r['a']=x&255;zf=r['a']==0;return
 if op==0x91:
  x=r['a']-r['c'];cf=x<0;r['a']=x&255;zf=r['a']==0;return
 if op==0x90:
  x=r['a']-r['b'];cf=x<0;r['a']=x&255;zf=r['a']==0;return
 if op==0xb9:
  x=r['a']-r['c'];cf=x<0;zf=(x&255)==0;return
 if op==0xb8:
  x=r['a']-r['b'];cf=x<0;zf=(x&255)==0;return
 if op==0xba:
  x=r['a']-r['d'];cf=x<0;zf=(x&255)==0;return
 if op==0xbe:
  x=r['a']-mem[hl()];cf=x<0;zf=(x&255)==0;return
 if op==0x24:r['h']=(r['h']+1)&255;zf=r['h']==0;return
 if op==0xb7:zf=r['a']==0;cf=False;return
 if op==0xaf:r['a']=0;zf=True;cf=False;return
 if op==0xe6:r['a'] &=rd();zf=r['a']==0;cf=False;return
 if op==0xc6:
  x=r['a']+rd();cf=x>255;r['a']=x&255;zf=r['a']==0;return
 if op==0xd6:
  x=r['a']-rd();cf=x<0;r['a']=x&255;zf=r['a']==0;return
 if op==0xfe:
  x=r['a']-rd();cf=x<0;zf=(x&255)==0;return
 if op==0x0f:
  low=r['a']&1;r['a']=((r['a']>>1)|(low<<7))&255;cf=bool(low);return
 if op==0xd3:rd();return
 if op==0xdb:
  rd()
  if r['a']==0x7f:r['a']=0xfe if 'space' in keys else 0xff
  elif r['a']==0xdf:
   r['a']=0xff
   if 'o' in keys:r['a'] &=~2
   if 'p' in keys:r['a'] &=~1
  else:r['a']=0xff
  return
 if op in (0xc5,0xd5,0xe5,0xf5):
  v={0xc5:bc,0xd5:de,0xe5:hl,0xf5:lambda:(r['a']<<8)|(int(zf)<<6)|int(cf)}[op]()
  push(v);return
 if op in (0xc1,0xd1,0xe1,0xf1):
  v=pop()
  if op==0xc1:setbc(v)
  if op==0xd1:setde(v)
  if op==0xe1:sethl(v)
  if op==0xf1:r['a']=(v>>8)&255;zf=bool(v&64);cf=bool(v&1)
  return
 raise Exception(f'unknown opcode {op:02x} at {pc-1:04x}')

def run_to_frame(n):
 global instructions
 while frame<n:
  op=rd();instructions+=1
  try:do(op)
  except Exception as e:
   raise Exception(f'{e}; frame {frame} PC {pc:04x} state {mem[labels["state"]]} stack {sp:04x}') from e
  if instructions>100000000:raise Exception(f'infinite loop frame={frame} pc={pc:04x}')
def val(n):return mem[labels[n]]


# Real regressions test Z80 instructions and the actual screen memory.
from art import render_screen
from PIL import Image

def screenshot(name):
 screen=bytes(mem[0x4000:0x5b00])
 render_screen(screen).resize((768,576),Image.Resampling.NEAREST).save(p/name)
 return screen

def playfield_clean(screen):
 # pixels/attributes in cells outside the allowed movable regions must match the background.
 bg=(p/'game.scr').read_bytes()
 allowed=set()
 # Covers the five live sprite columns and all their possible vertical positions.
 for lane in range(5):
  for col in range(2+6*lane,5+6*lane):
   for row in range(9,21):allowed.add((row,col))
 # HUD tiles are dynamic.
 for row in (22,23):
  for col in range(32):allowed.add((row,col))
 for row in range(24):
  for col in range(32):
   if (row,col) in allowed:continue
   assert bg[6144+row*32+col]==screen[6144+row*32+col],f'attr corruption {row,col}'
   for dy in range(8):
    y=row*8+dy
    off=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|col
    assert bg[off]==screen[off],f'pixel corruption {row,col} scan {dy}'

run_to_frame(2)
assert val('state')==0,(val('state'),frame)
assert bytes(mem[0x4000:0x5b00])==(p/'title.scr').read_bytes(),'title page mismatch'
print('PASS title screen loaded perfectly',frame)
keys={'space'};run_to_frame(4)
assert val('state')==1,(val('state'),frame)
assert val('lives')==3
shot=screenshot('actual_game_initial.png')
playfield_clean(shot)
print('PASS start game video',frame, 'PC',hex(pc))
keys={'p'};run_to_frame(10)
assert val('player')>=3,(val('player'),frame)
shot=screenshot('actual_game_move.png');playfield_clean(shot)
print('PASS moving right and clean background',val('player'))
keys=set();run_to_frame(22)
shot=screenshot('actual_game_enemies.png');playfield_clean(shot)
# Force fresh enemy in lane and verify beam + hit overlay after SPACE release
lane=val('player');mem[labels['enemies']+lane]=2
keys={'space'};oldscore=val('score');run_to_frame(24)
assert val('score')==oldscore+1, (val('score'),oldscore,frame)
assert val('beam_cd')>0, ('beam not activated',frame)
shot=screenshot('actual_game_laser.png');playfield_clean(shot)
print('PASS beam, hit, score and no debris',frame)
keys=set();run_to_frame(30)
shot=screenshot('actual_game_erase_laser.png');playfield_clean(shot)
assert val('beam_cd')==0 and val('hit_cd')==0
# Key invariant: no beam bytes remain when the effect ends
bg=(p/'game.scr').read_bytes()
for row in range(9,17):
 col=4+6*lane
 for dy in range(8):
  y=row*8+dy;off=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|col
  if not any(mem[labels['enemies']+i] and i==lane for i in range(5)):
   assert shot[off]==bg[off],f'Laser residue at row{row} byte{off}'
print('PASS laser fully erased',frame)
# Change lane with repeated position changes, ensure snapshots keep static pixels exact
keys={'o'};run_to_frame(48)
shot=screenshot('actual_game_late.png');playfield_clean(shot)
assert val('player')<=2
print('PASS sprite compositing after movements',frame)
# Strong ghost-busting regression: empty all 5 lanes after several screen updates
# and require every gameplay pixel to be byte-identical to the stored background.
for i in range(5):mem[labels['enemies']+i]=0
for v in ('beam_cd','hit_cd','spawn_cd','step_cd'):mem[labels[v]]=0
keys=set();run_to_frame(54) # drain all pending lane updates within five frames
clearshot=bytes(mem[0x4000:0x5b00]);bg=(p/'game.scr').read_bytes()
for row in range(9,17):
 for col in range(32):
  assert clearshot[6144+row*32+col]==bg[6144+row*32+col],f'ghost color attr {row},{col}'
  for dy in range(8):
   y=row*8+dy;off=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|col
   assert clearshot[off]==bg[off],f'ghost pixels {row},{col},{dy}'
print('PASS complete restoration of empty arena (all pixel & color bytes)')
# More than 100 successive Z80-produced frames; not merely one static screenshot.
for nextframe in range(55,156):
 keys={'p'} if nextframe%13 in (0,1) else {'o'} if nextframe%17 in (0,1) else set()
 run_to_frame(nextframe)
 if val('state')==1:playfield_clean(bytes(mem[0x4000:0x5b00]))
print('PASS 101 consecutive video-state checks')
keys=set();# With the more forgiving V10 timings, make the three losses explicitly,
# rather than assuming a game-over by frame 450.
# Force a near-ground pulpo into one empty lane, and arrange step timer
# to reach its threshold. Preserve gameplay logic: no direct call to damage.
for loss_idx in range(3):
 if val('state')!=1:break
 lane_idx=loss_idx%5
 mem[labels['enemies']+lane_idx]=4
 mem[labels['step_cd']]=54
 mem[labels['spawn_cd']]=0
 run_to_frame(frame+2)
assert val('state')==2,(val('lives'),val('state'),frame)
shot=screenshot('actual_game_over.png')
print('PASS game over with three lives',frame)
keys={'space'};run_to_frame(frame+4)
assert val('state')==0,(val('state'),frame)
assert bytes(mem[0x4000:0x5b00])==(p/'title.scr').read_bytes()
print('PASS menu return without visual corruption',frame,'instructions',instructions)
# Verify exact equality of the visible and hidden composed frames, including attributes.
keys=set();run_to_frame(frame+1)
keys={'space'};run_to_frame(frame+2)
assert val('state')==1
keys=set();run_to_frame(frame+3)
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),('shadow and visible differ after new game',[(hex(i),mem[0x4000+i],mem[0x6000+i]) for i in range(6912) if mem[0x4000+i]!=mem[0x6000+i]][:30])

# Force multiple enemies to change. Publish one ready lane per second frame,
# allowing at least 16 ticks for 5 lanes (game step needs 55 ticks).
for lane in range(5):mem[labels['enemies']+lane]=lane%4+1
run_to_frame(frame+16)
assert val('state')==1
assert val('pending_active')==0, 'stuck pending enemy lane'
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),'multi-lane screen != shadow'
playfield_clean(bytes(mem[0x4000:0x5b00]))
print('PASS five simultaneous animated lanes match shadow screen byte-for-byte')

# Clear all five lanes, then let renderer restore all 5 with no new spawn.
for lane in range(5):mem[labels['enemies']+lane]=0
mem[labels['spawn_cd']]=0;mem[labels['step_cd']]=0
run_to_frame(frame+16)
assert val('pending_active')==0, 'stuck clear lane'
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),'screen != shadow after clearing'
keys=set();mem[labels['spawn_cd']]=0;mem[labels['step_cd']]=0
prior=mem.visible_writes
run_to_frame(frame+2)
assert mem.visible_writes==prior,('idle visible writes',mem.visible_writes-prior)
print('PASS idle gameplay: ZERO writes to visible Spectrum screen during idle')

# New enemy and beam in same lane.
mem[labels['enemies']+val('player')]=2
mem[labels['spawn_cd']]=0
run_to_frame(frame+1)
keys={'space'};run_to_frame(frame+1)
assert val('score')>=1
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),'laser compositor mismatch'
keys=set();run_to_frame(frame+7)
assert bytes(mem[0x4000:0x5b00])==bytes(mem[0x6000:0x7b00]),'laser cleanup mismatch'
playfield_clean(bytes(mem[0x4000:0x5b00]))
print('PASS offscreen laser render and cleanup, including the attribute bytes')
print('PASS compositor counters', 'visible writes', mem.visible_writes, 'shadow writes',mem.shadow_writes,'largest visible block',mem.peak_block)
print('ALL VIDEO AND LOGIC TESTS PASSED')
