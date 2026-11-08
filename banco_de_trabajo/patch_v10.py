from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
# Replace the identifiers for a new, independent package.
s=s.replace('V9','V10').replace('v9','v10')
# One pending enemy lane, composed in hidden RAM, published just after the next HALT.
s=s.replace("L('game_tick')\nCALL('keyboard');CALL('update_timers')", "L('game_tick')\nCALL('commit_pending');CALL('keyboard');CALL('update_timers')")
s=s.replace("V(255);ST('prev_tamer_lane');CALL('reset_snapshots');copy_scr('game_scr')", "V(255);ST('prev_tamer_lane');O('AF','XOR A');ST('pending_active');CALL('reset_snapshots');copy_scr('game_scr')")
# Do not commit an enemy update partway through a visible frame.
s=s.replace("L('render_allowed');CALL('restore_lane');CALL('paint_lane');CALL('commit_lane')", "L('render_allowed');CALL('restore_lane');CALL('paint_lane');CALL('queue_pending')")
# To prevent shadow from being dirtied twice while pending, one enemy lane only per round.
s=s.replace("V(2);ST('frame_lane_budget')", "V(1);ST('frame_lane_budget')")
# Insert pending transport routine, which makes copy work immediately after HALT.
idx=s.index("L('render_priority_lane')")
transport="""# Pending enemy work has already been composed into the offscreen buffer.
# The small 3-byte-wide band is transferred immediately after HALT in the next
# interrupt, BEFORE game logic or further sprite painting. This avoids showing
# an incomplete 24x32 pulpo on the ULA's active display.
L('commit_pending')
LD('pending_active');O('B7','OR A');O('C8','RET Z')
LD('pending_lane');ST('tmp_lane')
LD('pending_start');ST('range_start')
LD('pending_end');ST('range_end')
CALL('commit_lane')
O('AF','XOR A');ST('pending_active');O('C9','RET')
L('queue_pending')
LD('tmp_lane');ST('pending_lane')
LD('range_start');ST('pending_start')
LD('range_end');ST('pending_end')
V(1);ST('pending_active');O('C9','RET')

"""
s=s[:idx]+transport+s[idx:]
# If there is already one enemy lane waiting to be published, don't compose
# another yet. Keep the changed snapshot by restoring the old values.
needle="L('render_loop')\nCALL('lane_changed')"
replace="L('render_loop')\nCALL('lane_changed')"
assert needle in s
# Before preparing another non-player lane, check pending, with rollback.
s=s.replace("CALL('compute_range')\nLD('range_end');O('47','LD B,A');LD('range_start');O('B8','CP B');JRNC('render_skip_lane')\nCALL('check_render_budget')", "CALL('compute_range')\nLD('range_end');O('47','LD B,A');LD('range_start');O('B8','CP B');JRNC('render_skip_lane')\nLD('pending_active');O('B7','OR A');JRZ('render_can_compose');CALL('undo_snapshot');JR0('render_finish')\nL('render_can_compose');CALL('check_render_budget')")
# Existing priority_player_old/new may paint a lane when pending just queued
# earlier in frame? They are before queue, so fine.
# New dynamic, larger HUD. Retain old print_score on game-over screen.
start=s.index("L('hud')\n")
end=s.index("L('final_score')",start)
hud="""# Large, arcade-style score and 16x16 hearts.
# Screen tile rows 22 and 23 only; all animation stays above row 21.
L('hud')
V(0x4F);ST('ink');B(22);C(10);CALL('print_score_big')
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

"""
s=s[:start]+hud+s[end:]
# Dynamic digits require 16x16 glyphs in 4 quadrants each, hearts 16x16 too.
# Existing custom font initially has five glyphs (128..132). New digits start at 133.
needle="a.Data(bytes(sum(CUSTOM,[])),'custom_font')"
assert needle in s
s=s.replace(needle,"""# 16x16 seven-segment digits. The bold 1985 instrument face is stored as
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
 heart=[(1,4),(3,2),(6,2),(8,4),(10,2),(13,2),(15,4),(15,8),(8,15),(1,8)]
 brush.polygon(heart,fill=1 if filled else 0,outline=1)
 if not filled:
  brush.line(heart+[heart[0]],fill=1,width=1)
 CUSTOM.extend(quad_tiles(pic))
a.Data(bytes(sum(CUSTOM,[])),'custom_font')""")
# Note glyph indices: 128-132 existing, digits 133..172, hearts 173..180.
# Pending variables.
needle="a.Data(b'\\0\\0','tile_dest')"
assert needle in s
s=s.replace(needle,"for v in ('pending_active','pending_lane','pending_start','pending_end'):a.Data(b'\\0',v)\n"+needle)
f.write_text(s)

# Art: a single elegant 2-box panel from y174 to191 with room for 16px numerals.
f=p/'art.py';s=f.read_text()
start=s.index('def stage(d):')
end=s.index('\ndef game_screen():',start)
s=s[:start]+'''def stage(d):
 # Lower ring: preserve the action plane and the domador's last sprite row.
 d.line((11,169,244,169),fill=14,width=2)
 d.line((12,172,244,172),fill=10,width=2)
 # Two framed, double-outline panels: white numerals + red heart icons.
 d.rectangle((0,175,255,191),fill=1)
 d.line((0,175,255,175),fill=14,width=1)
 d.line((0,191,255,191),fill=14,width=1)
 for xa,xb in ((4,148),(152,251)):
  d.rectangle((xa,175,xb,190),outline=14,width=1)
  d.line((xa+2,177,xa+2,188),fill=10)
  d.line((xb-2,177,xb-2,188),fill=10)
 # Separating stars are decorative but remain OUTSIDE the dynamic 16px glyphs.
 d.point((150,177),fill=15)
 d.point((150,189),fill=15)

''' +s[end:]
s=s.replace("txt(d,(12,178),'PUNTOS',14,10)\n txt(d,(168,178),'VIDAS',14,10)", "txt(d,(13,178),'PUNTOS',15,10)\n txt(d,(159,178),'VIDAS',15,10)")
f.write_text(s)
print('Patched V10 dynamic HUD + queued enemy compositing')
