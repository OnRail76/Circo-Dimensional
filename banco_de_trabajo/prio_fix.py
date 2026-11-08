from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
start=s.index("L('priority_player_changed')\n")
end=s.index("# Snapshot comparison helper",start)
new="""L('priority_player_changed')
# Strictly update only the four 8-pixel rows of the domador.
# Any changed enemy, beam or spark in the same lane is restored to its old
# snapshot and processed separately by the queued renderer. Otherwise the
# union range could expand to 12 rows and break the 69888T/frame budget.
LD('old_enemy');HL('prev_enemy');CALL('put_prev')
LD('old_beam');HL('prev_beam');CALL('put_prev')
LD('old_hit');HL('prev_hit');CALL('put_prev')
V(17);ST('range_start');V(21);ST('range_end')
LD('used_units');O('C604','ADD A,4');ST('used_units')
CALL('restore_lane');CALL('paint_lane');CALL('commit_lane');O('C9','RET')

"""
s=s[:start]+new+s[end:]
# The score can be committed in an idle frame; never combine a 16px HUD
# refresh with any other dirty lane transfer.
s=s.replace("L('hud_if_changed')\nLD('just_committed')", "L('hud_if_changed')\nLD('used_units');O('B7','OR A');O('C0','RET NZ')\nLD('just_committed')")
# Slightly lengthen the beam to survive one deferred display frame.
s=s.replace("LD('player');ST('beam_lane');V(3);ST('beam_cd')", "LD('player');ST('beam_lane');V(5);ST('beam_cd')")
f.write_text(s)
print('Domador draw range decoupled from pulpos/beam; HUD deferred on sprite-heavy frames')
