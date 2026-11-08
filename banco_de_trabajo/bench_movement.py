from pathlib import Path
p=Path(__file__).parent
src=(p/'bench_cycles.py').read_text()
start=src.index('post = r\'\'\'')
src=src[:start]+"""post = r'''
run_to_frame(2)
keys={'space'};run_to_frame(4)
keys=set();run_to_frame(10)
print('BASELINE',frame_cycles[-1],frame_ldir[-1]);
for n,k in enumerate(['p','p','p','p','p','p','p','p','o','o','o','o','o','o','o','o']):
 keys={k};run_to_frame(11+n)
 print('MOVE',n+1, k,mem[labels['player']], 'cycles',frame_cycles[-1], 'bytes',frame_ldir[-1])
'''
src+=post
exec(compile(src,str(p/'bench_movement.py'),'exec'),{'__file__':str(p/'bench_movement.py')})
"""
exec(compile(src,str(p/'bench_movement.py'),'exec'),{'__file__':str(p/'bench_movement.py')})
