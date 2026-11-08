"""Run 26 targeted real-Z80-instruction checks at score boundaries.
Requires test_engine.py's partial Z80 interpreter for instruction-level calls.
"""
from pathlib import Path
P=Path(__file__).parent
ns={'__file__':str(P/'test_engine.py')}
exec(compile((P/'test_engine.py').read_text(),str(P/'test_engine.py'),'exec'),ns)
case=[(0,68,55),(4,68,55),(5,56,46),(9,56,46),(10,45,38),
      (14,45,38),(15,38,32),(19,38,32),(20,31,27),(29,31,27),
      (30,25,23),(70,25,23),(255,25,23)]
for score,spawn,step in case:
 for label,expected in [('spawn_interval',spawn),('step_interval',step)]:
  ns['mem'][ns['labels']['score']]=score
  sentinel=0xFDFC
  ns['push'](sentinel)
  ns['pc']=ns['labels'][label]
  for _ in range(40):
   if ns['pc']==sentinel:break
   opcode=ns['rd']();ns['do'](opcode)
  else:raise AssertionError(f'subroutine did not return: {label}')
  got=ns['r']['a']
  assert got==expected,(score,label,got,expected)
print('PASS: 26 Z80-instruction-level timing tests at 13 scoring thresholds')
