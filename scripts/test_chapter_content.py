"""Execute published code activity reference/alternative answers through the real runner wrapper."""
import json,re,tempfile,os,math
from pathlib import Path
root=Path(__file__).resolve().parents[1]
html=(root/'apps/learner/assets/runner/runner.html').read_text()
wrapper=re.search(r'py.runPython\(`([\s\S]*?)`\)',html).group(1)
manifest=json.loads((root/'scripts/chapter_content_checks.json').read_text())
original=Path.cwd();cases=0
with tempfile.TemporaryDirectory() as directory:
 wrapper=wrapper.replace('/home/pyodide',directory).replace("json.dumps({'output':", "_checked=json.dumps({'output':")
 def run(source,test):
  scope={'_academy_request':json.dumps({'code':source,'input':test.get('input',[]),'harness':test.get('harness','')})};exec(wrapper,scope);return json.loads(scope['_checked'])
 def passed(result,test):
  if result['error']:return False
  if test.get('comparison')=='numeric':
   try:return math.isfinite(float(result['output'].strip())) and math.isclose(float(result['output'].strip()),float(test['expected']),rel_tol=0,abs_tol=0.000001)
   except ValueError:return False
  return result['output'].replace('\r\n','\n').rstrip()==test['expected'].replace('\r\n','\n').rstrip()
 for activity in manifest['activities']:
  for source in [activity['reference'],*activity['alternatives']]:
   for test in activity['tests']:
    result=run(source,test);assert passed(result,test),(activity['id'],test,result);cases+=1
  assert not all(passed(run('print("wrong")',test),test) for test in activity['tests']),activity['id']
 for lesson in manifest['lessons']:
  inputs=['  academy  '] if lesson['id']=='python-c0-t3' else []
  result=run(lesson['example'],{'input':inputs});assert not result['error'],(lesson['id'],result)
  if lesson['id']!='python-c0-t3':assert result['output'].rstrip()==lesson['output'].rstrip(),(lesson['id'],result)
 os.chdir(original)
print(f'{len(manifest["lessons"])} lesson examples and {cases} code activity cases passed; incorrect answers rejected.')
