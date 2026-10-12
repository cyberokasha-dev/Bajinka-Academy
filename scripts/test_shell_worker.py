"""Verify persistent shell semantics without downloading the browser runtime."""
import asyncio, re
from pathlib import Path
source=Path(__file__).resolve().parents[1]/'apps/learner/assets/runner/runner.html'
text=source.read_text().split('id="shell-worker-source">',1)[1].split('</script>',1)[0]
wrapper=re.search(r'py.runPython\(`([\s\S]*?)`\)',text).group(1).replace('\\\\n','\\n')
import tempfile, os
original=Path.cwd()
with tempfile.TemporaryDirectory() as directory:
 output=[];responses=[];prompts=[]
 async def read(prompt):
  prompts.append(prompt)
  return responses.pop(0)
 class Inputs(list):
  def to_py(self):return list(self)
 scope={'_academy_emit':output.append,'_academy_read':read}
 exec(wrapper.replace('/home/pyodide/academy-shell',directory),scope)
 def command(line,inputs=()):
  scope['_academy_line']=line;scope['_academy_inputs']=Inputs(inputs)
  return asyncio.run(scope['_academy_execute']())
 assert command('amount = 7') is False
 command('amount * 3');assert ''.join(output)=='21\n'
 output.clear();assert command('for i in range(2):') is True
 assert command('    print(i)') is True
 assert command('') is False;assert ''.join(output)=='0\n1\n'
 responses.append('Bajinka');command('name = input("Name: ")');command('name')
 assert prompts==['Name: '] and scope['_scope']['name']=='Bajinka'
 # Input is requested at execution time, so a loop can ask for each value.
 responses.extend(['4','5']);command('for i in range(2):');command('    print(input("Value: "))');command('')
 assert prompts[-2:]==['Value: ','Value: '] and '4\n5\n' in ''.join(output)
 output.clear();command('missing_name');assert 'NameError' in ''.join(output)
 output.clear();command('if )');assert 'SyntaxError' in ''.join(output)
 command('amount');assert ''.join(output).endswith('7\n')
 command('def read_value():');command('    return input("Function: ")');command('')
 command('read_value()',['queued']);assert ''.join(output).endswith("Function: 'queued'\n")
 os.chdir(original)
print('Shell persistence, blocks, interactive top-level input, tracebacks and function input checks passed')
