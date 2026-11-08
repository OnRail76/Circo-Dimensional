from pathlib import Path
p=Path(__file__).parent
f=p/'build.py';s=f.read_text()
# Synchronize the deferred enemy transfer with a light frame; input will be
# polled on the next 20 ms tick when this frame must publish a pulpo.
old="L('game_tick')\nCALL('commit_pending');CALL('keyboard');CALL('update_timers')\nLD('state')"
new="""L('game_tick')
O('AF','XOR A');ST('player_moved_frame')
CALL('commit_pending')
LD('just_committed');O('B7','OR A');JRNZ('game_skip_keyboard')
CALL('keyboard')
L('game_skip_keyboard');CALL('update_timers')
LD('state')"""
assert old in s;s=s.replace(old,new)
s=s.replace("ST('player');V(2);ST('move_cd')", "ST('player');V(1);ST('player_moved_frame');V(2);ST('move_cd')")
# Enemy animations in the same stationary lane as the ringmaster must also
# use the queued path. Priority only for a real player sprite pose/position change.
needle="""L('render_priority_lane')
CALL('lane_changed');O('B7','OR A');O('C8','RET Z')
CALL('compute_range')"""
repl="""L('render_priority_lane')
CALL('lane_changed');O('B7','OR A');O('C8','RET Z')
LD('old_player');O('47','LD B,A');HL('prev_player');CALL('fetch_prev');O('B8','CP B');JRNZ('priority_player_changed')
CALL('undo_snapshot');O('C9','RET')
L('priority_player_changed')
CALL('compute_range')"""
assert needle in s;s=s.replace(needle,repl)
# Skip HUD work during an expensive sprite commit, when player moved or while
# an enemy update has been prepared. One-frame delayed HUD is preferable to tearing.
needle="L('hud_if_changed')\nO('AF','XOR A');ST('hud_dirty')"
repl="""L('hud_if_changed')
LD('just_committed');O('B7','OR A');O('C0','RET NZ')
LD('player_moved_frame');O('B7','OR A');O('C0','RET NZ')
LD('pending_active');O('B7','OR A');O('C0','RET NZ')
O('AF','XOR A');ST('hud_dirty')"""
assert needle in s;s=s.replace(needle,repl)
# Also reset this after starting game, and allocate RAM byte.
s=s.replace("O('AF','XOR A');ST('pending_active');ST('just_committed');CALL('reset_snapshots')", "O('AF','XOR A');ST('pending_active');ST('just_committed');ST('player_moved_frame');CALL('reset_snapshots')")
s=s.replace("'just_committed','hud_dirty'):a.Data", "'just_committed','hud_dirty','player_moved_frame'):a.Data")
f.write_text(s)
print('Applied low-latency visual scheduling for V10')
