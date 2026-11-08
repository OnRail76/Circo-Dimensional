from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
s=s.replace("O('AF','XOR A');ST('pending_active');CALL('reset_snapshots')", "O('AF','XOR A');ST('pending_active');ST('just_committed');CALL('reset_snapshots')")
# Defer the next enemy compositing by one frame after pending commit.
s=s.replace("LD('player');ST('prev_tamer_lane')\nV(0);ST('tmp_lane')", "LD('player');ST('prev_tamer_lane')\nLD('just_committed');O('B7','OR A');JZ('render_nonprio')\nJP('render_finish')\nL('render_nonprio');V(0);ST('tmp_lane')")
s=s.replace("L('commit_pending')\nLD('pending_active')", "L('commit_pending')\nO('AF','XOR A');ST('just_committed')\nLD('pending_active')")
s=s.replace("CALL('commit_lane')\nO('AF','XOR A');ST('pending_active')", "CALL('commit_lane')\nV(1);ST('just_committed')\nO('AF','XOR A');ST('pending_active')")
# Split scoreboard drawing so scoring doesn't repaint hearts every attack.
start=s.index("L('hud_if_changed')\n")
end=s.index("# Commit the two HUD rows only on score or life changes.",start)
s=s[:start]+"""L('hud_if_changed')
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

"""+s[end:]
start=s.index("L('hud')\n")
end=s.index("L('hud_life')",start)
s=s[:start]+"""L('hud')
CALL('hud_score');CALL('hud_lives');O('C9','RET')
L('hud_score')
V(0x4F);ST('ink');B(22);C(10);CALL('print_score_big');O('C9','RET')
L('hud_lives')
D(0)
"""+s[end:]
s=s.replace("for v in ('pending_active','pending_lane','pending_start','pending_end'):a.Data", "for v in ('pending_active','pending_lane','pending_start','pending_end','just_committed','hud_dirty'):a.Data")
f.write_text(s)

# More legible, separated heart silhouettes.
f=p/'build.py';s=f.read_text();s=s.replace("heart=[(1,4),(3,2),(6,2),(8,4),(10,2),(13,2),(15,4),(15,8),(8,15),(1,8)]", "heart=[(2,4),(4,2),(6,2),(8,5),(10,2),(12,2),(14,4),(14,7),(8,14),(2,7)]")
f.write_text(s)
print('Hardened enemy presentation and independent scoreboard updates')
