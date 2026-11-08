from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
old="CALL('restore_lane');CALL('paint_lane');CALL('commit_lane');O('C9','RET')\n\n# Snapshot comparison helper"
new="CALL('restore_lane');CALL('paint_player_only');CALL('commit_lane');O('C9','RET')\n\n# Snapshot comparison helper"
assert old in s;s=s.replace(old,new)
# New strictly-clipped priority painter; nothing outside rows 17..20 is touched.
pos=s.index("L('hud_if_changed')")
add="""# Called ONLY by the ringmaster-priority path. Its clipping is exact:
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

"""
s=s[:pos]+add+s[pos:]
# Stamp2 is a native 24x16 sprite with pixels + attrs of its own; the same
# engine supports arbitrary 2/4 rows without writing extra bytes.
pos=s.index("L('stamp')\n")
stop=s.index("# Return DE = exact Spectrum scanline",pos)
region=s[pos:stop]
assert region.count("V(4);ST('spr_count')")==2,region.count("V(4);ST('spr_count')")
region=region.replace("L('stamp')\n", "L('stamp')\nV(4);ST('spr_total');JR0('stamp_setup')\nL('stamp_2rows');V(2);ST('spr_total')\nL('stamp_setup')\n",1)
region=region.replace("V(4);ST('spr_count')", "LD('spr_total');ST('spr_count')")
s=s[:pos]+region+s[stop:]
# Data: last two character-rows of 24x32 sprites, with exact attribute bytes.
needle="a.Data(art.SPRITES['spark'],'spark_sprite')"
assert needle in s
s=s.replace(needle,needle+"\n"+"a.Data(art.SPRITES['octopus_alt'][48:96]+art.SPRITES['octopus_alt'][102:108],'octo_bottom_alt')\na.Data(art.SPRITES['spark'][48:96]+art.SPRITES['spark'][102:108],'spark_bottom')")
s=s.replace("'spr_col','spr_count','score_remainder'", "'spr_col','spr_count','spr_total','score_remainder'")
f.write_text(s)
print('Clip-priority painter installed: non-player pixels are never touched outside the 17..20 row range.')
