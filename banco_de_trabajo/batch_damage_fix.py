from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
s=s.replace("L('advance');B(0)", "L('advance');O('AF','XOR A');ST('escaped_this_tick');B(0)")
s=s.replace("L('breakthrough');O('3600','LD (HL),0');CALL('damage')", "L('breakthrough');O('3600','LD (HL),0');V(1);ST('escaped_this_tick')")
needle="O('FE05','CP 5');JRNZ('advance_lane');O('C9','RET')\nL('damage')"
repl="O('FE05','CP 5');JRNZ('advance_lane')\nLD('escaped_this_tick');O('B7','OR A');O('C8','RET Z');CALL('damage');O('C9','RET')\nL('damage')"
assert needle in s;s=s.replace(needle,repl)
s=s.replace("L('snd_damage');B(38);C(39);CALL('tone');B(39);C(55);CALL('tone')", "L('snd_damage');B(16);C(26);CALL('tone');B(14);C(42);CALL('tone')")
s=s.replace("'just_committed','hud_dirty','player_moved_frame'):a.Data", "'just_committed','hud_dirty','player_moved_frame','escaped_this_tick'):a.Data")
f.write_text(s)
print('Updated missed-octopus handling to at most one life per simultaneous breach; shorter sound')
