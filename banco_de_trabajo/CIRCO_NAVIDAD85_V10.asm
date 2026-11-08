    ORG $8000
start:
    DI
    LD SP,$FF00
    IM 1
    EI
    LD A,0
    OUT ($FE),A
    CALL menu
main:
    HALT
    LD A,(state)
    OR A
    JP Z,menu_tick
    CP 1
    JP Z,game_tick
    JP over_tick
menu:
    XOR A
    LD (state),A
    LD (pressed),A
    LD HL,title_scr
    LD DE,16384
    LD BC,6912
    LDIR
    CALL beep_intro
    RET
menu_tick:
    CALL space_edge
    OR A
    JP Z,main
    CALL new_game
    JP main
over_tick:
    CALL space_edge
    OR A
    JP Z,main
    CALL menu
    LD A,1
    LD (pressed),A
    JP main
space_edge:
    LD A,127
    IN A,($FE)
    AND 1
    JR NZ,space_release
    LD A,(pressed)
    OR A
    JR Z,space_new
    XOR A
    RET
space_new:
    LD A,1
    LD (pressed),A
    RET
space_release:
    XOR A
    LD (pressed),A
    RET
new_game:
    LD A,1
    LD (state),A
    LD A,3
    LD (lives),A
    LD A,2
    LD (player),A
    XOR A
    LD (score),A
    LD (move_cd),A
    LD (spawn_cd),A
    LD (step_cd),A
    LD (beam_cd),A
    LD (hit_cd),A
    LD (rng),A
    LD (tick_n),A
    LD A,1
    LD (pressed),A
    XOR A
    LD HL,enemies
    LD B,5
clear_enemy:
    LD (HL),A
    INC HL
    DJNZ clear_enemy
    LD A,255
    LD (prev_tamer_lane),A
    XOR A
    LD (pending_active),A
    LD (just_committed),A
    LD (player_moved_frame),A
    CALL reset_snapshots
    LD HL,game_scr
    LD DE,16384
    LD BC,6912
    LDIR
    LD HL,game_scr
    LD DE,24576
    LD BC,6912
    LDIR
    CALL render_game
    RET
game_tick:
    XOR A
    LD (player_moved_frame),A
    CALL commit_pending
    CALL keyboard
    CALL update_timers
    LD A,(state)
    CP 1
    JP NZ,main
    CALL render_game
    JP main
keyboard:
    LD A,(move_cd)
    OR A
    JR Z,key_left
    DEC A
    LD (move_cd),A
    JR key_fire
key_left:
    LD A,223
    IN A,($FE)
    AND 2
    JR NZ,key_right
    LD A,(player)
    OR A
    JR Z,key_fire
    DEC A
    LD (player),A
    LD A,1
    LD (player_moved_frame),A
    LD A,2
    LD (move_cd),A
    JR key_fire
key_right:
    LD A,223
    IN A,($FE)
    AND 1
    JR NZ,key_fire
    LD A,(player)
    CP 4
    JR Z,key_fire
    INC A
    LD (player),A
    LD A,1
    LD (player_moved_frame),A
    LD A,2
    LD (move_cd),A
key_fire:
    CALL space_edge
    OR A
    RET Z
    CALL fire
    RET
fire:
    LD A,(player)
    LD (beam_lane),A
    LD A,5
    LD (beam_cd),A
    CALL snd_laser
    CALL enemy_for_player
    LD A,(HL)
    OR A
    RET Z
    PUSH AF
    LD A,(player)
    LD (hit_lane),A
    POP AF
    ADD A,A
    ADD A,7
    LD (hit_row),A
    LD A,2
    LD (hit_cd),A
    CALL enemy_for_player
    LD (HL),0
    LD A,(score)
    INC A
    LD (score),A
    CALL snd_hit
    RET
enemy_for_player:
    LD A,(player)
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    RET
update_timers:
    LD A,(tick_n)
    INC A
    AND 1
    LD (tick_n),A
    LD A,(beam_cd)
    OR A
    JR Z,hit_timer
    DEC A
    LD (beam_cd),A
hit_timer:
    LD A,(hit_cd)
    OR A
    JR Z,spawn_timer
    DEC A
    LD (hit_cd),A
spawn_timer:
    LD A,(spawn_cd)
    INC A
    LD (spawn_cd),A
    LD B,A
    CALL spawn_interval
    CP B
    JR C,spawn_now
    JR step_timer
spawn_now:
    XOR A
    LD (spawn_cd),A
    CALL spawn
step_timer:
    LD A,(step_cd)
    INC A
    LD (step_cd),A
    LD B,A
    CALL step_interval
    CP B
    RET NC
    XOR A
    LD (step_cd),A
    CALL advance
    RET
spawn_interval:
    LD A,(score)
    CP 30
    JR C,sp_20
    LD A,25
    RET
sp_20:
    CP 20
    JR C,sp_15
    LD A,31
    RET
sp_15:
    CP 15
    JR C,sp_10
    LD A,38
    RET
sp_10:
    CP 10
    JR C,sp_5
    LD A,45
    RET
sp_5:
    CP 5
    JR C,sp_0
    LD A,56
    RET
sp_0:
    LD A,68
    RET
step_interval:
    LD A,(score)
    CP 30
    JR C,st_20
    LD A,23
    RET
st_20:
    CP 20
    JR C,st_15
    LD A,27
    RET
st_15:
    CP 15
    JR C,st_10
    LD A,32
    RET
st_10:
    CP 10
    JR C,st_5
    LD A,38
    RET
st_5:
    CP 5
    JR C,st_0
    LD A,46
    RET
st_0:
    LD A,55
    RET
spawn:
    LD A,R
    LD B,A
    LD A,(rng)
    ADD A,B
    ADD A,41
    LD (rng),A
    AND 7
    CP 5
    RET NC
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    LD A,(HL)
    OR A
    RET NZ
    LD (HL),1
    RET
advance:
    XOR A
    LD (escaped_this_tick),A
    LD B,0
advance_lane:
    PUSH BC
    LD A,B
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    LD A,(HL)
    OR A
    JR Z,advance_next
    INC A
    CP 5
    JR Z,breakthrough
    LD (HL),A
    JR advance_next
breakthrough:
    LD (HL),0
    LD A,1
    LD (escaped_this_tick),A
advance_next:
    POP BC
    LD A,(state)
    CP 1
    RET NZ
    INC B
    LD A,B
    CP 5
    JR NZ,advance_lane
    LD A,(escaped_this_tick)
    OR A
    RET Z
    CALL damage
    RET
damage:
    CALL snd_damage
    LD A,(lives)
    DEC A
    LD (lives),A
    RET NZ
    LD A,2
    LD (state),A
    CALL over_screen
    RET
over_screen:
    LD HL,over_scr
    LD DE,16384
    LD BC,6912
    LDIR
    CALL final_score
    RET
reset_snapshots:
    LD HL,prev_enemy
    LD B,20
    LD A,255
reset_prev_loop:
    LD (HL),A
    INC HL
    DJNZ reset_prev_loop
    LD A,255
    LD (prev_score),A
    LD (prev_lives),A
    RET
render_game:
    LD A,(just_committed)
    OR A
    RET NZ
    LD A,0
    LD (tmp_lane),A
    LD (used_units),A
    LD (enemy_updated),A
    LD A,1
    LD (frame_lane_budget),A
    LD A,(prev_tamer_lane)
    CP 5
    JR NC,priority_player_new
    LD (tmp_lane),A
    CALL render_priority_lane
priority_player_new:
    LD A,(player)
    LD (tmp_lane),A
    CALL render_priority_lane
    LD A,(player)
    LD (prev_tamer_lane),A
    LD A,(just_committed)
    OR A
    JP Z,render_nonprio
    JP render_finish
render_nonprio:
    LD A,0
    LD (tmp_lane),A
render_loop:
    CALL lane_changed
    OR A
    JR Z,render_skip_lane
    CALL compute_range
    LD A,(range_end)
    LD B,A
    LD A,(range_start)
    CP B
    JR NC,render_skip_lane
    LD A,(pending_active)
    OR A
    JR Z,render_can_compose
    CALL undo_snapshot
    JR render_finish
render_can_compose:
    CALL check_render_budget
    OR A
    JR NZ,render_allowed
    CALL undo_snapshot
    JR render_finish
render_allowed:
    CALL restore_lane
    CALL paint_lane
    CALL queue_pending
    LD A,(frame_lane_budget)
    DEC A
    LD (frame_lane_budget),A
    JR Z,render_finish
render_skip_lane:
    LD A,(tmp_lane)
    INC A
    LD (tmp_lane),A
    CP 5
    JR NZ,render_loop
render_finish:
    CALL hud_if_changed
    RET
commit_pending:
    XOR A
    LD (just_committed),A
    LD A,(pending_active)
    OR A
    RET Z
    LD A,(pending_lane)
    LD (tmp_lane),A
    LD A,(pending_start)
    LD (range_start),A
    LD A,(pending_end)
    LD (range_end),A
    CALL commit_lane
    LD A,1
    LD (just_committed),A
    XOR A
    LD (pending_active),A
    RET
queue_pending:
    LD A,(tmp_lane)
    LD (pending_lane),A
    LD A,(range_start)
    LD (pending_start),A
    LD A,(range_end)
    LD (pending_end),A
    LD A,1
    LD (pending_active),A
    RET
render_priority_lane:
    CALL lane_changed
    OR A
    RET Z
    LD A,(old_player)
    LD B,A
    LD HL,prev_player
    CALL fetch_prev
    CP B
    JR NZ,priority_player_changed
    CALL undo_snapshot
    RET
priority_player_changed:
    LD A,(old_enemy)
    LD HL,prev_enemy
    CALL put_prev
    LD A,(old_beam)
    LD HL,prev_beam
    CALL put_prev
    LD A,(old_hit)
    LD HL,prev_hit
    CALL put_prev
    LD A,17
    LD (range_start),A
    LD A,21
    LD (range_end),A
    LD A,(used_units)
    ADD A,4
    LD (used_units),A
    CALL restore_lane
    CALL paint_player_only
    CALL commit_lane
    RET
compare_signature:
    LD (sig_value),A
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    ADD HL,DE
    LD A,(sig_value)
    CP (HL)
    RET Z
    LD (HL),A
    LD A,1
    LD (dirty),A
    RET
check_render_budget:
    XOR A
    LD (has_enemy_change),A
    LD A,(old_enemy)
    LD B,A
    LD HL,prev_enemy
    CALL fetch_prev
    CP B
    JR Z,budget_no_enemy
    LD A,1
    LD (has_enemy_change),A
    LD A,(enemy_updated)
    OR A
    JR Z,budget_no_enemy
    XOR A
    RET
budget_no_enemy:
    LD A,(range_end)
    LD B,A
    LD A,(range_start)
    LD C,A
    LD A,B
    SUB C
    LD B,A
    LD A,(used_units)
    OR A
    JR Z,budget_allow
    ADD A,B
    CP 9
    JR C,budget_store
    XOR A
    RET
budget_allow:
    ADD A,B
budget_store:
    LD (used_units),A
    LD A,(has_enemy_change)
    OR A
    JR Z,budget_no_mark
    LD A,1
    LD (enemy_updated),A
budget_no_mark:
    LD A,1
    RET
put_prev:
    LD (sig_value),A
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    ADD HL,DE
    LD A,(sig_value)
    LD (HL),A
    RET
undo_snapshot:
    LD A,(old_enemy)
    LD HL,prev_enemy
    CALL put_prev
    LD A,(old_player)
    LD HL,prev_player
    CALL put_prev
    LD A,(old_beam)
    LD HL,prev_beam
    CALL put_prev
    LD A,(old_hit)
    LD HL,prev_hit
    CALL put_prev
    RET
fetch_prev:
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    ADD HL,DE
    LD A,(HL)
    RET
capture_old_lanes:
    LD HL,prev_enemy
    CALL fetch_prev
    LD (old_enemy),A
    LD HL,prev_player
    CALL fetch_prev
    LD (old_player),A
    LD HL,prev_beam
    CALL fetch_prev
    LD (old_beam),A
    LD HL,prev_hit
    CALL fetch_prev
    LD (old_hit),A
    RET
mark_range:
    LD B,A
    LD A,(range_start)
    CP B
    JR C,mark_start_done
    JR Z,mark_start_done
    LD A,B
    LD (range_start),A
mark_start_done:
    LD A,(range_end)
    CP C
    JR NC,mark_end_done
    LD A,C
    LD (range_end),A
mark_end_done:
    RET
mark_enemy:
    OR A
    RET Z
    CP 5
    RET NC
    ADD A,A
    ADD A,7
    LD B,A
    ADD A,4
    LD C,A
    LD A,B
    CALL mark_range
    RET
mark_player:
    OR A
    RET Z
    CP 3
    RET NC
    LD A,17
    LD C,21
    CALL mark_range
    RET
mark_beam:
    OR A
    RET Z
    CP 2
    RET NC
    LD A,9
    LD C,17
    CALL mark_range
    RET
mark_hit:
    OR A
    RET Z
    CP 22
    RET NC
    LD B,A
    ADD A,4
    LD C,A
    LD A,B
    CALL mark_range
    RET
compute_range:
    LD A,21
    LD (range_start),A
    LD A,9
    LD (range_end),A
    LD A,(old_enemy)
    CALL mark_enemy
    LD HL,prev_enemy
    CALL fetch_prev
    CALL mark_enemy
    LD A,(old_player)
    CALL mark_player
    LD HL,prev_player
    CALL fetch_prev
    CALL mark_player
    LD A,(old_beam)
    CALL mark_beam
    LD HL,prev_beam
    CALL fetch_prev
    CALL mark_beam
    LD A,(old_hit)
    CALL mark_hit
    LD HL,prev_hit
    CALL fetch_prev
    CALL mark_hit
    RET
lane_changed:
    CALL capture_old_lanes
    XOR A
    LD (dirty),A
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    LD A,(HL)
    LD HL,prev_enemy
    CALL compare_signature
    LD A,(player)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,sig_no_player
    LD A,(beam_cd)
    OR A
    JR Z,sig_player_idle
    LD A,(beam_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR Z,sig_player_fire
sig_player_idle:
    LD A,1
    JR sig_player_ready
sig_player_fire:
    LD A,2
    JR sig_player_ready
sig_no_player:
    XOR A
sig_player_ready:
    LD HL,prev_player
    CALL compare_signature
    LD A,(beam_cd)
    OR A
    JR Z,sig_no_beam
    LD A,(beam_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,sig_no_beam
    LD A,1
    JR sig_beam_ready
sig_no_beam:
    XOR A
sig_beam_ready:
    LD HL,prev_beam
    CALL compare_signature
    LD A,(hit_cd)
    OR A
    JR Z,sig_no_hit
    LD A,(hit_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,sig_no_hit
    LD A,(hit_row)
    JR sig_hit_ready
sig_no_hit:
    XOR A
sig_hit_ready:
    LD HL,prev_hit
    CALL compare_signature
    LD A,(dirty)
    RET
restore_lane:
    LD A,(tmp_lane)
    CALL lane_col
    LD A,C
    LD (spr_col),A
    LD A,(range_start)
    LD (restore_row),A
restore_pixrow:
    LD A,(restore_row)
    CALL screen_destination
    LD HL,('game_scr', -24576)
    ADD HL,DE
    LD B,8
restore_scanline:
    PUSH BC
    PUSH HL
    PUSH DE
    LD BC,3
    LDIR
    POP DE
    POP HL
    INC H
    INC D
    POP BC
    DJNZ restore_scanline
    LD A,(restore_row)
    INC A
    LD (restore_row),A
    LD A,(range_end)
    LD B,A
    LD A,(restore_row)
    CP B
    JR NZ,restore_pixrow
    LD A,(range_start)
    LD (restore_row),A
restore_attrrow:
    LD A,(restore_row)
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,30720
    ADD HL,DE
    LD A,(spr_col)
    LD E,A
    LD D,0
    ADD HL,DE
    EX DE,HL
    LD HL,('game_scr', -24576)
    ADD HL,DE
    LD BC,3
    LDIR
    LD A,(restore_row)
    INC A
    LD (restore_row),A
    LD A,(range_end)
    LD B,A
    LD A,(restore_row)
    CP B
    JR NZ,restore_attrrow
    RET
commit_lane:
    LD A,(tmp_lane)
    CALL lane_col
    LD A,C
    LD (spr_col),A
    LD A,(range_start)
    LD (restore_row),A
commit_pixrow:
    LD A,(restore_row)
    CALL screen_destination
    EX DE,HL
    LD A,H
    SUB 32
    LD D,A
    LD A,L
    LD E,A
    LD B,8
commit_scanline:
    PUSH BC
    PUSH HL
    PUSH DE
    LD BC,3
    LDIR
    POP DE
    POP HL
    INC H
    INC D
    POP BC
    DJNZ commit_scanline
    LD A,(restore_row)
    INC A
    LD (restore_row),A
    LD A,(range_end)
    LD B,A
    LD A,(restore_row)
    CP B
    JR NZ,commit_pixrow
    LD A,(range_start)
    LD (restore_row),A
commit_attrrow:
    LD A,(restore_row)
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,30720
    ADD HL,DE
    LD A,(spr_col)
    LD E,A
    LD D,0
    ADD HL,DE
    LD A,H
    SUB 32
    LD D,A
    LD A,L
    LD E,A
    LD BC,3
    LDIR
    LD A,(restore_row)
    INC A
    LD (restore_row),A
    LD A,(range_end)
    LD B,A
    LD A,(restore_row)
    CP B
    JR NZ,commit_attrrow
    RET
paint_lane:
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    LD A,(HL)
    OR A
    JR Z,paint_no_enemy
    LD (enemy_step),A
    ADD A,A
    ADD A,7
    LD B,A
    LD A,(enemy_step)
    AND 1
    JR Z,paint_octo_alt
    LD HL,octo_sprite
    JR paint_octo_ready
paint_octo_alt:
    LD HL,octo_sprite_alt
paint_octo_ready:
    LD A,(tmp_lane)
    CALL stamp
paint_no_enemy:
    LD A,(beam_cd)
    OR A
    JR Z,paint_no_beam
    LD A,(beam_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,paint_no_beam
    LD A,(tmp_lane)
    CALL draw_beam
paint_no_beam:
    LD A,(hit_cd)
    OR A
    JR Z,paint_no_hit
    LD A,(hit_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,paint_no_hit
    LD A,(hit_row)
    LD B,A
    LD A,(tmp_lane)
    LD HL,spark_sprite
    CALL stamp
paint_no_hit:
    LD A,(player)
    LD B,A
    LD A,(tmp_lane)
    CP B
    RET NZ
    LD A,(beam_cd)
    OR A
    JR Z,paint_tamer_idle
    LD A,(beam_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,paint_tamer_idle
    LD HL,tamer_fire_sprite
    JR paint_tamer_ready
paint_tamer_idle:
    LD HL,tamer_sprite
paint_tamer_ready:
    LD B,17
    LD A,(tmp_lane)
    CALL stamp
    RET
paint_player_only:
    LD A,(tmp_lane)
    LD E,A
    LD D,0
    LD HL,enemies
    ADD HL,DE
    LD A,(HL)
    CP 4
    JR NZ,priority_no_octo_bottom
    LD HL,octo_bottom_alt
    LD B,17
    LD A,(tmp_lane)
    CALL stamp_2rows
priority_no_octo_bottom:
    LD A,(hit_cd)
    OR A
    JR Z,priority_no_spark_bottom
    LD A,(hit_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,priority_no_spark_bottom
    LD A,(hit_row)
    CP 15
    JR NZ,priority_no_spark_bottom
    LD HL,spark_bottom
    LD B,17
    LD A,(tmp_lane)
    CALL stamp_2rows
priority_no_spark_bottom:
    LD A,(player)
    LD B,A
    LD A,(tmp_lane)
    CP B
    RET NZ
    LD A,(beam_cd)
    OR A
    JR Z,priority_idle
    LD A,(beam_lane)
    LD B,A
    LD A,(tmp_lane)
    CP B
    JR NZ,priority_idle
    LD HL,tamer_fire_sprite
    JR priority_stamp_tamer
priority_idle:
    LD HL,tamer_sprite
priority_stamp_tamer:
    LD B,17
    LD A,(tmp_lane)
    CALL stamp
    RET
hud_if_changed:
    LD A,(used_units)
    OR A
    RET NZ
    LD A,(just_committed)
    OR A
    RET NZ
    LD A,(player_moved_frame)
    OR A
    RET NZ
    LD A,(pending_active)
    OR A
    RET NZ
    XOR A
    LD (hud_dirty),A
    LD A,(score)
    LD B,A
    LD A,(prev_score)
    CP B
    JR Z,hud_check_lives
    LD A,(score)
    LD (prev_score),A
    CALL hud_score
    LD A,1
    LD (hud_dirty),A
hud_check_lives:
    LD A,(lives)
    LD B,A
    LD A,(prev_lives)
    CP B
    JR Z,hud_commit_if_dirty
    LD A,(lives)
    LD (prev_lives),A
    CALL hud_lives
    LD A,1
    LD (hud_dirty),A
hud_commit_if_dirty:
    LD A,(hud_dirty)
    OR A
    RET Z
    CALL commit_hud
    RET
commit_hud:
    LD A,0
    LD (spr_col),A
    LD A,22
    LD (restore_row),A
commit_hud_pixrow:
    LD A,(restore_row)
    CALL screen_destination
    EX DE,HL
    LD A,H
    SUB 32
    LD D,A
    LD A,L
    LD E,A
    LD B,8
commit_hud_scan:
    PUSH BC
    PUSH HL
    PUSH DE
    LD BC,32
    LDIR
    POP DE
    POP HL
    INC H
    INC D
    POP BC
    DJNZ commit_hud_scan
    LD A,(restore_row)
    INC A
    LD (restore_row),A
    CP 24
    JR NZ,commit_hud_pixrow
    LD HL,31424
    LD DE,23232
    LD BC,64
    LDIR
    RET
lane_col:
    ADD A,A
    LD C,A
    ADD A,A
    ADD A,C
    ADD A,2
    LD C,A
    RET
stamp:
    PUSH AF
    LD A,4
    LD (spr_total),A
    POP AF
    JR stamp_setup
stamp_2rows:
    PUSH AF
    LD A,2
    LD (spr_total),A
    POP AF
stamp_setup:
    PUSH AF
    LD A,B
    LD (spr_start_row),A
    LD (spr_row),A
    POP AF
    CALL lane_col
    LD A,C
    LD (spr_col),A
    LD A,(spr_total)
    LD (spr_count),A
stamp_bitrow:
    PUSH HL
    LD A,(spr_row)
    CALL screen_destination
    POP HL
    LD B,8
stamp_scanline:
    PUSH BC
    LD BC,3
    LDIR
    POP BC
    INC D
    LD A,E
    SUB 3
    LD E,A
    DJNZ stamp_scanline
    LD A,(spr_row)
    INC A
    LD (spr_row),A
    LD A,(spr_count)
    DEC A
    LD (spr_count),A
    JR NZ,stamp_bitrow
    LD A,(spr_start_row)
    LD (spr_row),A
    LD A,(spr_total)
    LD (spr_count),A
stamp_attrrow:
    PUSH HL
    LD A,(spr_row)
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,30720
    ADD HL,DE
    LD A,(spr_col)
    LD E,A
    LD D,0
    ADD HL,DE
    EX DE,HL
    POP HL
    LD BC,3
    LDIR
    LD A,(spr_row)
    INC A
    LD (spr_row),A
    LD A,(spr_count)
    DEC A
    LD (spr_count),A
    JR NZ,stamp_attrrow
    RET
screen_destination:
    ADD A,A
    LD E,A
    LD D,0
    LD HL,scr_rows
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    LD A,(spr_col)
    ADD A,E
    LD E,A
    JR NC,screen_dest_ok
    INC D
screen_dest_ok:
    LD A,D
    ADD A,32
    LD D,A
    RET
draw_beam:
    CALL lane_col
    INC C
    INC C
    LD A,70
    LD (ink),A
    LD B,9
beam_loop:
    LD A,132
    CALL tile
    INC B
    LD A,B
    CP 17
    JR NZ,beam_loop
    RET
hud:
    CALL hud_score
    CALL hud_lives
    RET
hud_score:
    LD A,79
    LD (ink),A
    LD B,22
    LD C,10
    CALL print_score_big
    RET
hud_lives:
    LD D,0
hud_life:
    LD A,(lives)
    CP D
    JR C,hud_dead
    JR Z,hud_dead
    LD A,173
    LD A,74
    LD (ink),A
    LD A,173
    JR hud_life_glyph
hud_dead:
    LD A,65
    LD (ink),A
    LD A,177
hud_life_glyph:
    PUSH AF
    LD A,D
    ADD A,A
    ADD A,25
    LD C,A
    LD B,22
    POP AF
    CALL draw_2x2
    INC D
    LD A,D
    CP 3
    JR NZ,hud_life
    RET
draw_2x2:
    PUSH BC
    PUSH AF
    CALL tile
    POP AF
    PUSH AF
    PUSH BC
    INC A
    INC C
    CALL tile
    POP BC
    POP AF
    PUSH AF
    PUSH BC
    ADD A,2
    INC B
    CALL tile
    POP BC
    POP AF
    ADD A,3
    INC B
    INC C
    CALL tile
    POP BC
    RET
big_digit:
    ADD A,A
    ADD A,A
    ADD A,133
    CALL draw_2x2
    RET
print_score_big:
    LD A,(score)
    LD D,0
big_score_100:
    CP 100
    JR C,big_score_10begin
    SUB 100
    INC D
    JR big_score_100
big_score_10begin:
    LD (score_remainder),A
    LD A,D
    CALL big_digit
    INC C
    INC C
    LD A,(score_remainder)
    LD D,0
big_score_10:
    CP 10
    JR C,big_score_units
    SUB 10
    INC D
    JR big_score_10
big_score_units:
    LD (score_remainder),A
    LD A,D
    CALL big_digit
    INC C
    INC C
    LD A,(score_remainder)
    CALL big_digit
    RET
final_score:
    LD A,78
    LD (ink),A
    LD B,18
    LD C,19
    CALL print_score
    RET
print_score:
    LD A,(score)
    LD D,0
score_100:
    CP 100
    JR C,score_10begin
    SUB 100
    INC D
    JR score_100
score_10begin:
    LD (score_remainder),A
    LD A,D
    ADD A,48
    CALL tile
    INC C
    LD A,(score_remainder)
    LD D,0
score_10:
    CP 10
    JR C,score_units
    SUB 10
    INC D
    JR score_10
score_units:
    LD (score_remainder),A
    LD A,D
    ADD A,48
    CALL tile
    INC C
    LD A,(score_remainder)
    ADD A,48
    CALL tile
    RET
tile:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD (ch_tmp),A
    LD A,B
    LD (row_tmp),A
    LD A,C
    LD (col_tmp),A
    LD A,B
    ADD A,A
    LD E,A
    LD D,0
    LD HL,scr_rows
    ADD HL,DE
    LD E,(HL)
    INC HL
    LD D,(HL)
    LD A,C
    ADD A,E
    LD E,A
    JR NC,tile_dest_ok
    INC D
tile_dest_ok:
    LD A,(state)
    CP 1
    JR NZ,tile_dest_visible
    LD A,D
    ADD A,32
    LD D,A
tile_dest_visible:
    LD (tile_dest),DE
    LD A,(ch_tmp)
    CP 128
    JR C,tile_rom
    SUB 128
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,custom_font
    ADD HL,DE
    JR tile_src_ok
tile_rom:
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,15360
    ADD HL,DE
tile_src_ok:
    LD DE,(tile_dest)
    LD B,8
tile_8scan:
    LD A,(HL)
    LD (DE),A
    INC HL
    INC D
    DJNZ tile_8scan
    LD A,(row_tmp)
    LD L,A
    LD H,0
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    ADD HL,HL
    LD DE,22528
    ADD HL,DE
    LD A,(state)
    CP 1
    JR NZ,tile_attr_visible
    LD DE,8192
    ADD HL,DE
tile_attr_visible:
    LD A,(col_tmp)
    LD E,A
    LD D,0
    ADD HL,DE
    LD A,(ink)
    LD (HL),A
    POP HL
    POP DE
    POP BC
    POP AF
    RET
tone:
tone_pulse:
    LD A,16
    OUT ($FE),A
    LD E,C
tone_high:
    DEC E
    JR NZ,tone_high
    XOR A
    OUT ($FE),A
    LD E,C
tone_low:
    DEC E
    JR NZ,tone_low
    DJNZ tone_pulse
    RET
beep_intro:
    LD B,24
    LD C,29
    CALL tone
    LD B,22
    LD C,17
    CALL tone
    RET
snd_laser:
    LD B,15
    LD C,9
    CALL tone
    LD B,18
    LD C,5
    CALL tone
    RET
snd_hit:
    LD B,18
    LD C,16
    CALL tone
    LD B,30
    LD C,7
    CALL tone
    RET
snd_damage:
    LD B,16
    LD C,26
    CALL tone
    LD B,14
    LD C,42
    CALL tone
    RET
tamer_sprite:
    DB $00,$00,$00,$01,$FF,$C0,$01,$FF,$C0,$01,$FF,$C0,$01,$FF,$C0,$01
    DB $FF,$C0,$03,$FF,$E0,$03,$FF,$E0,$03,$FF,$E0,$00,$7F,$80,$00,$7F
    DB $80,$00,$4E,$80,$00,$7F,$80,$00,$7F,$80,$00,$7F,$80,$00,$FF,$E2
    DB $00,$FF,$E2,$00,$FF,$E2,$07,$FF,$FF,$1F,$FF,$FF,$1F,$FF,$FF,$1F
    DB $FF,$FE,$1F,$FF,$FE,$1F,$FF,$FE,$1F,$FF,$F8,$07,$FF,$F8,$07,$FF
    DB $F8,$01,$FF,$E0,$00,$F1,$E0,$00,$F1,$E0,$03,$F1,$FC,$03,$F1,$FC
    DB $41,$41,$41,$47,$46,$47,$42,$47,$42,$42,$46,$41
tamer_fire_sprite:
    DB $00,$00,$00,$01,$FF,$C0,$01,$FF,$C0,$01,$FF,$C0,$01,$FF,$C0,$01
    DB $FF,$C0,$03,$FF,$E0,$03,$FF,$E0,$03,$FF,$E4,$00,$7F,$8C,$00,$7F
    DB $8C,$00,$4E,$8C,$00,$7F,$8F,$00,$7F,$87,$00,$7F,$86,$00,$FF,$EE
    DB $00,$FF,$FE,$00,$FF,$FE,$07,$FF,$FC,$1F,$FF,$F8,$1F,$FF,$F8,$1F
    DB $FF,$F0,$1F,$FF,$E0,$1F,$FF,$E0,$1F,$FF,$F8,$07,$FF,$F8,$07,$FF
    DB $F8,$01,$FF,$E0,$00,$F1,$E0,$00,$F1,$E0,$03,$F1,$FC,$03,$F1,$FC
    DB $41,$41,$41,$47,$46,$46,$42,$47,$42,$42,$46,$41
octo_sprite:
    DB $00,$00,$00,$00,$7E,$00,$00,$FF,$00,$01,$FF,$80,$03,$FF,$C0,$07
    DB $FF,$E0,$07,$FF,$E0,$0F,$FF,$F0,$0F,$FF,$F0,$1F,$FF,$F8,$1C,$3C
    DB $38,$19,$99,$98,$19,$99,$98,$08,$18,$10,$0C,$3C,$30,$0F,$FF,$E4
    DB $0B,$FF,$CE,$19,$FF,$86,$11,$FE,$23,$31,$B3,$73,$33,$33,$31,$33
    DB $31,$B9,$66,$21,$9F,$66,$61,$8F,$6F,$60,$DF,$7F,$61,$DC,$1D,$F1
    DB $B8,$09,$FB,$10,$00,$9F,$00,$01,$8A,$00,$00,$00,$00,$00,$00,$00
    DB $43,$43,$43,$45,$43,$45,$45,$45,$43,$45,$45,$43
octo_sprite_alt:
    DB $00,$00,$00,$00,$7E,$00,$00,$FF,$00,$01,$FF,$80,$03,$FF,$C0,$07
    DB $FF,$E0,$07,$FF,$E0,$0F,$FF,$F0,$0F,$FF,$F0,$1F,$FF,$F8,$1C,$3C
    DB $38,$19,$99,$98,$19,$99,$98,$08,$18,$10,$0C,$3C,$30,$0F,$FF,$E4
    DB $0B,$FF,$CE,$1D,$FF,$8E,$1F,$FF,$7F,$0C,$DB,$2E,$1D,$99,$B7,$19
    DB $B1,$93,$1B,$31,$9A,$0B,$60,$D6,$0F,$60,$F6,$1D,$70,$E7,$71,$B1
    DB $E3,$23,$B9,$F1,$03,$19,$B8,$07,$1F,$1C,$02,$0B,$08,$00,$00,$00
    DB $43,$43,$43,$45,$43,$45,$45,$45,$43,$43,$45,$43
spark_sprite:
    DB $00,$00,$00,$00,$00,$00,$00,$0C,$00,$00,$0C,$00,$00,$0C,$00,$00
    DB $0C,$10,$02,$0C,$38,$07,$0C,$70,$03,$8C,$60,$01,$8C,$E0,$01,$CD
    DB $C0,$00,$EF,$80,$00,$7F,$00,$00,$3F,$00,$00,$7F,$00,$3F,$FF,$FC
    DB $3F,$FF,$FC,$00,$3F,$00,$00,$7F,$00,$00,$EF,$80,$01,$CD,$C0,$01
    DB $8C,$E0,$03,$8C,$60,$07,$0C,$70,$02,$0C,$38,$00,$0C,$10,$00,$0C
    DB $00,$00,$0C,$00,$00,$0C,$00,$00,$0C,$00,$00,$00,$00,$00,$00,$00
    DB $46,$46,$46,$47,$46,$46,$46,$46,$46,$46,$46,$46
octo_bottom_alt:
    DB $0B,$FF,$CE,$1D,$FF,$8E,$1F,$FF,$7F,$0C,$DB,$2E,$1D,$99,$B7,$19
    DB $B1,$93,$1B,$31,$9A,$0B,$60,$D6,$0F,$60,$F6,$1D,$70,$E7,$71,$B1
    DB $E3,$23,$B9,$F1,$03,$19,$B8,$07,$1F,$1C,$02,$0B,$08,$00,$00,$00
    DB $45,$45,$43,$43,$45,$43
spark_bottom:
    DB $3F,$FF,$FC,$00,$3F,$00,$00,$7F,$00,$00,$EF,$80,$01,$CD,$C0,$01
    DB $8C,$E0,$03,$8C,$60,$07,$0C,$70,$02,$0C,$38,$00,$0C,$10,$00,$0C
    DB $00,$00,$0C,$00,$00,$0C,$00,$00,$0C,$00,$00,$00,$00,$00,$00,$00
    DB $46,$46,$46,$46,$46,$46
custom_font:
    DB $00,$66,$FF,$FF,$7E,$3C,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $7E,$FF,$DB,$DB,$DB,$DB,$FF,$7E,$7E,$81,$81,$81,$81,$81,$81,$7E
    DB $18,$18,$18,$3C,$18,$18,$18,$18,$00,$0F,$0F,$70,$70,$70,$70,$70
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$00,$70,$70,$70,$70,$70,$0F,$0F
    DB $00,$0E,$0E,$0E,$0E,$0E,$F0,$F0,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$0E,$0E,$0E,$0E,$0E,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$0E,$0E,$0E,$0E,$0E,$00,$00,$00,$0F,$0F,$00,$00,$00,$00,$00
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$0F,$7F,$70,$70,$70,$70,$0F,$0F
    DB $F0,$F0,$00,$00,$00,$00,$F0,$F0,$00,$0F,$0F,$00,$00,$00,$00,$00
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$0F,$0F,$00,$00,$00,$00,$0F,$0F
    DB $F0,$FE,$0E,$0E,$0E,$0E,$F0,$F0,$00,$00,$00,$70,$70,$70,$70,$70
    DB $00,$00,$00,$0E,$0E,$0E,$0E,$0E,$0F,$0F,$00,$00,$00,$00,$00,$00
    DB $F0,$FE,$0E,$0E,$0E,$0E,$00,$00,$00,$0F,$0F,$70,$70,$70,$70,$70
    DB $00,$F0,$F0,$00,$00,$00,$00,$00,$0F,$0F,$00,$00,$00,$00,$0F,$0F
    DB $F0,$FE,$0E,$0E,$0E,$0E,$F0,$F0,$00,$0F,$0F,$70,$70,$70,$70,$70
    DB $00,$F0,$F0,$00,$00,$00,$00,$00,$0F,$7F,$70,$70,$70,$70,$0F,$0F
    DB $F0,$FE,$0E,$0E,$0E,$0E,$F0,$F0,$00,$0F,$0F,$00,$00,$00,$00,$00
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$0E,$0E,$0E,$0E,$0E,$00,$00,$00,$0F,$0F,$70,$70,$70,$70,$70
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$0F,$7F,$70,$70,$70,$70,$0F,$0F
    DB $F0,$FE,$0E,$0E,$0E,$0E,$F0,$F0,$00,$0F,$0F,$70,$70,$70,$70,$70
    DB $00,$F0,$F0,$0E,$0E,$0E,$0E,$0E,$0F,$0F,$00,$00,$00,$00,$0F,$0F
    DB $F0,$FE,$0E,$0E,$0E,$0E,$F0,$F0,$00,$00,$0E,$1F,$3F,$3F,$3F,$3F
    DB $00,$00,$38,$7C,$7E,$FE,$FE,$FE,$1F,$0F,$07,$07,$03,$01,$00,$00
    DB $FC,$F8,$F0,$F0,$E0,$C0,$80,$00,$00,$00,$0E,$11,$21,$20,$20,$20
    DB $00,$00,$38,$44,$42,$82,$02,$02,$10,$08,$04,$04,$02,$01,$00,$00
    DB $04,$08,$10,$10,$20,$40,$80,$00
scr_rows:
    DW 16384
    DW 16416
    DW 16448
    DW 16480
    DW 16512
    DW 16544
    DW 16576
    DW 16608
    DW 18432
    DW 18464
    DW 18496
    DW 18528
    DW 18560
    DW 18592
    DW 18624
    DW 18656
    DW 20480
    DW 20512
    DW 20544
    DW 20576
    DW 20608
    DW 20640
    DW 20672
    DW 20704
state:
    DB $00
pressed:
    DB $00
player:
    DB $00
lives:
    DB $00
score:
    DB $00
move_cd:
    DB $00
spawn_cd:
    DB $00
step_cd:
    DB $00
beam_cd:
    DB $00
beam_lane:
    DB $00
hit_cd:
    DB $00
hit_lane:
    DB $00
hit_row:
    DB $00
rng:
    DB $00
tick_n:
    DB $00
tmp_lane:
    DB $00
dirty:
    DB $00
sig_value:
    DB $00
restore_row:
    DB $00
enemy_step:
    DB $00
prev_tamer_lane:
    DB $00
prev_score:
    DB $00
prev_lives:
    DB $00
old_enemy:
    DB $00
old_player:
    DB $00
old_beam:
    DB $00
old_hit:
    DB $00
range_start:
    DB $00
range_end:
    DB $00
frame_lane_budget:
    DB $00
used_units:
    DB $00
has_enemy_change:
    DB $00
enemy_updated:
    DB $00
spr_start_row:
    DB $00
spr_row:
    DB $00
spr_col:
    DB $00
spr_count:
    DB $00
spr_total:
    DB $00
score_remainder:
    DB $00
ch_tmp:
    DB $00
row_tmp:
    DB $00
col_tmp:
    DB $00
ink:
    DB $00
pending_active:
    DB $00
pending_lane:
    DB $00
pending_start:
    DB $00
pending_end:
    DB $00
just_committed:
    DB $00
hud_dirty:
    DB $00
player_moved_frame:
    DB $00
escaped_this_tick:
    DB $00
tile_dest:
    DB $00,$00
enemies:
    DB $00,$00,$00,$00,$00
prev_enemy:
    DB $00,$00,$00,$00,$00
prev_player:
    DB $00,$00,$00,$00,$00
prev_beam:
    DB $00,$00,$00,$00,$00
prev_hit:
    DB $00,$00,$00,$00,$00
title_scr:
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$01,$C0
    DB $00,$00,$00,$38,$00,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$00,$78,$01
    DB $C3,$FE,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C1,$C7,$0F,$DF,$87,$F8,$FC,$E3
    DB $F0,$1C,$E0,$78,$FC,$E1,$DC,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$01,$FC,$07,$0E,$03,$87,$F8,$E1,$E1
    DB $FC,$1C,$1F,$C0,$E1,$EE,$03,$9F,$E0,$00,$00,$00,$00,$03,$00,$FF
    DB $0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$FF,$0F,$F9
    DB $C3,$FE,$01,$FF,$07,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$00,$78,$01
    DB $C3,$FE,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C1,$C7,$0E,$DB,$87,$F8,$EC,$E1
    DB $FE,$1C,$E0,$78,$EC,$E1,$CE,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$FF,$1F,$F9
    DB $C3,$FF,$03,$FF,$0F,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$00,$78,$01
    DB $C3,$8F,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C1,$C7,$0E,$DB,$87,$F8,$EE,$E0
    DB $FF,$1C,$E0,$78,$EE,$E3,$8E,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$FF,$3E,$39
    DB $C3,$FF,$07,$C7,$1F,$3E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$00,$78,$01
    DB $C3,$8F,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$FC,$07,$0F,$07,$87,$F8,$E0,$E0
    DB $FE,$1C,$1F,$80,$E0,$E0,$78,$1C,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C1,$C7,$0E,$FB,$87,$00,$E6,$E0
    DB $1F,$1C,$E0,$78,$E6,$E3,$8E,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$FF,$3C,$09
    DB $C3,$87,$07,$81,$1E,$1E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$00,$3C,$09
    DB $C3,$87,$87,$81,$1E,$1E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$FF,$07,$0F,$07,$87,$F8,$F0,$E1
    DB $FE,$1C,$3F,$E0,$F0,$E0,$F8,$1C,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C3,$C7,$0E,$73,$87,$00,$E7,$E0
    DB $07,$1C,$F0,$70,$E7,$E3,$FF,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$FF,$78,$01
    DB $C3,$87,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$F1,$FF,$80,$3F,$F9
    DB $C3,$87,$87,$FF,$1F,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$FF,$87,$0F,$8F,$87,$F8,$F0,$E3
    DB $EE,$1C,$7D,$F0,$F0,$E0,$F8,$1C,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C3,$C7,$0E,$73,$87,$00,$E7,$E2
    DB $07,$1C,$F0,$70,$E7,$E7,$FF,$1C,$00,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$C0,$FF,$78,$01
    DB $C3,$87,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$F1,$FF,$80,$1F,$F9
    DB $C3,$83,$C3,$FF,$0F,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C7,$C7,$0F,$8F,$87,$00,$F8,$E3
    DB $80,$1C,$70,$F0,$F8,$E0,$FC,$1C,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$FF,$87,$0E,$03,$87,$F8,$E3,$E3
    DB $8F,$1C,$79,$F0,$E3,$E7,$07,$1F,$E0,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$FF
    DB $01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0
    DB $01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$E1,$C0,$FF,$78,$01
    DB $C3,$FF,$0F,$00,$3C,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$F1,$FF,$80,$07,$F1
    DB $C3,$83,$C0,$FE,$07,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$C3,$C7,$0F,$8F,$87,$00,$F8,$E3
    DB $80,$1C,$F0,$70,$F8,$E1,$DC,$1C,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$FF,$01,$FF,$07,$0E,$03,$87,$F8,$E3,$E3
    DB $FE,$1C,$3F,$E0,$E3,$E7,$07,$9F,$E0,$FF,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$CC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80
    DB $C1,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F
    DB $F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$1F,$C0,$1F,$C0,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF,$FF,$FE,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$82,$0F,$82,$0F,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$1F,$FF,$FF,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$BF,$FF,$FF,$E1,$F0,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$3C,$3C,$3E,$3E,$0F,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80
    DB $C1,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$00,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$3F,$C0,$1F,$E0,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF,$FF,$FE,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$80,$0F,$80,$0E,$00,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$00,$1F,$FF,$FF,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$0F,$0F,$FF,$FF,$80,$F8,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$78,$3C,$38,$1E,$1F,$1E,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80
    DB $C1,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$1F,$C0,$00,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$00,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$3F,$80,$0E,$E0,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$C0,$1F,$C0,$1E,$00,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$00,$00,$00,$00,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$0F,$07,$FF,$FF,$00,$FC,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$78,$7C,$78,$1E,$1F,$9E,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80
    DB $C1,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$F8,$00,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$01,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$7F,$00,$00,$F0,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$E0,$3F,$E0,$3E,$00,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F7,$C0,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$1E,$09,$FF,$FC,$10,$7C,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$78,$78,$78,$1F,$0F,$9E,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F
    DB $F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80
    DB $C1,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$FF,$FC,$00,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$01,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$F8,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$F0,$7F,$F0,$7F,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$01,$00,$10,$00,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$01,$F0,$7F,$F0,$7C,$00,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F7,$C0,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$1E,$0F,$3F,$E0,$38,$3E,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$78,$F8,$78,$0F,$07,$DE,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38
    DB $DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$C0
    DB $C3,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$FF,$FF,$00,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$01,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$F8,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$06,$3F,$B0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$E0,$3F,$E0,$3F,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$1F,$FF,$FF,$03,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$02,$FF,$FF,$FF,$F8,$40,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$C0,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$1F,$00,$00,$F8,$1F,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$78,$F0,$78,$0F,$07,$FE,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60
    DB $C6,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$60
    DB $C6,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0F,$FF,$FF,$80,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$01,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$01,$FF,$00,$00,$FC,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$C2,$1F,$C2,$1F,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$1F,$FF,$FF,$03,$FF,$FF,$FF,$FF,$FF,$FF,$01
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$FF,$FF,$F8,$E0,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$C0,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$1E,$3C,$04,$7C,$1F,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$F8,$78,$0F,$83,$FC,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0
    DB $C3,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$38
    DB $DC,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$7F,$FF,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$FF,$FF,$C0,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$01,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$00,$00,$FE,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$07,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$87,$0F,$87,$0F,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$1F,$FF,$FF,$03,$FF,$FF,$FF,$FF,$FF,$FF,$00
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$07,$FF,$FF,$FF,$F3,$E0,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$C0,$FF,$FF,$FF,$FF,$FF,$FF
    DB $E0,$FF,$FF,$FF,$FF,$FF,$FF,$3C,$3E,$3C,$3C,$7E,$0F,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$7F,$81,$1F,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$F8,$70,$07,$81,$FC,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$F1,$FC,$F0,$07,$87,$FC,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$1F,$C0,$7F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $D8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$87,$7C,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$33,$66,$60,$F0,$B0,$3E,$78,$CD,$62,$06
    DB $43,$0C,$CB,$36,$16,$06,$66,$40,$2C,$D8,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$06,$24,$F0,$5A,$C5,$A3,$DE,$FF,$3D
    DB $E7,$B5,$82,$C4,$10,$D1,$96,$6C,$40,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$67,$AC,$D1,$F0,$00
    DB $00,$F0,$19,$20,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FE,$F0,$07,$C7,$F8,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$00,$1F,$C0,$7F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0F,$02,$F8,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$3E,$66,$60,$79,$90,$3E,$3C,$FB,$22,$06
    DB $43,$0F,$99,$3E,$32,$06,$66,$4E,$64,$F8,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$06,$24,$E0,$5A,$C5,$E2,$1E,$FF,$20
    DB $67,$25,$82,$C4,$10,$91,$96,$2C,$40,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$6C,$8C,$80,$67,$3D
    DB $90,$80,$0A,$A7,$3B,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$07,$C7,$C0,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$00,$1F,$C0,$7F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$00,$38,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$30,$66,$60,$09,$F8,$30,$04,$C3,$F3,$06
    DB $63,$0C,$1F,$B6,$3F,$06,$66,$62,$7E,$D8,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$0C,$FC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$02,$64,$80,$5A,$4C,$E2,$12,$FF,$20
    DB $24,$3E,$C2,$4C,$10,$F9,$93,$24,$C0,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$6C,$8C,$F0,$6C,$A4
    DB $B1,$80,$0A,$A1,$A6,$40,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$07,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$3F,$DF,$F8,$07,$CF,$80,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$01,$FF,$C0,$7F,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$10,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$30,$66,$7C,$99,$F8,$3E,$4C,$C3,$F3,$96
    DB $66,$0C,$1F,$B3,$3F,$06,$66,$72,$7E,$CC,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$0C,$FC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$01,$C8,$80,$42,$38,$C3,$D3,$FF,$3D
    DB $E4,$62,$72,$38,$1F,$89,$91,$E3,$80,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$CC,$98,$90,$6C,$A4
    DB $A1,$80,$0E,$E7,$A7,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$00,$7F,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $F0,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$CF,$FC,$0F,$9F,$00,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$01,$FF,$C0,$7F,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$30,$3C,$7C,$FB,$08,$3E,$7C,$C6,$11,$F6
    DB $3C,$0C,$30,$B3,$61,$06,$3C,$3E,$C2,$CC,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$0C,$EC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$00,$08,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$84,$B0,$90,$6C,$A4
    DB $E0,$C2,$0E,$ED,$A6,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$00,$7F,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $D8,$FF,$FF,$FF,$FF,$FF,$FF,$07,$87,$FE,$1F,$3E,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$01,$FF,$C0,$7F,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$00,$00,$00,$3E,$66,$60,$F8,$60,$3E,$7C,$F8,$C1,$F6
    DB $3C,$0F,$86,$3E,$0C,$06,$66,$3E,$18,$F8,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$0E,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$01,$C2,$E0,$66,$3B,$13,$DC,$00,$3C
    DB $C7,$18,$72,$38,$10,$67,$D1,$C3,$80,$00,$00,$00,$FF,$FF,$0C,$CC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$E7,$3C,$F0,$67,$A4
    DB $60,$72,$06,$C7,$A3,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$00,$1F,$C0,$7F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $D8,$FF,$FF,$FF,$FF,$FF,$FF,$02,$07,$DF,$3F,$1C,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$00,$00,$00,$37,$66,$60,$C8,$E0,$3E,$64,$DD,$C3,$96
    DB $66,$0D,$CE,$36,$1C,$06,$66,$72,$38,$D8,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$1C,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$03,$E2,$F0,$66,$7F,$33,$DE,$00,$3D
    DB $E7,$98,$F2,$7C,$10,$67,$D3,$E7,$C0,$00,$00,$00,$FF,$FF,$0C,$CC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00
    DB $40,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$00,$1F,$C0,$7F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $D8,$FF,$FF,$FF,$FF,$FF,$FF,$00,$07,$8F,$BE,$08,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$00,$00,$00,$33,$66,$60,$80,$F0,$30,$40,$CD,$E3,$06
    DB $63,$0C,$CF,$32,$1E,$06,$66,$60,$3C,$C8,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$00,$00,$00,$02,$24,$98,$66,$45,$32,$12,$00,$21
    DB $04,$DC,$82,$44,$10,$71,$92,$04,$40,$00,$00,$00,$FF,$FF,$0C,$CC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$01,$C3,$38,$61,$F0,$00
    DB $00,$70,$19,$30,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00
    DB $C0,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46
    DB $00,$00,$46,$00,$00,$00,$00,$00,$00,$00,$46,$46,$46,$00,$46,$46
    DB $46,$46,$46,$46,$46,$46,$00,$00,$00,$00,$00,$00,$00,$46,$00,$00
    DB $00,$00,$46,$00,$00,$00,$00,$00,$00,$00,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$00,$00,$00,$00,$00,$00,$00,$46,$00,$00
    DB $00,$00,$46,$00,$00,$00,$00,$45,$45,$45,$45,$45,$45,$45,$45,$45
    DB $45,$45,$45,$45,$45,$45,$45,$45,$00,$00,$00,$00,$00,$46,$00,$00
    DB $00,$00,$46,$00,$00,$00,$00,$45,$45,$45,$45,$45,$45,$45,$45,$45
    DB $45,$45,$45,$45,$45,$45,$45,$45,$45,$00,$00,$00,$00,$46,$00,$00
    DB $00,$47,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$47,$00
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $46,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$47
    DB $47,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$47,$47
    DB $46,$47,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$41,$41,$41,$00,$00,$00,$00,$00,$00,$00,$47
    DB $46,$00,$00,$00,$00,$00,$00,$00,$43,$43,$43,$43,$00,$00,$46,$43
    DB $42,$42,$00,$00,$47,$47,$79,$47,$00,$00,$00,$00,$00,$00,$00,$46
    DB $46,$00,$00,$00,$00,$00,$00,$45,$43,$5F,$5F,$43,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$46,$46,$46,$00,$00,$00,$00,$00,$00,$00,$46
    DB $46,$00,$00,$00,$00,$00,$00,$45,$43,$43,$43,$45,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$47,$47,$47,$47,$00,$00,$00,$00,$00,$00,$46
    DB $46,$00,$00,$00,$00,$00,$00,$45,$45,$45,$45,$45,$43,$00,$46,$42
    DB $42,$43,$00,$00,$42,$42,$47,$42,$46,$46,$00,$00,$00,$00,$00,$00
    DB $46,$00,$00,$00,$00,$00,$00,$45,$43,$45,$45,$45,$43,$00,$46,$43
    DB $42,$42,$00,$00,$42,$51,$7E,$42,$42,$00,$00,$00,$00,$00,$00,$00
    DB $46,$00,$00,$00,$00,$00,$00,$45,$43,$45,$43,$45,$43,$00,$46,$42
    DB $42,$43,$00,$00,$41,$42,$42,$42,$41,$00,$00,$00,$00,$00,$00,$00
    DB $46,$00,$00,$00,$00,$00,$00,$45,$43,$45,$43,$45,$43,$00,$46,$43
    DB $42,$42,$00,$00,$41,$41,$46,$46,$41,$00,$00,$00,$00,$00,$00,$00
    DB $46,$00,$00,$00,$00,$00,$00,$00,$43,$45,$43,$00,$00,$00,$46,$42
    DB $42,$43,$00,$46,$46,$46,$47,$47,$46,$47,$47,$47,$47,$47,$47,$47
    DB $47,$47,$47,$47,$47,$46,$47,$47,$47,$47,$46,$46,$46,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
    DB $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$46,$46,$46,$46,$45,$45,$45,$45,$45,$45,$46,$45
    DB $45,$45,$45,$45,$46,$45,$45,$45,$46,$46,$46,$46,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$45,$45,$45,$45,$45,$45,$45,$00,$45
    DB $45,$45,$45,$45,$45,$45,$45,$45,$45,$00,$00,$00,$00,$00,$46,$42
    DB $00,$00,$00,$00,$00,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
game_scr:
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$FF,$00,$F8,$E7,$E0,$1F,$03,$C0,$0F,$C0,$E7,$87
    DB $9F,$E7,$0E,$1F,$0E,$0F,$07,$0E,$0E,$07,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$07,$00,$E7,$38,$E0,$1C,$38,$0E,$1C,$E7,$3B
    DB $9C,$07,$3E,$01,$8E,$70,$E7,$3E,$7F,$C7,$00,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$1F,$00,$FF
    DB $00,$18,$FC,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$7F,$00,$08,$FF,$01,$F0,$FF
    DB $F8,$F0,$FF,$00,$F0,$FF,$1F,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$00,$00,$03,$F0,$00,$FE,$F0,$00,$E0,$E0,$00,$FF,$E0,$01
    DB $FF,$C0,$00,$80,$E0,$00,$E0,$E0,$00,$FF,$3F,$C0,$00,$00,$00,$FF
    DB $0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
    DB $CC,$DC,$07,$FF,$F0,$00,$FF,$00,$07,$FF,$F0,$00,$FF,$00,$07,$FF
    DB $F0,$00,$FF,$00,$07,$FF,$F0,$00,$FF,$00,$07,$FF,$F0,$00,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$FF,$01,$FC,$E7,$F8,$3F,$8F,$F0,$0F,$F0,$E7,$87
    DB $9F,$E7,$8E,$3F,$8E,$3F,$C7,$8E,$0F,$07,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$07,$84,$E7,$1C,$F0,$9E,$38,$0E,$78,$E7,$33
    DB $9C,$07,$1E,$43,$8E,$78,$E7,$1E,$7F,$C7,$00,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$03,$FF,$00,$FF
    DB $00,$38,$FF,$C0,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$0F,$FF,$00,$18,$FF,$01,$F0,$FF
    DB $F0,$E0,$FF,$01,$F0,$FF,$01,$F8,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$00,$00,$3F,$00,$00,$F8,$F0,$00,$80,$E0,$01,$FF,$C0,$03
    DB $FF,$C0,$00,$00,$E0,$00,$C0,$E0,$00,$FF,$F0,$FC,$00,$00,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$1F,$7F,$7C,$40,$FF,$00,$1F,$7F,$7C,$40,$FF,$00,$1F,$7F
    DB $7C,$40,$FF,$00,$1F,$7F,$7C,$40,$FF,$00,$1F,$7F,$7C,$40,$0C,$CC
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$FF,$FF,$08,$FF,$03,$8C,$E7,$F8,$71,$8E,$78,$0F,$F8,$E7,$C7
    DB $9F,$E7,$8E,$71,$8E,$39,$E7,$8E,$1F,$07,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$03,$FC,$E7,$1C,$7F,$8F,$F0,$0F,$F8,$E7,$03
    DB $9F,$E7,$1E,$7F,$8E,$3F,$C7,$1E,$60,$E7,$F8,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$3F,$FF,$00,$FF
    DB $00,$38,$FF,$FE,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$FF,$FF,$00,$38,$FF,$03,$F0,$FF
    DB $F0,$E0,$FF,$03,$F0,$FF,$00,$FF,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$00,$03,$FF,$08,$00,$F0,$E0,$00,$00,$E0,$03,$FF,$C0,$07
    DB $FF,$C0,$01,$00,$C0,$00,$80,$E0,$00,$FC,$F0,$FF,$C0,$00,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$3B,$FF,$EE,$00,$FF,$00,$3B,$FF,$EE,$00,$FF,$00,$3B,$FF
    DB $EE,$00,$FF,$00,$3B,$FF,$EE,$00,$FF,$00,$3B,$FF,$EE,$00,$0C,$CC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $FF,$FF,$FF,$08,$FF,$07,$00,$E7,$18,$E0,$1C,$38,$0E,$1C,$E7,$CF
    DB $9C,$07,$CE,$60,$0E,$70,$E7,$CE,$1B,$07,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$01,$F8,$E7,$0E,$3F,$07,$E0,$0F,$E0,$E7,$03
    DB $9F,$E7,$1E,$7F,$0E,$1F,$87,$1E,$E0,$E7,$F8,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$03,$FF,$FF,$08,$FF
    DB $00,$70,$FF,$FF,$E0,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$0F,$FF,$FF,$00,$F0,$FF,$07,$F0,$FF
    DB $E0,$E0,$FF,$07,$F0,$FF,$00,$FF,$F8,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$00,$3F,$FF,$70,$00,$C0,$E0,$01,$00,$C0,$07,$FF,$C0,$07
    DB $FF,$C0,$03,$00,$C0,$00,$00,$C0,$00,$F0,$E0,$FF,$FE,$00,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$77,$FF,$F7,$00,$FF,$00,$77,$FF,$F7,$00,$FF,$00,$77,$FF
    DB $F7,$00,$FF,$00,$77,$FF,$F7,$00,$FF,$00,$77,$FF,$F7,$00,$0C,$CC
    DB $00,$00,$00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$00,$00,$00
    DB $FF,$FF,$FF,$08,$FF,$07,$00,$E7,$18,$E0,$1C,$18,$0E,$1C,$E7,$CF
    DB $9C,$07,$CE,$70,$0E,$70,$67,$CE,$1B,$87,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$3F,$FF,$FF,$18,$FF
    DB $00,$F0,$FF,$FF,$FE,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$01,$FF,$FF,$FF,$01,$F0,$FF,$0F,$E0,$FF
    DB $C0,$E0,$FF,$0F,$E0,$FF,$00,$FF,$FF,$80,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$07,$FF,$FF,$F0,$00,$00,$E0,$03,$00,$C0,$07,$FF,$C0,$0F
    DB $FF,$C0,$07,$00,$C0,$03,$00,$C0,$00,$C0,$E0,$FF,$FF,$E8,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DC,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF
    DB $DD,$80,$FF,$00,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF,$DD,$80,$0C,$CC
    DB $00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00
    DB $FF,$FF,$FF,$08,$FF,$07,$00,$E7,$F8,$E0,$1C,$18,$0E,$1C,$E7,$6F
    DB $9F,$C7,$6E,$7F,$0E,$70,$67,$6E,$3B,$87,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$07,$FF,$FF,$FF,$38,$FF
    DB $01,$F0,$FF,$FF,$FF,$E0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$1F,$FF,$FF,$FF,$03,$F0,$FF,$1F,$E0,$FF
    DB $80,$E0,$FF,$1F,$E0,$FF,$01,$FF,$FF,$F8,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$00,$7F,$FF,$FF,$E0,$01,$00,$C0,$07,$00,$C0,$0F,$FF,$C0,$1F
    DB $FF,$C0,$0F,$00,$C0,$07,$00,$C0,$00,$00,$E0,$FF,$FF,$FE,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DD,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF
    DB $EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$0C,$CC
    DB $00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00
    DB $FF,$FF,$FF,$08,$FF,$07,$00,$E7,$F0,$E0,$1C,$1C,$0E,$1C,$E7,$7B
    DB $9F,$C7,$6E,$3F,$8E,$70,$77,$6E,$39,$87,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$7F,$FF,$FF,$FF,$70,$FF
    DB $01,$F0,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$01,$FF,$FF,$FF,$FF,$07,$F0,$FF,$3F,$E0,$FF
    DB $00,$E0,$FF,$3F,$E0,$FF,$03,$FF,$FF,$FF,$80,$FF,$FF,$FF,$FF,$FF
    DB $FF,$07,$FF,$FF,$FF,$E0,$07,$00,$C0,$0F,$00,$C0,$1F,$FF,$C0,$3F
    DB $FF,$80,$1F,$00,$C0,$0F,$00,$C0,$03,$00,$C0,$FF,$FF,$FF,$E0,$FF
    DB $01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0
    DB $01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0
    DB $CC,$DD,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F
    DB $76,$C0,$FF,$01,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F,$76,$C0,$0C,$CC
    DB $00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00
    DB $FF,$FF,$FF,$08,$FF,$07,$00,$E7,$F8,$E0,$1C,$18,$0E,$1C,$E7,$7B
    DB $9C,$07,$3E,$07,$8E,$70,$67,$3E,$31,$C7,$FF,$FF,$04,$FF,$FF,$FF
    DB $FF,$FF,$FF,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$FF,$FF,$FF,$FF,$F0,$FF
    DB $03,$F0,$FF,$FF,$FF,$FF,$F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$1F,$FF,$FF,$FF,$FF,$0F,$E0,$FF,$7F,$E0,$FF
    DB $00,$E0,$FF,$3F,$E0,$FF,$07,$FF,$FF,$FF,$FC,$FF,$FF,$FF,$FF,$FF
    DB $FF,$7F,$FF,$FF,$FF,$C0,$1F,$00,$C0,$3F,$00,$80,$3F,$FF,$80,$3F
    DB $FF,$80,$3F,$00,$80,$1F,$00,$80,$0F,$00,$C0,$FF,$FF,$FF,$FF,$FF
    DB $CC,$CC,$00,$FF,$80,$00,$00,$00,$00,$FF,$80,$00,$00,$00,$00,$FF
    DB $80,$00,$00,$00,$00,$FF,$80,$00,$00,$00,$00,$FF,$80,$00,$0C,$CC
    DB $CC,$DF,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF
    DB $BB,$60,$FF,$03,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF,$BB,$60,$0C,$CC
    DB $CC,$DF,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF
    DB $DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$0C,$CC
    DB $CC,$DC,$3B,$FF,$EE,$FF,$00,$FF,$3B,$FF,$EE,$FF,$00,$FF,$3B,$FF
    DB $EE,$FF,$00,$FF,$3B,$FF,$EE,$FF,$00,$FF,$3B,$FF,$EE,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DF,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF
    DB $DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$0C,$EC
    DB $CC,$DC,$1F,$7F,$7C,$FF,$00,$FF,$1F,$7F,$7C,$FF,$00,$FF,$1F,$7F
    DB $7C,$FF,$00,$FF,$1F,$7F,$7C,$FF,$00,$FF,$1F,$7F,$7C,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DF,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF
    DB $DB,$60,$FF,$03,$6D,$FF,$DB,$60,$FF,$03,$6D,$FF,$DB,$60,$0C,$FC
    DB $CC,$DC,$07,$FF,$F0,$FF,$00,$FF,$07,$FF,$F0,$FF,$00,$FF,$07,$FF
    DB $F0,$FF,$00,$FF,$07,$FF,$F0,$FF,$00,$FF,$07,$FF,$F0,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DF,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF
    DB $BB,$60,$FF,$03,$6E,$FF,$BB,$60,$FF,$03,$6E,$FF,$BB,$60,$0C,$FC
    DB $CC,$DC,$00,$FF,$80,$FF,$08,$FF,$00,$FF,$80,$FF,$08,$FF,$00,$FF
    DB $80,$FF,$08,$FF,$00,$FF,$80,$FF,$08,$FF,$00,$FF,$80,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DD,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F
    DB $76,$C0,$FF,$01,$B7,$7F,$76,$C0,$FF,$01,$B7,$7F,$76,$C0,$0C,$EC
    DB $CC,$DC,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00
    DB $00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DD,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF
    DB $EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$FF,$01,$BB,$FF,$EE,$C0,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00
    DB $00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF
    DB $DD,$80,$FF,$00,$DD,$FF,$DD,$80,$FF,$00,$DD,$FF,$DD,$80,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00
    DB $00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$00,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$F7,$FF,$F7,$00,$FF,$00,$F7,$FF,$F7,$00,$FF,$00,$F7,$FF
    DB $F7,$00,$FF,$00,$F7,$FF,$F7,$00,$FF,$00,$F7,$FF,$F7,$00,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00
    DB $00,$FF,$08,$FF,$00,$00,$00,$FF,$08,$FF,$00,$00,$00,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$80,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $08,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$08,$80,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$10
    DB $0A,$03,$06,$49,$CC,$23,$0C,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$28,$A0,$51,$B3,$3E,$0C,$00,$00,$00,$00,$00,$00,$00,$50
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $00,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$00
    DB $0A,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$2A,$A0,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $0A,$03,$06,$C9,$CC,$33,$4C,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$28,$A0,$71,$B6,$3E,$4C,$00,$00,$00,$00,$00,$00,$00,$50
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $00,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$00
    DB $0A,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A0,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $0A,$03,$03,$C8,$CC,$1E,$78,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$28,$A0,$71,$BC,$63,$78,$00,$00,$00,$00,$00,$00,$00,$50
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $0A,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A0,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$28,$A0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$50
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$00
    DB $0A,$03,$E6,$4C,$FF,$3E,$78,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A1,$8D,$BE,$1C,$78,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $0A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$28,$A0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$50
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF
    DB $FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8,$00
    DB $0A,$03,$66,$4E,$CC,$33,$40,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A0,$89,$B7,$14,$40,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$0A,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF
    DB $FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $0A,$03,$66,$4A,$CC,$23,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A0,$D9,$B3,$14,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF
    DB $FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF
    DB $FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $0A,$03,$E6,$4B,$CC,$63,$78,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$28,$A0,$D9,$B3,$36,$78,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46
    DB $00,$00,$00,$46,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$46,$00,$00,$00
    DB $00,$00,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$47,$47,$42,$42,$42,$56,$42
    DB $51,$51,$42,$42,$42,$47,$47,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$47,$42,$42,$42,$42,$51,$51,$42,$56,$56,$42
    DB $4A,$51,$42,$56,$56,$42,$57,$42,$42,$42,$47,$00,$00,$00,$00,$00
    DB $00,$47,$42,$42,$42,$51,$56,$72,$56,$51,$4A,$51,$56,$46,$56,$51
    DB $41,$51,$56,$72,$56,$51,$4A,$51,$56,$72,$56,$42,$42,$47,$47,$00
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $42,$43,$43,$41,$45,$43,$00,$43,$43,$41,$45,$43,$00,$43,$43,$41
    DB $45,$43,$00,$43,$43,$41,$45,$43,$00,$43,$43,$41,$45,$43,$46,$42
    DB $42,$43,$45,$01,$45,$43,$00,$43,$45,$01,$45,$43,$00,$43,$45,$01
    DB $45,$43,$00,$43,$45,$01,$45,$43,$00,$43,$45,$01,$45,$43,$46,$43
    DB $42,$42,$43,$43,$43,$00,$01,$00,$43,$43,$43,$00,$01,$00,$43,$43
    DB $43,$00,$01,$00,$43,$43,$43,$00,$01,$00,$43,$43,$43,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$44,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00
    DB $00,$00,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$46,$43
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $4E,$4F,$4F,$4F,$4F,$4F,$4F,$01,$01,$01,$01,$01,$01,$01,$01,$01
    DB $01,$01,$4E,$4E,$4F,$4F,$4F,$4F,$01,$01,$01,$01,$01,$01,$01,$4E
    DB $4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E
    DB $4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E
over_scr:
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$3F,$38,$01,$C1,$E3,$80,$FF,$70
    DB $07,$07,$0F,$CE,$3C,$00,$E3,$C0,$E3,$F3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$38,$78,$01,$FF,$83,$FE,$FF,$70
    DB $03,$FE,$0E,$1E,$0F,$F8,$E0,$FF,$83,$87,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$60,$F1,$F0,$3E,$66,$61,$F0,$F1,$F0,$31
    DB $0C,$31,$07,$CF,$8F,$86,$3E,$30,$F8,$78,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$0F,$00,$00,$00
    DB $00,$00,$00,$78,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$FE,$1C,$3B,$38,$01,$C1,$E3,$FC,$FF,$7F
    DB $87,$07,$0E,$CE,$38,$00,$E3,$80,$E3,$B3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$38,$78,$01,$FE,$03,$FE,$FF,$70
    DB $01,$FC,$0E,$1E,$07,$F0,$E0,$7F,$03,$87,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$61,$99,$90,$37,$66,$61,$B9,$99,$90,$31
    DB $1C,$39,$07,$CC,$9C,$8E,$37,$70,$FC,$CC,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$3C,$00,$00,$00
    DB $00,$00,$00,$1E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$FE,$1C,$3B,$B8,$01,$C0,$E3,$FC,$FF,$7F
    DB $87,$07,$0E,$EE,$38,$00,$E3,$80,$E3,$BB,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$61,$8D,$00,$33,$66,$61,$99,$8D,$00,$31
    DB $1E,$39,$06,$08,$18,$0F,$33,$78,$CC,$C6,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$F0,$00,$00,$3F
    DB $FF,$00,$00,$07,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$01,$FF,$1C,$38,$38,$01,$F0,$03,$FE,$FF,$7F
    DB $C7,$07,$0E,$0E,$01,$E0,$E0,$3E,$03,$83,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$FE,$1C,$39,$B8,$01,$C1,$E3,$FC,$FF,$7F
    DB $87,$07,$0E,$6E,$38,$00,$E3,$80,$E3,$9B,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$61,$0D,$E0,$33,$66,$61,$99,$0D,$E0,$3F
    DB $16,$3D,$07,$CF,$10,$0B,$33,$58,$C6,$86,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$C0,$00,$0F,$C7
    DB $F0,$FC,$00,$01,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$01,$FF,$1C,$3C,$38,$01,$FF,$03,$FE,$FF,$7F
    DB $C7,$07,$0F,$0E,$07,$F8,$E0,$FF,$83,$C3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$39,$F8,$01,$C1,$E3,$80,$FF,$70
    DB $07,$07,$0E,$7E,$3C,$00,$E3,$C0,$E3,$9F,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$61,$0C,$F0,$3E,$66,$61,$F1,$0C,$F0,$3F
    DB $32,$35,$07,$C7,$90,$19,$3E,$C8,$C6,$86,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E3,$FF,$E0
    DB $03,$FF,$E3,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$00,$00,$70,$3F
    DB $FE,$03,$80,$00,$70,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$01,$FF,$1C,$3C,$38,$01,$FF,$83,$FE,$FF,$7F
    DB $C7,$07,$0F,$0E,$0F,$F8,$E1,$FF,$C3,$C3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$39,$F8,$01,$C1,$E3,$80,$FF,$70
    DB $07,$0F,$0E,$7E,$3C,$00,$E3,$C1,$E3,$9F,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$61,$8C,$10,$30,$66,$61,$81,$8C,$10,$31
    DB $3F,$37,$06,$00,$98,$1F,$B0,$FC,$CC,$C6,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$00,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF
    DB $03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$FF,$C3,$E0
    DB $03,$E1,$FF,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0,$03,$E0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$00,$03,$80,$7F
    DB $FF,$00,$70,$00,$1C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$3E,$38,$01,$C7,$C3,$80,$FF,$70
    DB $07,$07,$0F,$8E,$1E,$08,$E1,$E3,$E3,$E3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$38,$F8,$01,$C3,$C3,$80,$FF,$70
    DB $07,$0F,$0E,$3E,$1E,$00,$E1,$C1,$E3,$8F,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$7D,$99,$30,$30,$66,$7D,$81,$99,$30,$31
    DB $3F,$33,$07,$C9,$9C,$9F,$B0,$FC,$FC,$CC,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$FF
    DB $01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$FC,$01,$C0
    DB $01,$C0,$1F,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0,$01,$C0
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$00,$1C,$01,$FF
    DB $FF,$C0,$0E,$00,$0E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $00,$00,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$3E,$38,$01,$C1,$C3,$80,$FF,$70
    DB $07,$07,$0F,$8E,$3C,$00,$E3,$C1,$E3,$E3,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$01,$C0,$1C,$38,$F8,$01,$FF,$C3,$FE,$FF,$70
    DB $07,$DE,$0E,$3E,$1F,$B8,$E1,$F7,$C3,$8F,$80,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$03,$FF,$FF
    DB $FF,$FF,$60,$FF,$FF,$FF,$7C,$F1,$F0,$30,$3C,$7D,$80,$F1,$F0,$31
    DB $61,$33,$07,$CF,$8F,$B0,$B1,$84,$F8,$78,$FF,$FF,$FF,$03,$FF,$FF
    DB $FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $CC,$CC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$E0,$00,$00
    DB $00,$00,$03,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$00,$60,$03,$FF
    DB $FF,$E0,$01,$80,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$C0,$01,$80,$07,$F0
    DB $07,$F0,$FF,$60,$01,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$C0,$04,$FF,$00,$FF,$FF
    DB $FF,$FF,$80,$FF,$08,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$01,$FF,$FF,$01,$E1,$C3
    DB $E1,$C3,$C0,$FF,$FF,$20,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$01,$FF,$FF
    DB $FF,$FC,$F8,$00,$FF,$04,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$0F,$0F,$8F
    DB $0F,$1F,$83,$C0,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$3C,$3E,$1C
    DB $01,$E0,$7F,$FF,$FF,$04,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$00,$80,$FF,$FF,$01,$E3
    DB $EF,$82,$FF,$FF,$00,$40,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$70,$02,$00,$00,$FF,$FF
    DB $FF,$FF,$FF,$00,$10,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$80,$02,$00,$07,$F0
    DB $07,$F0,$FF,$10,$00,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80,$08,$FF,$00,$FF,$FF
    DB $FF,$FF,$80,$FF,$04,$00,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$01,$FF,$FF,$01,$E0,$83
    DB $E0,$83,$C0,$FF,$FF,$20,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$01,$EF,$FF
    DB $FF,$F8,$7C,$00,$FF,$04,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$0F,$0F,$0F
    DB $0F,$8F,$83,$C0,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$3C,$7F,$3C
    DB $01,$E1,$FF,$FF,$FF,$04,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06,$00,$80,$FF,$FF,$01,$E1
    DB $DF,$00,$FF,$FF,$00,$40,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$01,$00,$00,$FF,$FF
    DB $FF,$FF,$FF,$00,$20,$0E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$00,$0C,$00,$0F,$F0
    DB $07,$F8,$FF,$0C,$00,$70,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$80,$10,$FF,$00,$FF,$FF
    DB $FF,$FF,$80,$FF,$02,$00,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$02,$FF,$FF,$00,$E0,$03
    DB $E0,$03,$80,$FF,$FF,$10,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$03,$C3,$FF
    DB $FF,$E0,$3E,$00,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$1E,$0F,$0E
    DB $07,$87,$C7,$80,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$04,$FF,$FF,$1F,$FF,$BC
    DB $01,$F1,$FE,$FF,$FF,$08,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06,$00,$40,$FF,$FF,$03,$C0
    DB $BE,$00,$FF,$FF,$00,$80,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$00,$80,$00,$FF,$FF
    DB $FF,$FF,$FF,$00,$40,$1C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0E,$00,$10,$00,$0F,$E0
    DB $03,$F8,$FF,$02,$00,$38,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$00,$20,$FF,$01,$FF,$FF
    DB $FF,$FF,$C0,$FF,$01,$00,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$02,$FF,$FF,$00,$F0,$07
    DB $F0,$07,$80,$FF,$FF,$10,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$03,$C1,$FF
    DB $FF,$C0,$3F,$00,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$1E,$1F,$1E
    DB $07,$87,$E7,$80,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$04,$FF,$FF,$3F,$FF,$FC
    DB $01,$F1,$F0,$FF,$FF,$08,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$00,$20,$FF,$FF,$00,$40
    DB $0E,$00,$FF,$FF,$01,$00,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0E,$00,$60,$00,$FF,$FF
    DB $FF,$FF,$FF,$01,$80,$38,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$00,$60,$00,$1F,$00
    DB $00,$FC,$FF,$01,$80,$1C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06,$00,$20,$FF,$01,$FF,$FF
    DB $FF,$FF,$C0,$FF,$01,$00,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$04,$FF,$FF,$00,$F8,$0F
    DB $F8,$0F,$80,$FF,$FF,$08,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$07,$82,$7F
    DB $FF,$04,$1F,$00,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$1E,$1E,$1E
    DB $07,$C3,$E7,$80,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$30,$02,$FF,$FF,$0F,$F7,$FE
    DB $01,$F3,$E0,$FF,$FF,$10,$06,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$80,$20,$FF,$FF,$00,$00
    DB $04,$00,$FF,$FF,$01,$00,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$00,$10,$00,$FF,$FF
    DB $FF,$FF,$FF,$02,$00,$70,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$00,$80,$00,$3F,$00
    DB $00,$FE,$FF,$00,$40,$0E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$06,$00,$40,$FF,$01,$FC,$1F
    DB $FC,$1F,$C0,$FF,$00,$80,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$04,$FF,$FF,$00,$7C,$1F
    DB $FC,$1F,$00,$FF,$FF,$08,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$07,$83,$CF
    DB $F8,$0E,$0F,$80,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$10,$FF,$FF,$1E,$3E,$1E
    DB $03,$C1,$F7,$80,$FF,$02,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$02,$FF,$FF,$07,$F3,$FF
    DB $03,$E7,$C0,$FF,$FF,$10,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$80,$10,$FF,$FF,$00,$00
    DB $00,$00,$FF,$FF,$02,$00,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$80,$0C,$00,$FF,$FF
    DB $FF,$FF,$FF,$0C,$00,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$70,$01,$00,$00,$3F,$00
    DB $00,$FE,$FF,$00,$20,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$00,$80,$FF,$01,$F8,$0F
    DB $F8,$0F,$C0,$FF,$00,$40,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$00,$BF,$FF
    DB $FF,$FE,$10,$FF,$FF,$04,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$0F,$07,$C0
    DB $00,$3E,$07,$C0,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$1E,$3C,$1E
    DB $03,$C1,$FF,$80,$FF,$04,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$18,$01,$FF,$FF,$01,$E1,$FF
    DB $87,$CF,$80,$FF,$FF,$20,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$C0,$08,$FF,$FF,$00,$00
    DB $00,$00,$FF,$FF,$04,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$C0,$02,$00,$FF,$FF
    DB $FF,$FF,$FF,$10,$01,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$02,$00,$00,$7F,$00
    DB $00,$FF,$FF,$00,$10,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$00,$80,$FF,$01,$F0,$87
    DB $F0,$87,$C0,$FF,$00,$40,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$00,$FF,$FF
    DB $FF,$FE,$38,$FF,$FF,$04,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$10,$FF,$FF,$0F,$07,$8F
    DB $01,$1F,$07,$C0,$FF,$02,$01,$80,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$60,$08,$FF,$FF,$3C,$3E,$1E
    DB $03,$E0,$FF,$00,$FF,$04,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$01,$FF,$FF,$00,$81,$F7
    DB $CF,$C7,$00,$FF,$FF,$20,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$60,$04,$FF,$FF,$00,$00
    DB $00,$00,$FF,$FF,$08,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$60,$01,$80,$FF,$FF
    DB $FF,$FF,$FF,$60,$03,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$38,$00,$60,$00,$00
    DB $00,$00,$01,$80,$0E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$00,$00
    DB $00,$00,$1F,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CC,$DC,$80,$FF,$FF,$FF,$07,$30,$60,$E7,$3E,$38,$80,$18,$4F,$E6
    DB $84,$06,$F0,$0C,$60,$0F,$4C,$E1,$F3,$C0,$FF,$FF,$FF,$01,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$03,$66,$CF,$36,$A3,$62,$8C,$3C,$1B,$51,$B1
    DB $40,$8C,$63,$62,$81,$E6,$45,$68,$1A,$32,$B0,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1C,$00,$1C,$00,$00
    DB $00,$00,$0E,$00,$1C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$C0,$00
    DB $00,$01,$FC,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$71,$32,$3F
    DB $1C,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CF,$DC,$80,$FF,$FF,$FF,$07,$33,$64,$47,$72,$33,$C0,$08,$D9,$67
    DB $8C,$06,$B0,$1C,$60,$1C,$4C,$63,$96,$60,$FF,$FF,$FF,$01,$0C,$EC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$03,$E7,$8F,$3F,$B3,$C6,$CC,$3C,$1F,$D9,$E3
    DB $61,$8C,$63,$C6,$C1,$E6,$45,$F8,$1E,$32,$F0,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$07,$00,$03,$80,$00
    DB $00,$00,$70,$00,$70,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$FF,$00
    DB $00,$7F,$E0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$79,$33,$3F
    DB $3E,$78,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CF,$DC,$80,$FF,$FF,$FF,$06,$F7,$E6,$43,$60,$33,$6C,$0C,$D8,$27
    DB $CC,$3E,$90,$1E,$60,$18,$CC,$23,$06,$30,$FF,$FF,$FF,$01,$0C,$FC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$03,$06,$CC,$31,$F3,$67,$CC,$30,$18,$F9,$B3
    DB $E0,$8C,$63,$67,$C1,$86,$44,$E8,$1A,$32,$70,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$C0,$00,$70,$00
    DB $00,$03,$80,$01,$E0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$3F,$FF
    DB $FF,$FE,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$4D,$33,$26
    DB $22,$41,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$FC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CF,$DC,$80,$FF,$FF,$FF,$07,$30,$E6,$53,$40,$37,$6C,$0C,$90,$27
    DB $C8,$06,$B0,$16,$60,$10,$CC,$62,$04,$30,$FF,$FF,$FF,$01,$0C,$FC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$03,$06,$CC,$31,$F3,$67,$CC,$30,$18,$F9,$B3
    DB $E0,$CC,$63,$67,$C1,$86,$C4,$EC,$9B,$32,$70,$FF,$FF,$FF,$FF,$FF
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$F0,$00,$0F,$C0
    DB $00,$FC,$00,$07,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$FF
    DB $FF,$80,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CF,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$79,$32,$A6
    DB $62,$79,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$EC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CF,$DC,$80,$FF,$FF,$FF,$07,$38,$60,$9B,$40,$37,$60,$05,$90,$27
    DB $58,$06,$F0,$32,$60,$10,$CC,$E2,$04,$30,$FF,$FF,$FF,$01,$0C,$EC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$03,$06,$6F,$33,$1B,$3C,$6C,$3C,$19,$8D,$9E
    DB $30,$78,$63,$3C,$61,$83,$C4,$67,$99,$E2,$30,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$3C,$00,$00,$3F
    DB $FF,$00,$00,$1E,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00
    DB $00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$71,$32,$A6
    DB $62,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$CC
    DB $CC,$DC,$80,$FF,$FF,$FF,$06,$FF,$67,$81,$60,$33,$60,$07,$98,$27
    DB $78,$3E,$B0,$3F,$60,$18,$CC,$63,$06,$30,$FF,$FF,$FF,$01,$0C,$CC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$0F,$00,$00,$00
    DB $00,$00,$00,$78,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00
    DB $00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$41,$32,$66
    DB $26,$09,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$80,$FF,$FF,$FF,$07,$36,$67,$81,$72,$33,$CC,$07,$19,$60
    DB $70,$06,$98,$3F,$7C,$1C,$4C,$33,$96,$60,$FF,$FF,$FF,$01,$0C,$CC
    DB $00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$03,$E7,$CF,$3E,$E3,$E3,$BF,$3C,$1F,$71,$F1
    DB $C0,$F9,$FB,$E3,$81,$E6,$46,$6F,$9B,$E3,$30,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$03,$E0,$00,$00
    DB $00,$00,$03,$E0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00
    DB $00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$41,$E2,$66
    DB $1C,$79,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$0C,$CC
    DB $CC,$DC,$80,$FF,$FF,$FF,$07,$30,$67,$3D,$3E,$38,$8C,$03,$0F,$E0
    DB $30,$06,$98,$61,$7C,$0F,$4C,$31,$F3,$C0,$FF,$FF,$FF,$01,$0C,$CC
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $FF,$FF,$FF,$FF,$FF,$03,$66,$CC,$36,$A3,$62,$8C,$30,$1B,$51,$B1
    DB $40,$CC,$63,$62,$81,$86,$47,$6C,$1B,$33,$B0,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46
    DB $46,$46,$42,$46,$46,$46,$42,$46,$46,$46,$42,$46,$46,$42,$42,$46
    DB $00,$00,$42,$00,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$42,$00,$00
    DB $00,$00,$42,$00,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$42,$00,$00
    DB $00,$00,$42,$00,$00,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$00,$00,$42,$00,$00
    DB $00,$00,$42,$00,$00,$00,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
    DB $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$00,$00,$00,$42,$00,$00
    DB $00,$47,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42
    DB $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$47,$00
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$43
    DB $43,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$45,$43
    DB $43,$45,$45,$43,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$45,$43,$5F
    DB $5F,$43,$00,$45,$45,$43,$00,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$00,$45,$45,$43
    DB $43,$43,$45,$00,$45,$45,$43,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$43,$45,$00,$00,$45,$45,$45
    DB $45,$45,$45,$00,$00,$45,$43,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$43,$45,$00,$00,$45,$45,$45
    DB $45,$45,$43,$43,$00,$45,$43,$43,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$43,$45,$00,$00,$45,$43,$45
    DB $43,$45,$45,$43,$00,$45,$43,$43,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$43,$45,$00,$00,$45,$43,$45
    DB $43,$43,$43,$00,$00,$45,$43,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$00,$00,$43,$43
    DB $43,$43,$00,$00,$45,$45,$43,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$45,$00,$00
    DB $00,$00,$00,$45,$45,$43,$00,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$43,$45,$45,$45
    DB $45,$45,$45,$43,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$43,$43
    DB $43,$43,$43,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$42
    DB $42,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$46,$46
    DB $46,$46,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$43
    DB $42,$42,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
    DB $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$42
    DB $42,$43,$4E,$01,$01,$01,$4E,$71,$71,$71,$4E,$71,$4E,$4E,$4E,$71
    DB $4E,$71,$4E,$4E,$4E,$4E,$71,$4E,$4E,$4E,$01,$01,$01,$4E,$46,$43
    DB $42,$42,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
    DB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$46,$42
    DB $00,$00,$00,$00,$00,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
    DB $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
    DB $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$00,$00,$00,$00,$00
    END
