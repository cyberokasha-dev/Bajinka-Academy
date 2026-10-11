"""Exercise the worker's Python wrapper independently of runtime download."""
import json, re, tempfile
from pathlib import Path
source=Path(__file__).resolve().parents[1]/'apps/learner/assets/runner/runner.html'
wrapper=re.search(r'py.runPython\(`([\s\S]*?)`\)',source.read_text()).group(1)
with tempfile.TemporaryDirectory() as root:
 wrapper=wrapper.replace('/home/pyodide',root).replace("json.dumps({'output':", "_checked = json.dumps({'output':")
 def run(code,inputs=(),harness=''):
  scope={'_academy_request':json.dumps({'code':code,'input':list(inputs),'harness':harness})}
  exec(wrapper,scope)
  return json.loads(scope['_checked'])
 result=run('def double(n):\n    return n*2',harness='print(double(4))')
 assert result['output']=='8\n' and not result['error']
 result=run('print(input("Name: "))',['Amina'])
 assert result['output']=='Amina\n' and result['prompts']==['Name: ']
 assert 'EOFError' in run('input()')['error']
 assert 'NameError' in run('print(missing)')['error']
 assert 'Output limit' in run('print("x" * 20001)')['error']
 run('open("saved.txt", "w").write("one")')
 assert run('import os\nprint(os.path.exists("saved.txt"))')['output']=='False\n'
 # Restore the process working directory before the temporary workspace is removed.
 import os; os.chdir(source.parent)
print('Runner input, harness, error, output-limit and filesystem checks passed')
