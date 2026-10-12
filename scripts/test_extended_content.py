import contextlib, io, json, os, re, tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=root/'apps/learner/assets/runner/runner.html'
wrapper=re.search(r'py.runPython\(`([\s\S]*?)`\)',source.read_text()).group(1)
with tempfile.TemporaryDirectory() as workspace:
 wrapper=wrapper.replace('/home/pyodide',workspace).replace("json.dumps({'output':", "_checked = json.dumps({'output':")
 for case in json.loads((root/'scripts/extended_reference_checks.json').read_text()):
  scope={'_academy_request':json.dumps({'code':case['code'],'input':[],'harness':case['harness']})}
  exec(wrapper,scope)
  result=json.loads(scope['_checked']);assert not result['error'],result['error']
  assert result['output'].rstrip()==case['expected'].rstrip(),(case,result)
 for example in json.loads((root/'scripts/extended_example_checks.json').read_text()):
  scope={'_academy_request':json.dumps({'code':example,'input':[],'harness':''})};exec(wrapper,scope)
  result=json.loads(scope['_checked']);assert not result['error'],(example,result['error'])
 os.chdir(root)
print('Extended lesson examples and assignment reference cases passed')
