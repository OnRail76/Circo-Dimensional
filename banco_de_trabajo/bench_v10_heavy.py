from pathlib import Path
p=Path(__file__).parent
source=(p/'bench_cycles.py').read_text();source=source[:source.index("post = r'''")]
tail=r'''
run_to_frame(2)
keys={'space'};run_to_frame(4)
keys=set();run_to_frame(8)
mem[labels['score']]=30
for lane in range(5):mem[labels['enemies']+lane]=1
first=frame
for i in range(330):
 # Fast but realistic: fire every 10 frames and alternate slow joystick moves
 keys={'p'} if (i//5)%4==0 else {'o'} if (i//5)%4==2 else {'space'} if i%13==0 else set()
 run_to_frame(frame+1)
 if frame_cycles[-1]>95000 and val('state')==1:
  print('SLOWFRAME',frame,'keys',keys,'cycles',frame_cycles[-1],'bulk',frame_ldir[-1],'player',val('player'),'pending',val('pending_active'),'just',val('just_committed'),'lives',val('lives'),'step_cd',val('step_cd'),'score',val('score'),'hud_prev',val('prev_score'),'enemies',[mem[labels['enemies']+x] for x in range(5)])
 if val('state')!=1:
  break
busy=[(j+1+first,frame_cycles[j],frame_ldir[j]) for j in range(first,len(frame_cycles))]
worst=sorted(busy,key=lambda x:x[1],reverse=True)[:12]
print('HEAVY state',val('state'),'frames',len(busy),'score',val('score'),'lives',val('lives'))
print('PEAK 12',worst)
print('EXCEED 70000',sum(x[1]>70000 for x in busy),'EXCEED 90000',sum(x[1]>90000 for x in busy))
'''
ns={'__file__':str(p/'bench_cycles.py')}
exec(compile(source,str(p/'bench_cycles.py'),'exec'),ns)
exec(compile(ns['src']+tail,str(p/'bench_v10_heavy.py'),'exec'),{'__file__':str(p/'bench_v10_heavy.py')})
