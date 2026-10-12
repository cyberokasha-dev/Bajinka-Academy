// Verify the actual runner routes Run, Save in app and Download independently.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(require('node:path').join(__dirname,'../apps/learner/assets/runner/runner.html'),'utf8');
const elements=new Map();
function element(id){if(!elements.has(id))elements.set(id,{value:'',textContent:'',selectionStart:0,selectionEnd:0,scrollTop:0,scrollHeight:0,style:{},children:[],addEventListener(){},setAttribute(){},focus(){},replaceChildren(){this.children=[];},append(node){this.children.push(node);}});return elements.get(id);}
for(const id of ['worker-source','shell-worker-source'])element(id).textContent=html.split(`id="${id}">`)[1].split('</script>')[0];
const sent=[],workers=[];
class Worker{constructor(){workers.push(this);}postMessage(data){this.request=data;}terminate(){this.terminated=true;}}
const context={document:{getElementById:element,createElement:()=>element('case-'+Math.random()),body:{dataset:{},classList:{toggle(){}}}},window:{AcademyBridge:{postMessage:payload=>sent.push(JSON.parse(payload))},addEventListener(){}},parent:{},location:{origin:'https://academy.example'},Worker,URL:{createObjectURL:()=>'',revokeObjectURL(){}},Blob:class{},setTimeout:()=>1,clearTimeout(){},console,compareOutput:require('../apps/learner/assets/runner/marking.js').compareOutput};
vm.createContext(context);for(const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g))vm.runInContext(match[1],context);
context.window.academyInit({workspaceId:'activity:homework-a',activityId:'homework-a',category:'Homework',activityTitle:'A',filename:'topic-homework-a.py',code:'print(7)',tests:[{expected:'7'},{expected:'8'}]});
element('run').onclick();assert.equal(workers.at(-1).request.cases.length,2);assert.ok(!sent.some(m=>['download','save-file'].includes(m.type)));
workers.at(-1).onmessage({data:{kind:'done',results:[{output:'7\n',error:'',prompts:[]},{output:'8\n',error:'',prompts:[]}]}});
assert.equal(sent.at(-1).type,'result');assert.equal(sent.at(-1).workspaceId,'activity:homework-a');assert.equal(sent.at(-1).result.passed,true);
element('save-file').onclick();assert.equal(sent.at(-1).type,'save-file');assert.equal(sent.at(-1).code,'print(7)');assert.ok(!sent.some(m=>m.type==='download'));
element('download').onclick();assert.equal(sent.at(-1).type,'download');
context.window.academyInit({workspaceId:'activity:homework-b',activityId:'homework-b',category:'Project',revision:'new',filename:'topic-project-b.py',code:'print(7)',tests:[{expected:'99'}]});
element('run').onclick();assert.equal(workers.at(-1).request.cases[0].expected,'99');workers.at(-1).onmessage({data:{kind:'done',results:[{output:'7\n',error:'',prompts:[]}]}});
assert.equal(sent.at(-1).workspaceId,'activity:homework-b');assert.equal(sent.at(-1).result.passed,false);
console.log('Run auto-check, per-activity tests, in-app Save and explicit-only Download checks passed.');
