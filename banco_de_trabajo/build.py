"""Assemble an original Spectrum 48K Z80 action game and TAP without external assembler.
Machine code source emitted in build/CIRCO_NAVIDAD85_V10.asm.
"""
from pathlib import Path
import struct,zipfile,runpy
P=Path(__file__).parent
# pixel art is built independently and is exactly the byte data used by the Z80 engine
import art
class ASM:
 def __init__(self):self.org=0x8000;self.buf=bytearray();self.lab={};self.fix=[];self.lines=[]
 def pc(self):return self.org+len(self.buf)
 def L(self,n):
  if n in self.lab:raise RuntimeError('duplicate '+n)
  self.lab[n]=self.pc();self.lines.append(n+':')
 def O(self,h,s=None):
  data=bytes.fromhex(h);self.buf+=data
  self.lines.append('    '+(s if s is not None else 'DB '+','.join('$%02X'%v for v in data)))
 def Imm(self,op,n,s):self.O(op+f'{n&255:02X}',s)
 def Fix(self,op,x,s,relative=False):
  self.buf+=bytes.fromhex(op);offset=len(self.buf)
  self.buf+=b'\x00' if relative else b'\x00\x00'
  self.fix.append((offset,x,relative));self.lines.append('    '+s)
 def Data(self,dat,label=None):
  if label:self.L(label)
  self.buf+=dat
  for i in range(0,len(dat),16):self.lines.append('    DB '+','.join('$%02X'%b for b in dat[i:i+16]))
 def DW(self,x):self.Fix('',x,f'DW {x}')
 def resolve(self):
  for p,x,r in self.fix:
   adr=(self.lab[x[0]]+x[1]) if isinstance(x,tuple) else (self.lab[x] if isinstance(x,str) else x)
   if r:
    d=adr-(self.org+p+1)
    if not (-128<=d<=127):raise RuntimeError(f'JR out of range {x} {d}')
    self.buf[p]=d&255
   else:self.buf[p:p+2]=struct.pack('<H',adr)
  return bytes(self.buf)
a=ASM();L=a.L;O=a.O
V=lambda n:a.Imm('3E',n,f'LD A,{n}')
B=lambda n:a.Imm('06',n,f'LD B,{n}')
C=lambda n:a.Imm('0E',n,f'LD C,{n}')
D=lambda n:a.Imm('16',n,f'LD D,{n}')
E=lambda n:a.Imm('1E',n,f'LD E,{n}')
def W(op,x,t):a.Fix(op,x,t)
def CALL(x):W('CD',x,f'CALL {x}')
def JP(x):W('C3',x,f'JP {x}')
def JZ(x):W('CA',x,f'JP Z,{x}')
def JNZ(x):W('C2',x,f'JP NZ,{x}')
def JNC(x):W('D2',x,f'JP NC,{x}')
def JC(x):W('DA',x,f'JP C,{x}')
def JR(op,x,t):a.Fix(op,x,f'JR {t},{x}' if t else f'JR {x}',True)
def JR0(x):JR('18',x,'')
def JRZ(x):JR('28',x,'Z')
def JRNZ(x):JR('20',x,'NZ')
def JRC(x):JR('38',x,'C')
def JRNC(x):JR('30',x,'NC')
def DJ(x):a.Fix('10',x,f'DJNZ {x}',True)
def HL(x):W('21',x,f'LD HL,{x}')
def DE(x):W('11',x,f'LD DE,{x}')
def BC(x):W('01',x,f'LD BC,{x}')
def LD(x):W('3A',x,f'LD A,({x})')
def ST(x):W('32',x,f'LD ({x}),A')
def key_space():V(0x7F);O('DBFE','IN A,($FE)');O('E601','AND 1')

def copy_scr(name):HL(name);DE(0x4000);BC(6912);O('EDB0','LDIR')

L('start');O('F3','DI');W('31',0xFF00,'LD SP,$FF00');O('ED56','IM 1');O('FB','EI');V(0);O('D3FE','OUT ($FE),A');CALL('menu')
L('main');O('76','HALT');LD('state');O('B7','OR A');JZ('menu_tick');O('FE01','CP 1');JZ('game_tick');JP('over_tick')
L('menu');O('AF','XOR A');ST('state');ST('pressed');copy_scr('title_scr');CALL('beep_intro');O('C9','RET')
L('menu_tick');CALL('space_edge');O('B7','OR A');JZ('main');CALL('new_game');JP('main')
L('over_tick');CALL('space_edge');O('B7','OR A');JZ('main');CALL('menu');V(1);ST('pressed');JP('main')
L('space_edge')
key_space();JRNZ('space_release')
LD('pressed');O('B7','OR A');JRZ('space_new');O('AF','XOR A');O('C9','RET')
L('space_new');V(1);ST('pressed');O('C9','RET')
L('space_release');O('AF','XOR A');ST('pressed');O('C9','RET')

L('new_game')
V(1);ST('state');V(3);ST('lives');V(2);ST('player')
O('AF','XOR A')
for var in ('score','move_cd','spawn_cd','step_cd','beam_cd','hit_cd','rng','tick_n'):ST(var)
V(1);ST('pressed')
O('AF','XOR A');HL('enemies');B(5)
L('clear_enemy');O('77','LD (HL),A');O('23','INC HL');DJ('clear_enemy')
V(255);ST('prev_tamer_lane');O('AF','XOR A');ST('pending_active');ST('just_committed');ST('player_moved_frame');CALL('reset_snapshots');copy_scr('game_scr');HL('game_scr');DE(0x6000);BC(6912);O('EDB0','LDIR');CALL('render_game');O('C9','RET')

L('game_tick')
O('AF','XOR A');ST('player_moved_frame')
CALL('commit_pending')
CALL('keyboard');CALL('update_timers')
LD('state');O('FE01','CP 1');JNZ('main')
CALL('render_game');JP('main')

L('keyboard')
LD('move_cd');O('B7','OR A');JRZ('key_left');O('3D','DEC A');ST('move_cd');JR0('key_fire')
L('key_left');V(0xDF);O('DBFE','IN A,($FE)');O('E602','AND 2');JRNZ('key_right')
LD('player');O('B7','OR A');JRZ('key_fire');O('3D','DEC A');ST('player');V(1);ST('player_moved_frame');V(2);ST('move_cd');JR0('key_fire')
L('key_right');V(0xDF);O('DBFE','IN A,($FE)');O('E601','AND 1');JRNZ('key_fire')
LD('player');O('FE04','CP 4');JRZ('key_fire');O('3C','INC A');ST('player');V(1);ST('player_moved_frame');V(2);ST('move_cd')
L('key_fire');CALL('space_edge');O('B7','OR A');O('C8','RET Z');CALL('fire');O('C9','RET')

L('fire')
LD('player');ST('beam_lane');V(5);ST('beam_cd');CALL('snd_laser')
CALL('enemy_for_player');O('7E','LD A,(HL)');O('B7','OR A');O('C8','RET Z')
O('F5','PUSH AF')
LD('player');ST('hit_lane');O('F1','POP AF')
O('87','ADD A,A');O('C607','ADD A,7');ST('hit_row')
V(2);ST('hit_cd')
CALL('enemy_for_player');O('3600','LD (HL),0')
LD('score');O('3C','INC A');ST('score');CALL('snd_hit');O('C9','RET')
L('enemy_for_player');LD('player');O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('C9','RET')

L('update_timers')
LD('tick_n');O('3C','INC A');O('E601','AND 1');ST('tick_n')
LD('beam_cd');O('B7','OR A');JRZ('hit_timer');O('3D','DEC A');ST('beam_cd')
L('hit_timer');LD('hit_cd');O('B7','OR A');JRZ('spawn_timer');O('3D','DEC A');ST('hit_cd')
# Six non-overlapping difficulty bands, based solely on captured pulpos.
# Score  0-4 : gentle learning phase; 5-9 : warm-up; 10-14 : moderate;
#       15-19: brisk; 20-29: fast; 30+ : fast with a controlled ceiling.
# Intervals are 50 Hz interrupt ticks; a shorter interval means more action.
#                 0..4  5..9  10..14  15..19  20..29  30+
# spawn interval: 68    56     45      38      31    25
# step interval:  55    46     38      32      27    23
L('spawn_timer');LD('spawn_cd');O('3C','INC A');ST('spawn_cd');O('47','LD B,A')
CALL('spawn_interval');O('B8','CP B');JRC('spawn_now');JR0('step_timer')
L('spawn_now');O('AF','XOR A');ST('spawn_cd');CALL('spawn')
L('step_timer');LD('step_cd');O('3C','INC A');ST('step_cd');O('47','LD B,A')
CALL('step_interval');O('B8','CP B');O('D0','RET NC')
O('AF','XOR A');ST('step_cd');CALL('advance');O('C9','RET')

# A = frames between spawn attempts, by current score. Only A is modified;
# compare is done by caller against B (elapsed frame ticks).
L('spawn_interval');LD('score')
O('FE1E','CP 30');JRC('sp_20');V(25);O('C9','RET')
L('sp_20');O('FE14','CP 20');JRC('sp_15');V(31);O('C9','RET')
L('sp_15');O('FE0F','CP 15');JRC('sp_10');V(38);O('C9','RET')
L('sp_10');O('FE0A','CP 10');JRC('sp_5');V(45);O('C9','RET')
L('sp_5');O('FE05','CP 5');JRC('sp_0');V(56);O('C9','RET')
L('sp_0');V(68);O('C9','RET')
L('step_interval');LD('score')
O('FE1E','CP 30');JRC('st_20');V(23);O('C9','RET')
L('st_20');O('FE14','CP 20');JRC('st_15');V(27);O('C9','RET')
L('st_15');O('FE0F','CP 15');JRC('st_10');V(32);O('C9','RET')
L('st_10');O('FE0A','CP 10');JRC('st_5');V(38);O('C9','RET')
L('st_5');O('FE05','CP 5');JRC('st_0');V(46);O('C9','RET')
L('st_0');V(55);O('C9','RET')

L('spawn');O('ED5F','LD A,R');O('47','LD B,A');LD('rng');O('80','ADD A,B');O('C629','ADD A,41');ST('rng');O('E607','AND 7');O('FE05','CP 5');O('D0','RET NC')
O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('7E','LD A,(HL)');O('B7','OR A');O('C0','RET NZ');O('3601','LD (HL),1');O('C9','RET')

L('advance');O('AF','XOR A');ST('escaped_this_tick');B(0)
L('advance_lane');O('C5','PUSH BC');O('78','LD A,B');O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('7E','LD A,(HL)');O('B7','OR A');JRZ('advance_next')
O('3C','INC A');O('FE05','CP 5');JRZ('breakthrough');O('77','LD (HL),A');JR0('advance_next')
L('breakthrough');O('3600','LD (HL),0');V(1);ST('escaped_this_tick')
L('advance_next');O('C1','POP BC');LD('state');O('FE01','CP 1');O('C0','RET NZ');O('04','INC B');O('78','LD A,B');O('FE05','CP 5');JRNZ('advance_lane')
LD('escaped_this_tick');O('B7','OR A');O('C8','RET Z');CALL('damage');O('C9','RET')
L('damage');CALL('snd_damage');LD('lives');O('3D','DEC A');ST('lives');O('C0','RET NZ');V(2);ST('state');CALL('over_screen');O('C9','RET')
L('over_screen');copy_scr('over_scr');CALL('final_score');O('C9','RET')

# ---------------------------------------------------------------
# Dirty-lane renderer (25 fps-equivalent updates only when needed).
# Static image remains untouched. On each frame we inspect a 4-byte
# visual state for each lane; only changed lanes are restored + stamped.
# One lane: 3 columns x 12 character rows, never the whole 48K screen.
# ---------------------------------------------------------------
L('reset_snapshots')
HL('prev_enemy');B(20);V(255)
L('reset_prev_loop');O('77','LD (HL),A');O('23','INC HL');DJ('reset_prev_loop')
V(255);ST('prev_score');ST('prev_lives');O('C9','RET')

L('render_game')
# Keyboard always sampled; on the frame that publishes a pulpo, any newly
# requested player change is retained in RAM and visualized next frame.
# This avoids a frame with both a big enemy copy and two player sprite copies.
LD('just_committed');O('B7','OR A');O('C0','RET NZ')
V(0);ST('tmp_lane');ST('used_units');ST('enemy_updated');V(1);ST('frame_lane_budget')
# Give both positions of the player priority over enemy updates. Otherwise
# the painter can postpone one sprite and show the wrong pose while moving.
LD('prev_tamer_lane');O('FE05','CP 5');JRNC('priority_player_new')
ST('tmp_lane');CALL('render_priority_lane')
L('priority_player_new');LD('player');ST('tmp_lane');CALL('render_priority_lane')
LD('player');ST('prev_tamer_lane')
LD('just_committed');O('B7','OR A');JZ('render_nonprio')
JP('render_finish')
L('render_nonprio');V(0);ST('tmp_lane')
L('render_loop')
CALL('lane_changed');O('B7','OR A');JRZ('render_skip_lane')
CALL('compute_range')
LD('range_end');O('47','LD B,A');LD('range_start');O('B8','CP B');JRNC('render_skip_lane')
LD('pending_active');O('B7','OR A');JRZ('render_can_compose');CALL('undo_snapshot');JR0('render_finish')
L('render_can_compose');CALL('check_render_budget');O('B7','OR A');JRNZ('render_allowed');CALL('undo_snapshot');JR0('render_finish')
L('render_allowed');CALL('restore_lane');CALL('paint_lane');CALL('queue_pending')
LD('frame_lane_budget');O('3D','DEC A');ST('frame_lane_budget');JRZ('render_finish')
L('render_skip_lane');LD('tmp_lane');O('3C','INC A');ST('tmp_lane');O('FE05','CP 5');JRNZ('render_loop')
L('render_finish');CALL('hud_if_changed');O('C9','RET')

# Pending enemy work has already been composed into the offscreen buffer.
# The small 3-byte-wide band is transferred immediately after HALT in the next
# interrupt, BEFORE game logic or further sprite painting. This avoids showing
# an incomplete 24x32 pulpo on the ULA's active display.
L('commit_pending')
O('AF','XOR A');ST('just_committed')
LD('pending_active');O('B7','OR A');O('C8','RET Z')
LD('pending_lane');ST('tmp_lane')
LD('pending_start');ST('range_start')
LD('pending_end');ST('range_end')
CALL('commit_lane')
V(1);ST('just_committed')
O('AF','XOR A');ST('pending_active');O('C9','RET')
L('queue_pending')
LD('tmp_lane');ST('pending_lane')
LD('range_start');ST('pending_start')
LD('range_end');ST('pending_end')
V(1);ST('pending_active');O('C9','RET')


L('render_priority_lane')
CALL('lane_changed');O('B7','OR A');O('C8','RET Z')
LD('old_player');O('47','LD B,A');HL('prev_player');CALL('fetch_prev');O('B8','CP B');JRNZ('priority_player_changed')
CALL('undo_snapshot');O('C9','RET')
L('priority_player_changed')
# Strictly update only the four 8-pixel rows of the domador.
# Any changed enemy, beam or spark in the same lane is restored to its old
# snapshot and processed separately by the queued renderer. Otherwise the
# union range could expand to 12 rows and break the 69888T/frame budget.
LD('old_enemy');HL('prev_enemy');CALL('put_prev')
LD('old_beam');HL('prev_beam');CALL('put_prev')
LD('old_hit');HL('prev_hit');CALL('put_prev')
V(17);ST('range_start');V(21);ST('range_end')
LD('used_units');O('C604','ADD A,4');ST('used_units')
CALL('restore_lane');CALL('paint_player_only');CALL('commit_lane');O('C9','RET')

# Snapshot comparison helper: input A=current value, HL=previous array base.
# Preserve no registers; use tmp_lane (not B) as index.
L('compare_signature')
ST('sig_value');LD('tmp_lane');O('5F','LD E,A');D(0);O('19','ADD HL,DE')
LD('sig_value');O('BE','CP (HL)');O('C8','RET Z')
O('77','LD (HL),A');V(1);ST('dirty');O('C9','RET')


# Never spend more than 8 x (8px-high, 24px-wide) row units after the first
# changed lane. Small player moves (4+4 rows) can update both positions together;
# simultaneous enemy advances (6 rows each) are spread across following frames.
# A large beam redraw is always allowed as the FIRST update of the frame.
L('check_render_budget')
O('AF','XOR A');ST('has_enemy_change')
LD('old_enemy');O('47','LD B,A');HL('prev_enemy');CALL('fetch_prev');O('B8','CP B');JRZ('budget_no_enemy')
V(1);ST('has_enemy_change')
LD('enemy_updated');O('B7','OR A');JRZ('budget_no_enemy')
O('AF','XOR A');O('C9','RET')
L('budget_no_enemy')
LD('range_end');O('47','LD B,A');LD('range_start');O('4F','LD C,A')
O('78','LD A,B');O('91','SUB C');O('47','LD B,A')
LD('used_units');O('B7','OR A');JRZ('budget_allow')
O('80','ADD A,B');O('FE09','CP 9');JRC('budget_store')
O('AF','XOR A');O('C9','RET')
L('budget_allow');O('80','ADD A,B')
L('budget_store');ST('used_units')
LD('has_enemy_change');O('B7','OR A');JRZ('budget_no_mark')
V(1);ST('enemy_updated')
L('budget_no_mark');V(1);O('C9','RET')

L('put_prev')
ST('sig_value');LD('tmp_lane');O('5F','LD E,A');D(0);O('19','ADD HL,DE')
LD('sig_value');O('77','LD (HL),A');O('C9','RET')
L('undo_snapshot')
LD('old_enemy');HL('prev_enemy');CALL('put_prev')
LD('old_player');HL('prev_player');CALL('put_prev')
LD('old_beam');HL('prev_beam');CALL('put_prev')
LD('old_hit');HL('prev_hit');CALL('put_prev')
O('C9','RET')


L('fetch_prev')
LD('tmp_lane');O('5F','LD E,A');D(0);O('19','ADD HL,DE');O('7E','LD A,(HL)');O('C9','RET')
L('capture_old_lanes')
HL('prev_enemy');CALL('fetch_prev');ST('old_enemy')
HL('prev_player');CALL('fetch_prev');ST('old_player')
HL('prev_beam');CALL('fetch_prev');ST('old_beam')
HL('prev_hit');CALL('fetch_prev');ST('old_hit');O('C9','RET')

# Update a minimal range [top,end) of 8-pixel rows. B and C are scratch.
# Offscreen renderer restores just the union of old & new object rectangles.
L('mark_range')
O('47','LD B,A');LD('range_start');O('B8','CP B');JRC('mark_start_done');JRZ('mark_start_done')
O('78','LD A,B');ST('range_start')
L('mark_start_done');LD('range_end');O('B9','CP C');JRNC('mark_end_done')
O('79','LD A,C');ST('range_end')
L('mark_end_done');O('C9','RET')

L('mark_enemy')
O('B7','OR A');O('C8','RET Z');O('FE05','CP 5');O('D0','RET NC')
O('87','ADD A,A');O('C607','ADD A,7');O('47','LD B,A');O('C604','ADD A,4');O('4F','LD C,A');O('78','LD A,B');CALL('mark_range');O('C9','RET')
L('mark_player')
O('B7','OR A');O('C8','RET Z');O('FE03','CP 3');O('D0','RET NC')
V(17);C(21);CALL('mark_range');O('C9','RET')
L('mark_beam')
O('B7','OR A');O('C8','RET Z');O('FE02','CP 2');O('D0','RET NC')
V(9);C(17);CALL('mark_range');O('C9','RET')
L('mark_hit')
O('B7','OR A');O('C8','RET Z');O('FE16','CP 22');O('D0','RET NC')
O('47','LD B,A');O('C604','ADD A,4');O('4F','LD C,A');O('78','LD A,B');CALL('mark_range');O('C9','RET')

L('compute_range')
V(21);ST('range_start');V(9);ST('range_end')
LD('old_enemy');CALL('mark_enemy');HL('prev_enemy');CALL('fetch_prev');CALL('mark_enemy')
LD('old_player');CALL('mark_player');HL('prev_player');CALL('fetch_prev');CALL('mark_player')
LD('old_beam');CALL('mark_beam');HL('prev_beam');CALL('fetch_prev');CALL('mark_beam')
LD('old_hit');CALL('mark_hit');HL('prev_hit');CALL('fetch_prev');CALL('mark_hit')
O('C9','RET')

L('lane_changed')
CALL('capture_old_lanes')
O('AF','XOR A');ST('dirty')
LD('tmp_lane');O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('7E','LD A,(HL)');HL('prev_enemy');CALL('compare_signature')
# Player: 0 absent, 1 idle, 2 firing in this same lane.
LD('player');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('sig_no_player')
LD('beam_cd');O('B7','OR A');JRZ('sig_player_idle')
LD('beam_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRZ('sig_player_fire')
L('sig_player_idle');V(1);JR0('sig_player_ready')
L('sig_player_fire');V(2);JR0('sig_player_ready')
L('sig_no_player');O('AF','XOR A')
L('sig_player_ready');HL('prev_player');CALL('compare_signature')
# Beam: only binary active or inactive; do not redraw for a countdown.
LD('beam_cd');O('B7','OR A');JRZ('sig_no_beam')
LD('beam_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('sig_no_beam')
V(1);JR0('sig_beam_ready')
L('sig_no_beam');O('AF','XOR A')
L('sig_beam_ready');HL('prev_beam');CALL('compare_signature')
# Hit spark: 0 absent; otherwise exact top sprite row.
LD('hit_cd');O('B7','OR A');JRZ('sig_no_hit')
LD('hit_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('sig_no_hit')
LD('hit_row');JR0('sig_hit_ready')
L('sig_no_hit');O('AF','XOR A')
L('sig_hit_ready');HL('prev_hit');CALL('compare_signature')
LD('dirty');O('C9','RET')

# Source bytes always taken from the immutable, native Spectrum 6912B
# background. DE screen pixel address in 0x4000-0x57FF;
# source = game_scr + DE - 0x6000 (same layout for attributes).
L('restore_lane')
LD('tmp_lane');CALL('lane_col');O('79','LD A,C');ST('spr_col')
LD('range_start');ST('restore_row')
L('restore_pixrow')
LD('restore_row');CALL('screen_destination')
HL(('game_scr',-0x6000));O('19','ADD HL,DE');B(8)
L('restore_scanline')
O('C5','PUSH BC');O('E5','PUSH HL');O('D5','PUSH DE')
BC(3);O('EDB0','LDIR')
O('D1','POP DE');O('E1','POP HL');O('24','INC H');O('14','INC D');O('C1','POP BC')
DJ('restore_scanline')
LD('restore_row');O('3C','INC A');ST('restore_row');LD('range_end');O('47','LD B,A');LD('restore_row');O('B8','CP B');JRNZ('restore_pixrow')
# 12 rows of attribute bytes, three cells across (other colors stay fixed).
LD('range_start');ST('restore_row')
L('restore_attrrow')
LD('restore_row');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(5):O('29','ADD HL,HL')
DE(0x7800);O('19','ADD HL,DE')
LD('spr_col');O('5F','LD E,A');D(0);O('19','ADD HL,DE');O('EB','EX DE,HL')
HL(('game_scr',-0x6000));O('19','ADD HL,DE');BC(3);O('EDB0','LDIR')
LD('restore_row');O('3C','INC A');ST('restore_row');LD('range_end');O('47','LD B,A');LD('restore_row');O('B8','CP B');JRNZ('restore_attrrow')
O('C9','RET')

# Copy just the finished lane from offscreen 0x6000 to visible 0x4000.
# This NEVER shows the intermediate erased background (no flicker on redraw).
L('commit_lane')
LD('tmp_lane');CALL('lane_col');O('79','LD A,C');ST('spr_col')
LD('range_start');ST('restore_row')
L('commit_pixrow')
LD('restore_row');CALL('screen_destination');O('EB','EX DE,HL')
O('7C','LD A,H');O('D620','SUB 32');O('57','LD D,A')
O('7D','LD A,L');O('5F','LD E,A');B(8)
L('commit_scanline')
O('C5','PUSH BC');O('E5','PUSH HL');O('D5','PUSH DE')
BC(3);O('EDB0','LDIR')
O('D1','POP DE');O('E1','POP HL');O('24','INC H');O('14','INC D');O('C1','POP BC')
DJ('commit_scanline')
LD('restore_row');O('3C','INC A');ST('restore_row');LD('range_end');O('47','LD B,A');LD('restore_row');O('B8','CP B');JRNZ('commit_pixrow')
LD('range_start');ST('restore_row')
L('commit_attrrow')
LD('restore_row');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(5):O('29','ADD HL,HL')
DE(0x7800);O('19','ADD HL,DE')
LD('spr_col');O('5F','LD E,A');D(0);O('19','ADD HL,DE')
O('7C','LD A,H');O('D620','SUB 32');O('57','LD D,A')
O('7D','LD A,L');O('5F','LD E,A')
BC(3);O('EDB0','LDIR')
LD('restore_row');O('3C','INC A');ST('restore_row');LD('range_end');O('47','LD B,A');LD('restore_row');O('B8','CP B');JRNZ('commit_attrrow')
O('C9','RET')

L('paint_lane')
# Enemy at one of the four Game & Watch steps, alt tentacles by step parity.
LD('tmp_lane');O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('7E','LD A,(HL)');O('B7','OR A');JRZ('paint_no_enemy')
ST('enemy_step');O('87','ADD A,A');O('C607','ADD A,7');O('47','LD B,A')
LD('enemy_step');O('E601','AND 1');JRZ('paint_octo_alt');HL('octo_sprite');JR0('paint_octo_ready')
L('paint_octo_alt');HL('octo_sprite_alt')
L('paint_octo_ready');LD('tmp_lane');CALL('stamp')
L('paint_no_enemy')
LD('beam_cd');O('B7','OR A');JRZ('paint_no_beam')
LD('beam_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('paint_no_beam')
LD('tmp_lane');CALL('draw_beam')
L('paint_no_beam')
LD('hit_cd');O('B7','OR A');JRZ('paint_no_hit')
LD('hit_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('paint_no_hit')
LD('hit_row');O('47','LD B,A');LD('tmp_lane');HL('spark_sprite');CALL('stamp')
L('paint_no_hit')
LD('player');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');O('C0','RET NZ')
LD('beam_cd');O('B7','OR A');JRZ('paint_tamer_idle')
LD('beam_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('paint_tamer_idle')
HL('tamer_fire_sprite');JR0('paint_tamer_ready')
L('paint_tamer_idle');HL('tamer_sprite')
L('paint_tamer_ready');B(17);LD('tmp_lane');CALL('stamp');O('C9','RET')

# Called ONLY by the ringmaster-priority path. Its clipping is exact:
# even if an octopus occupies the lower arena, no pixels above row 17 are
# stamped into hidden memory and allowed to diverge from the live screen.
L('paint_player_only')
LD('tmp_lane');O('5F','LD E,A');D(0);HL('enemies');O('19','ADD HL,DE');O('7E','LD A,(HL)');O('FE04','CP 4');JRNZ('priority_no_octo_bottom')
HL('octo_bottom_alt');B(17);LD('tmp_lane');CALL('stamp_2rows')
L('priority_no_octo_bottom')
LD('hit_cd');O('B7','OR A');JRZ('priority_no_spark_bottom')
LD('hit_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('priority_no_spark_bottom')
LD('hit_row');O('FE0F','CP 15');JRNZ('priority_no_spark_bottom')
HL('spark_bottom');B(17);LD('tmp_lane');CALL('stamp_2rows')
L('priority_no_spark_bottom')
LD('player');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');O('C0','RET NZ')
LD('beam_cd');O('B7','OR A');JRZ('priority_idle')
LD('beam_lane');O('47','LD B,A');LD('tmp_lane');O('B8','CP B');JRNZ('priority_idle')
HL('tamer_fire_sprite');JR0('priority_stamp_tamer')
L('priority_idle');HL('tamer_sprite')
L('priority_stamp_tamer');B(17);LD('tmp_lane');CALL('stamp');O('C9','RET')


L('hud_if_changed')
LD('used_units');O('B7','OR A');O('C0','RET NZ')
LD('just_committed');O('B7','OR A');O('C0','RET NZ')
LD('player_moved_frame');O('B7','OR A');O('C0','RET NZ')
LD('pending_active');O('B7','OR A');O('C0','RET NZ')
O('AF','XOR A');ST('hud_dirty')
LD('score');O('47','LD B,A');LD('prev_score');O('B8','CP B');JRZ('hud_check_lives')
LD('score');ST('prev_score');CALL('hud_score')
V(1);ST('hud_dirty')
L('hud_check_lives')
LD('lives');O('47','LD B,A');LD('prev_lives');O('B8','CP B');JRZ('hud_commit_if_dirty')
LD('lives');ST('prev_lives');CALL('hud_lives')
V(1);ST('hud_dirty')
L('hud_commit_if_dirty')
LD('hud_dirty');O('B7','OR A');O('C8','RET Z')
CALL('commit_hud');O('C9','RET')

# Commit the two HUD rows only on score or life changes.
L('commit_hud')
V(0);ST('spr_col');V(22);ST('restore_row')
L('commit_hud_pixrow')
LD('restore_row');CALL('screen_destination');O('EB','EX DE,HL')
O('7C','LD A,H');O('D620','SUB 32');O('57','LD D,A')
O('7D','LD A,L');O('5F','LD E,A');B(8)
L('commit_hud_scan')
O('C5','PUSH BC');O('E5','PUSH HL');O('D5','PUSH DE');BC(32);O('EDB0','LDIR')
O('D1','POP DE');O('E1','POP HL');O('24','INC H');O('14','INC D');O('C1','POP BC')
DJ('commit_hud_scan')
LD('restore_row');O('3C','INC A');ST('restore_row');O('FE18','CP 24');JRNZ('commit_hud_pixrow')
HL(0x7AC0);DE(0x5AC0);BC(64);O('EDB0','LDIR');O('C9','RET')

L('lane_col');O('87','ADD A,A');O('4F','LD C,A');O('87','ADD A,A');O('81','ADD A,C');O('C602','ADD A,2');O('4F','LD C,A');O('C9','RET')

L('stamp')
O('F5','PUSH AF');V(4);ST('spr_total');O('F1','POP AF');JR0('stamp_setup')
L('stamp_2rows');O('F5','PUSH AF');V(2);ST('spr_total');O('F1','POP AF')
L('stamp_setup')
O('F5','PUSH AF');O('78','LD A,B');ST('spr_start_row');ST('spr_row');O('F1','POP AF')
CALL('lane_col');O('79','LD A,C');ST('spr_col');LD('spr_total');ST('spr_count')
L('stamp_bitrow')
O('E5','PUSH HL');LD('spr_row');CALL('screen_destination');O('E1','POP HL')
B(8)
L('stamp_scanline')
O('C5','PUSH BC');BC(3);O('EDB0','LDIR');O('C1','POP BC')
O('14','INC D');O('7B','LD A,E');O('D603','SUB 3');O('5F','LD E,A')
DJ('stamp_scanline')
LD('spr_row');O('3C','INC A');ST('spr_row')
LD('spr_count');O('3D','DEC A');ST('spr_count');JRNZ('stamp_bitrow')
LD('spr_start_row');ST('spr_row');LD('spr_total');ST('spr_count')
L('stamp_attrrow')
O('E5','PUSH HL')
LD('spr_row');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(5):O('29','ADD HL,HL')
DE(0x7800);O('19','ADD HL,DE')
LD('spr_col');O('5F','LD E,A');D(0);O('19','ADD HL,DE');O('EB','EX DE,HL');O('E1','POP HL')
BC(3);O('EDB0','LDIR')
LD('spr_row');O('3C','INC A');ST('spr_row')
LD('spr_count');O('3D','DEC A');ST('spr_count');JRNZ('stamp_attrrow')
O('C9','RET')

# Return DE = exact Spectrum scanline start for character row A + spr_col.
L('screen_destination')
O('87','ADD A,A');O('5F','LD E,A');D(0);HL('scr_rows');O('19','ADD HL,DE')
O('5E','LD E,(HL)');O('23','INC HL');O('56','LD D,(HL)')
LD('spr_col');O('83','ADD A,E');O('5F','LD E,A');JRNC('screen_dest_ok');O('14','INC D')
L('screen_dest_ok');O('7A','LD A,D');O('C620','ADD A,32');O('57','LD D,A');O('C9','RET')

# narrow two-pixel beam, no persistent drawing: reconstructed each pass.
L('draw_beam');CALL('lane_col');O('0C','INC C');O('0C','INC C')
V(0x46);ST('ink');B(9)
L('beam_loop');V(132);CALL('tile');O('04','INC B');O('78','LD A,B');O('FE11','CP 17');JRNZ('beam_loop');O('C9','RET')

# Large, arcade-style score and 16x16 hearts.
# Screen tile rows 22 and 23 only; all animation stays above row 21.
L('hud')
CALL('hud_score');CALL('hud_lives');O('C9','RET')
L('hud_score')
V(0x4F);ST('ink');B(22);C(10);CALL('print_score_big');O('C9','RET')
L('hud_lives')
D(0)
L('hud_life')
LD('lives');O('BA','CP D');JRC('hud_dead');JRZ('hud_dead')
V(173);V(0x4A);ST('ink');V(173);JR0('hud_life_glyph')
L('hud_dead');V(0x41);ST('ink');V(177)
L('hud_life_glyph')
O('F5','PUSH AF')
O('7A','LD A,D');O('87','ADD A,A');O('C619','ADD A,25');O('4F','LD C,A');B(22)
O('F1','POP AF');CALL('draw_2x2')
O('14','INC D');O('7A','LD A,D');O('FE03','CP 3');JRNZ('hud_life')
O('C9','RET')

# Render 16x16 glyph A with four consecutive 8x8 tiles at B,C.
# Preserves BC and DE, so the multi-digit counter is never corrupted.
L('draw_2x2')
O('C5','PUSH BC')
O('F5','PUSH AF');CALL('tile');O('F1','POP AF')
O('F5','PUSH AF');O('C5','PUSH BC');O('3C','INC A');O('0C','INC C');CALL('tile');O('C1','POP BC');O('F1','POP AF')
O('F5','PUSH AF');O('C5','PUSH BC');O('C602','ADD A,2');O('04','INC B');CALL('tile');O('C1','POP BC');O('F1','POP AF')
O('C603','ADD A,3');O('04','INC B');O('0C','INC C');CALL('tile')
O('C1','POP BC');O('C9','RET')

# A=decimal digit -> first of four 8x8 custom glyphs (base 133).
L('big_digit')
O('87','ADD A,A');O('87','ADD A,A');O('C685','ADD A,133');CALL('draw_2x2');O('C9','RET')
L('print_score_big')
LD('score');D(0)
L('big_score_100');O('FE64','CP 100');JRC('big_score_10begin');O('D664','SUB 100');O('14','INC D');JR0('big_score_100')
L('big_score_10begin');ST('score_remainder');O('7A','LD A,D');CALL('big_digit');O('0C','INC C');O('0C','INC C')
LD('score_remainder');D(0)
L('big_score_10');O('FE0A','CP 10');JRC('big_score_units');O('D60A','SUB 10');O('14','INC D');JR0('big_score_10')
L('big_score_units');ST('score_remainder');O('7A','LD A,D');CALL('big_digit');O('0C','INC C');O('0C','INC C')
LD('score_remainder');CALL('big_digit');O('C9','RET')

L('final_score');V(0x4E);ST('ink');B(18);C(19);CALL('print_score');O('C9','RET')

# B=char row; C=first column; score is an 8-bit count, displayed as 3 decimal digits
L('print_score');LD('score');D(0)
L('score_100');O('FE64','CP 100');JRC('score_10begin');O('D664','SUB 100');O('14','INC D');JR0('score_100')
L('score_10begin');ST('score_remainder');O('7A','LD A,D');O('C630','ADD A,48');CALL('tile');O('0C','INC C')
LD('score_remainder');D(0)
L('score_10');O('FE0A','CP 10');JRC('score_units');O('D60A','SUB 10');O('14','INC D');JR0('score_10')
L('score_units');ST('score_remainder');O('7A','LD A,D');O('C630','ADD A,48');CALL('tile');O('0C','INC C')
LD('score_remainder');O('C630','ADD A,48');CALL('tile');O('C9','RET')

# Draw one 8x8 ROM glyph or one of the custom HUD glyphs.
# A=char, B=screen character row, C=column. Preserves AF BC DE HL.
L('tile');O('F5','PUSH AF');O('C5','PUSH BC');O('D5','PUSH DE');O('E5','PUSH HL')
ST('ch_tmp');O('78','LD A,B');ST('row_tmp');O('79','LD A,C');ST('col_tmp')
O('78','LD A,B');O('87','ADD A,A');O('5F','LD E,A');D(0);HL('scr_rows');O('19','ADD HL,DE')
O('5E','LD E,(HL)');O('23','INC HL');O('56','LD D,(HL)');O('79','LD A,C');O('83','ADD A,E');O('5F','LD E,A');JRNC('tile_dest_ok');O('14','INC D')
L('tile_dest_ok');LD('state');O('FE01','CP 1');JRNZ('tile_dest_visible');O('7A','LD A,D');O('C620','ADD A,32');O('57','LD D,A')
L('tile_dest_visible');W('ED53','tile_dest','LD (tile_dest),DE')
LD('ch_tmp');O('FE80','CP 128');JRC('tile_rom')
O('D680','SUB 128');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(3):O('29','ADD HL,HL')
DE('custom_font');O('19','ADD HL,DE');JR0('tile_src_ok')
L('tile_rom');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(3):O('29','ADD HL,HL')
DE(0x3C00);O('19','ADD HL,DE')
L('tile_src_ok');W('ED5B','tile_dest','LD DE,(tile_dest)');B(8)
L('tile_8scan');O('7E','LD A,(HL)');O('12','LD (DE),A');O('23','INC HL');O('14','INC D');DJ('tile_8scan')
LD('row_tmp');O('6F','LD L,A');O('2600','LD H,0')
for _ in range(5):O('29','ADD HL,HL')
DE(0x5800);O('19','ADD HL,DE');LD('state');O('FE01','CP 1');JRNZ('tile_attr_visible');DE(0x2000);O('19','ADD HL,DE')
L('tile_attr_visible');LD('col_tmp');O('5F','LD E,A');D(0);O('19','ADD HL,DE');LD('ink');O('77','LD (HL),A')
O('E1','POP HL');O('D1','POP DE');O('C1','POP BC');O('F1','POP AF');O('C9','RET')

# Original Spectrum 48K beeper routines
L('tone');L('tone_pulse');V(0x10);O('D3FE','OUT ($FE),A');O('59','LD E,C')
L('tone_high');O('1D','DEC E');JRNZ('tone_high');O('AF','XOR A');O('D3FE','OUT ($FE),A');O('59','LD E,C')
L('tone_low');O('1D','DEC E');JRNZ('tone_low');DJ('tone_pulse');O('C9','RET')
L('beep_intro');B(24);C(29);CALL('tone');B(22);C(17);CALL('tone');O('C9','RET')
L('snd_laser');B(15);C(9);CALL('tone');B(18);C(5);CALL('tone');O('C9','RET')
L('snd_hit');B(18);C(16);CALL('tone');B(30);C(7);CALL('tone');O('C9','RET')
L('snd_damage');B(16);C(26);CALL('tone');B(14);C(42);CALL('tone');O('C9','RET')

# All data is located in the same machine-code block, 32768 onwards.
# The screens are native ZX 48K memory images with 6144 pixel bytes + 768 attributes.
a.Data(art.SPRITES['tamer'],'tamer_sprite')
a.Data(art.SPRITES['tamer_fire'],'tamer_fire_sprite')
a.Data(art.SPRITES['octopus'],'octo_sprite')
a.Data(art.SPRITES['octopus_alt'],'octo_sprite_alt')
a.Data(art.SPRITES['spark'],'spark_sprite')
a.Data(art.SPRITES['octopus_alt'][48:96]+art.SPRITES['octopus_alt'][102:108],'octo_bottom_alt')
a.Data(art.SPRITES['spark'][48:96]+art.SPRITES['spark'][102:108],'spark_bottom')
CUSTOM=[
 [0,0x66,0xff,0xff,0x7e,0x3c,0x18,0],
 [0,0,0,0,0,0,0,0],
 [0x7e,0xff,0xdb,0xdb,0xdb,0xdb,0xff,0x7e],
 [0x7e,0x81,0x81,0x81,0x81,0x81,0x81,0x7e],
 [0x18,0x18,0x18,0x3c,0x18,0x18,0x18,0x18]
]
# 16x16 seven-segment digits. The bold 1985 instrument face is stored as
# actual Z80 glyph bytes, not generated by a runtime BASIC printer.
from PIL import Image, ImageDraw
DIGIT_SEGMENTS={0:'abcdef',1:'bc',2:'abdeg',3:'abcdg',4:'bcfg',5:'acdfg',6:'acdefg',7:'abc',8:'abcdefg',9:'abcdfg'}
SEG_COORDS={
 'a':(4,1,11,2),'b':(12,3,14,7),'c':(12,9,14,13),
 'd':(4,14,11,15),'e':(1,9,3,13),'f':(1,3,3,7),'g':(4,8,11,9)}
def quad_tiles(drawable):
 # 2x2 tiles: top-left, top-right, bottom-left, bottom-right.
 return [[sum((1<<(7-x)) for x in range(8) if drawable.getpixel((qx+x,qy+y))) for y in range(8)]
         for qy,qx in ((0,0),(0,8),(8,0),(8,8))]
for digit in range(10):
 pic=Image.new('1',(16,16),0);brush=ImageDraw.Draw(pic)
 for segment in DIGIT_SEGMENTS[digit]:brush.rectangle(SEG_COORDS[segment],fill=1)
 CUSTOM.extend(quad_tiles(pic))
# large hearts, bright red when alive, thin outline when absent.
for filled in (True,False):
 pic=Image.new('1',(16,16),0);brush=ImageDraw.Draw(pic)
 heart=[(2,4),(4,2),(6,2),(8,5),(10,2),(12,2),(14,4),(14,7),(8,14),(2,7)]
 brush.polygon(heart,fill=1 if filled else 0,outline=1)
 if not filled:
  brush.line(heart+[heart[0]],fill=1,width=1)
 CUSTOM.extend(quad_tiles(pic))
a.Data(bytes(sum(CUSTOM,[])),'custom_font')
L('scr_rows')
for row in range(24):a.DW(0x4000+((row&24)<<8)+((row&7)<<5))
for v in ('state','pressed','player','lives','score','move_cd','spawn_cd','step_cd','beam_cd','beam_lane','hit_cd','hit_lane','hit_row','rng','tick_n','tmp_lane','dirty','sig_value','restore_row','enemy_step','prev_tamer_lane','prev_score','prev_lives','old_enemy','old_player','old_beam','old_hit','range_start','range_end','frame_lane_budget','used_units','has_enemy_change','enemy_updated','spr_start_row','spr_row','spr_col','spr_count','spr_total','score_remainder','ch_tmp','row_tmp','col_tmp','ink'):
 a.Data(b'\0',v)
for v in ('pending_active','pending_lane','pending_start','pending_end','just_committed','hud_dirty','player_moved_frame','escaped_this_tick'):a.Data(b'\0',v)
a.Data(b'\0\0','tile_dest')
a.Data(b'\0'*5,'enemies')
a.Data(b'\0'*5,'prev_enemy')
a.Data(b'\0'*5,'prev_player')
a.Data(b'\0'*5,'prev_beam')
a.Data(b'\0'*5,'prev_hit')
a.Data(art.SCREENS['title'],'title_scr')
a.Data(art.SCREENS['game'],'game_scr')
a.Data(art.SCREENS['over'],'over_scr')
code=a.resolve()
assert len(code)<0x7F00,(len(code),hex(a.pc()))
assert a.pc()<0xFF00,hex(a.pc())
(P/'CIRCO_NAVIDAD85_V10.bin').write_bytes(code)
(P/'CIRCO_NAVIDAD85_V10.asm').write_text('    ORG $8000\n'+'\n'.join(a.lines)+'\n    END\n',encoding='ascii')

# BASIC 10 CLEAR VAL "32767": LOAD "" SCREEN$: LOAD "" CODE:
#          RANDOMIZE USR VAL "32768"
# First the full-color 6912-byte title/loading illustration, then the compiled Z80.
line=(bytes([0xFD,32,0xB0,32,34])+b'32767'+bytes([34,58,0xEF,32,34,34,32,0xAA,58,
 0xEF,32,34,34,32,0xAF,58,0xF9,32,0xC0,32,0xB0,32,34])+b'32768'+bytes([34,13]))
basic=struct.pack('>H',10)+struct.pack('<H',len(line))+line

def block(flag,payload):
 payload=bytes([flag])+payload
 x=0
 for c in payload:x^=c
 payload+=bytes([x]);return struct.pack('<H',len(payload))+payload

def header(t,name,n,p1,p2):return bytes([t])+name.encode('ascii').ljust(10,b' ')+struct.pack('<HHH',n,p1,p2)
tap=(block(0,header(0,'CIRCO V10',len(basic),10,len(basic)))+block(255,basic)+
 block(0,header(3,'CARATULA',6912,0x4000,0x4000))+block(255,art.SCREENS['title'])+
 block(0,header(3,'CIRCO Z80',len(code),0x8000,0x8000))+block(255,code))
(P/'CIRCO_DIMENSIONAL_NAVIDAD85_V10.tap').write_bytes(tap)
print('CODE',len(code),'end',hex(a.pc()),'TAP',len(tap),'labels',len(a.lab))
