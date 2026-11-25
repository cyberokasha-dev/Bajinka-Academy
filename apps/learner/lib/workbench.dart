import 'dart:convert';
import 'package:flutter/material.dart';
import 'learner_store.dart';

const _teal = Color(0xff0eaaa7);
const _projectsKey = 'workbench-projects';
List<Map<String,dynamic>> _projects(LearnerStore s) {
  try { final raw=s.draft(_projectsKey)['notes'] as String? ?? ''; if(raw.isEmpty)return []; return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList(); } catch (_) { return []; }
}
void _saveProjects(LearnerStore s,List<Map<String,dynamic>> p){s.edit(_projectsKey,notes:jsonEncode(p),revision:'project-${DateTime.now().microsecondsSinceEpoch}');s.save();}

class WorkbenchDashboard extends StatelessWidget {
 const WorkbenchDashboard({super.key,required this.store,required this.onOpen});
 final LearnerStore store; final ValueChanged<String> onOpen;
 @override Widget build(BuildContext c){final p=_projects(store);return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('Bajinka Workbench',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),
 const SizedBox(height:8),const Text('Build software, investigate defensive security scenarios, document your work and prepare a portfolio.',style:TextStyle(height:1.5)),
 const SizedBox(height:22),Wrap(spacing:12,runSpacing:12,children:[_metric('Projects','${p.length}'),_metric('In progress','${p.where((x)=>x['status']!='Completed').length}')]),
 const SizedBox(height:20),_launch(c,'Python Studio','Open your saved browser-based Python workspace.',Icons.code,()=>onOpen('Python Studio')),
 _launch(c,'Cybersecurity Lab','Practise defensive network design, SOC triage, email review and incident response.',Icons.security,()=>onOpen('Cybersecurity Lab')),
 _launch(c,'Projects','Manage objectives, status, technologies and repository links.',Icons.folder_open,()=>onOpen('Projects')),
 _launch(c,'Portfolio','Review completed work and evidence.',Icons.workspaces_outline,()=>onOpen('Portfolio')),
 const SizedBox(height:18),const Text('Recent projects',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
 if(p.isEmpty)const Text('No projects yet. Create your first project in Projects.'),
 for(final x in p.take(4))ListTile(contentPadding:EdgeInsets.zero,title:Text(x['title']??'Untitled'),subtitle:Text('${x['category']} • ${x['status']}'))
 ]);}
 Widget _metric(String t,String v)=>Container(width:150,padding:const EdgeInsets.all(16),decoration:BoxDecoration(border:Border.all(color:Colors.grey.shade300),borderRadius:BorderRadius.circular(8)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(v,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),Text(t)]));
 Widget _launch(BuildContext c,String t,String d,IconData i,VoidCallback f)=>Card(elevation:0,child:ListTile(leading:Icon(i,color:_teal),title:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(d),trailing:const Icon(Icons.chevron_right),onTap:f));
}

class PythonStudioHome extends StatelessWidget {
 const PythonStudioHome({super.key,required this.store,required this.onLaunch});
 final LearnerStore store; final VoidCallback onLaunch;
 @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('Python Studio',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:10),
 const Text('This workspace uses Pyodide in a browser worker. It is not a Linux shell or unrestricted desktop Python. Only packages compatible with the Pyodide runtime can run here.',style:TextStyle(height:1.5)),
 const SizedBox(height:16),FilledButton.icon(onPressed:onLaunch,icon:const Icon(Icons.terminal),label:const Text('Open Python workspace')),
 const SizedBox(height:16),Text('Save status: ${store.saveStatus}'),
 const Text('Runtime boundaries',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
 const Text('• Python executes in the browser worker.\n• Native operating-system commands are unavailable.\n• Package compatibility depends on Pyodide wheels.\n• A separate isolated execution service is required for general desktop Python.')
 ]);
}

class ProjectManager extends StatefulWidget {
 const ProjectManager({super.key,required this.store});final LearnerStore store;
 @override State<ProjectManager> createState()=>_ProjectManagerState();
}
class _ProjectManagerState extends State<ProjectManager>{
 String filter='All';
 Future<void> edit([Map<String,dynamic>? old])async{
 final title=TextEditingController(text:old?['title']??'');final objective=TextEditingController(text:old?['objective']??'');final tech=TextEditingController(text:old?['technologies']??'');final url=TextEditingController(text:old?['url']??'');
 String category=old?['category']??'Python',status=old?['status']??'Idea';
 final r=await showDialog<Map<String,dynamic>>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(old==null?'New project':'Edit project'),content:SizedBox(width:450,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
 TextField(controller:title,decoration:const InputDecoration(labelText:'Project title')),
 TextField(controller:objective,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Objective')),
 TextField(controller:tech,decoration:const InputDecoration(labelText:'Skills and technologies')),
 TextField(controller:url,decoration:const InputDecoration(labelText:'GitHub / demo URL')),
 DropdownButtonFormField(value:category,decoration:const InputDecoration(labelText:'Category'),items:['Python','Cybersecurity','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>category=v??'Other')),
 DropdownButtonFormField(value:status,decoration:const InputDecoration(labelText:'Status'),items:['Idea','Planning','Building','Testing','Completed'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>status=v??'Idea'))
 ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,{'title':title.text.trim(),'objective':objective.text.trim(),'technologies':tech.text.trim(),'url':url.text.trim(),'category':category,'status':status}),child:const Text('Save'))])));
 title.dispose();objective.dispose();tech.dispose();url.dispose();
 if(r==null||r['title'].isEmpty)return;final p=_projects(widget.store);
 if(old==null){p.insert(0,{'id':DateTime.now().microsecondsSinceEpoch.toString(),...r});}else{final i=p.indexWhere((x)=>x['id']==old['id']);if(i>=0)p[i]={...p[i],...r};}
 _saveProjects(widget.store,p);if(mounted)setState((){});
 }
 @override Widget build(BuildContext c){final all=_projects(widget.store);final shown=all.where((p)=>filter=='All'||p['category']==filter).toList();return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 Row(children:[const Expanded(child:Text('Projects',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold))),FilledButton.icon(onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('New project'))]),
 const SizedBox(height:8),const Text('Track practical work from idea to tested result. Records save in your existing account workspace.'),
 Wrap(spacing:8,children:['All','Python','Cybersecurity','Other'].map((v)=>ChoiceChip(label:Text(v),selected:filter==v,onSelected:(_)=>setState(()=>filter=v)).toList()),
 if(shown.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('No projects yet.')),
 for(final p in shown)Card(elevation:0,child:ListTile(title:Text(p['title']??''),subtitle:Text('${p['category']} • ${p['status']}\n${p['objective']??''}\n${p['technologies']??''}'),isThreeLine:true,onTap:()=>edit(p),trailing:PopupMenuButton(onSelected:(v){if(v=='edit')edit(p);if(v=='delete'){final list=_projects(widget.store)..removeWhere((x)=>x['id']==p['id']);_saveProjects(widget.store,list);setState((){});}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])))
 ]);}
}

class CybersecurityLab extends StatefulWidget{
 const CybersecurityLab({super.key,required this.store});final LearnerStore store;
 @override State<CybersecurityLab> createState()=>_CybersecurityLabState();
}
class _CybersecurityLabState extends State<CybersecurityLab>{
 String lab='Network Builder';final checked=<String>{};late final TextEditingController notes;
 static const Map<String,List<String>> tasks={
 'Network Builder':['Internet connection','Router','Firewall','Managed switch','Wireless access point','Staff workstation','Guest device','Backup server'],
 'SOC Investigation':['Preserve synthetic log evidence','Identify affected asset','Build event timeline','Separate facts from assumptions','Recommend defensive containment','Write incident summary'],
 'Email Investigation':['Check sender address and domain','Compare displayed sender with actual address','Inspect link destination without opening it','Check for urgency or sensitive-data requests','Record indicators and report decision'],
 'Firewall Simulator':['Allow only required outbound services','Block unsolicited inbound traffic','Separate guest and staff networks','Restrict administration to management devices','Enable appropriate logging'],
 'Incident Response':['Record report and time','Identify affected assets','Preserve logs and evidence','Plan authorised containment','Recover from known-good state','Document lessons learned'],
 'Security Audit':['Identify unsupported software','Review administrator access','Check backup and restore testing','Review multi-factor authentication','Check network segmentation','Prioritise remediation']
 };
 @override void initState(){super.initState();notes=TextEditingController(text:widget.store.draft('wb-lab')['notes'] as String? ?? '');}
 @override void dispose(){notes.dispose();super.dispose();}
 void save(){widget.store.edit('wb-lab',notes:notes.text,revision:'lab-${DateTime.now().microsecondsSinceEpoch}');widget.store.save();}
 @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('Cybersecurity Lab',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:8),
 const Text('Fictional, local defensive simulations. No external systems are contacted and no real credentials or targets are used.'),
 DropdownButtonFormField(value:lab,decoration:const InputDecoration(labelText:'Select a lab'),items:tasks.keys.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>lab=v??'Network Builder')),
 const SizedBox(height:12),Text(lab,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 for(final t in tasks[lab]!)CheckboxListTile(dense:true,contentPadding:EdgeInsets.zero,value:checked.contains(t),title:Text(t),onChanged:(v)=>setState(()=>v==true?checked.add(t):checked.remove(t))),
 const SizedBox(height:12),const Text('Case notes',style:TextStyle(fontWeight:FontWeight.bold)),
 TextField(controller:notes,minLines:5,maxLines:10,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'Record observations, evidence, decisions and recommendations...'),onChanged:(_)=>save()),
 Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:save,icon:const Icon(Icons.save),label:const Text('Save notes'))),
 Text('Checklist: ${checked.length}/${tasks[lab]!.length} completed')
 ]);
}

class PortfolioHome extends StatelessWidget{
 const PortfolioHome({super.key,required this.store});final LearnerStore store;
 @override Widget build(BuildContext c){final completed=_projects(store).where((p)=>p['status']=='Completed').toList();return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('Portfolio',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:8),
 const Text('Private-first showcase of practical work. Review every project and remove private information before sharing externally.'),
 Text('${completed.length} completed projects',style:const TextStyle(fontWeight:FontWeight.bold)),
 if(completed.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Mark a project Completed to list it here.')),
 for(final p in completed)ListTile(leading:const Icon(Icons.verified_outlined,color:_teal),title:Text(p['title']??''),subtitle:Text('${p['category']} • ${p['technologies']??''}')),
 const SizedBox(height:18),const Text('Certificates and evidence',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 const Text('Secure certificate uploads, issuer/date metadata and verification links are not implemented yet. Internal project milestones are not accredited qualifications. Visibility is private by default.')
 ]);}
}

class CareerHub extends StatelessWidget{
 const CareerHub({super.key});
 @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Text('Career Hub',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
 const Text('Career preparation tools planned for this workbench.'),
 for(final x in const [
 ['CV Builder','Organise education, skills and genuine project evidence.'],
 ['Cover Letter Builder','Draft role-specific applications from the job description.'],
 ['Apprenticeship Tracker','Track employer, role, deadline and application status.'],
 ['Interview Preparation','Practise explaining projects and troubleshooting decisions.'],
 ['Certification Roadmap','Compare prerequisites, recognition and costs before enrolling.']
 ])Card(elevation:0,child:ListTile(leading:const Icon(Icons.work_outline,color:_teal),title:Text(x[0]),subtitle:Text(x[1]),trailing:const Text('Planned')))
 ]);
}
