"""Approximate Z80 work per frame, useful to catch regressions; not a Fuse timing benchmark."""
from pathlib import Path
p=Path(__file__).parent
src=(p/'test_engine.py').read_text()
src=src[:src.index('# Real regressions test Z80 instructions')]
src=src.replace('instructions=0;frame=0;keys=set()', 'instructions=0;frame=0;keys=set();tstates=0;total_ldir_bytes=0;frame_cycles=[];frame_ldir=[];last_halt_cycles=0;last_halt_ldir=0')
src=src.replace(' global pc,sp,zf,cf,halted,frame\n if op==0xed:', ' global pc,sp,zf,cf,halted,frame,tstates,total_ldir_bytes,last_halt_cycles,last_halt_ldir\n tstates+=9\n if op==0xed:')
src=src.replace('n=bc();src=hl();dst=de();mem[dst:dst+n]', 'n=bc();tstates+=max(0,n*21-14);total_ldir_bytes+=n;src=hl();dst=de();mem[dst:dst+n]')
src=src.replace('if op==0x76:halted+=1;frame+=1;return','if op==0x76:\n  halted+=1;frame+=1;frame_cycles.append(tstates-last_halt_cycles);frame_ldir.append(total_ldir_bytes-last_halt_ldir);last_halt_cycles=tstates;last_halt_ldir=total_ldir_bytes;return')
post = r'''
run_to_frame(2)
keys={'space'};run_to_frame(4)
keys=set()
# steady-state with five active enemies and sudden simultaneous advances
for i in range(5):mem[labels['enemies']+i]=1
run_to_frame(6)
print('FIVE SPAWN approx cycles',frame_cycles[-1],'bulk bytes',total_ldir_bytes)
for i in range(5):mem[labels['enemies']+i]=2
run_to_frame(7)
print('FIVE MOVE approx cycles',frame_cycles[-1],'bulk bytes',total_ldir_bytes)
run_to_frame(8)
print('IDLE approx cycles',frame_cycles[-1])
print('ALL FRAME APPROX',list(enumerate(zip(frame_cycles,frame_ldir),start=1)))
print('MAX',max(frame_cycles[4:]),'last frames',frame_cycles[-5:])
'''
src+=post
exec(compile(src,str(p/'bench_cycles.py'),'exec'),{'__file__':str(p/'bench_cycles.py')})
