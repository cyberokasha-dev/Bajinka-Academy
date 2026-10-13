import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/course_content.dart';
import 'package:bajinka_academy/learner_store.dart';
class FailingCloud implements DeviceStorage {
  bool fail=true;
  String? saved;
  @override Future<String?> read(String key) async=>saved;
  @override Future<void> write(String key,String value) async {if(fail)throw const FormatException('offline');saved=value;}
}
class SlowCloud implements DeviceStorage {
  final release=Completer<void>();
  final writes=<String>[];
  @override Future<String?> read(String key) async=>null;
  @override Future<void> write(String key,String value) async {writes.add(value);if(writes.length==1)await release.future;}
}
void main() {
  test('four chapters publish independent activities without unlocking a course record', () async {
    final store = LearnerStore(storage:MemoryStorage());await store.start();
    expect(courseTopics.length,43);expect(courseTopics.where((t)=>t.ready).length,22);expect(courseTopics.where((t)=>t.chapter>3).every((t)=>!t.ready),true);expect(exercises.length,176);for(final topic in courseTopics.where((t)=>t.chapter<=3)){for(final category in ['Classwork','Homework','Challenge','Project','Assessment']){expect(forTopic(topic.id,category),isNotEmpty,reason:'${topic.id}: $category');}}expect(exercises.map((e)=>e.id).toSet().length,176);expect(exercises.where((e)=>e.type=='code').every((e)=>e.tests.isNotEmpty),true);
    await store.setReview('opening-project',true);await store.recordAssessment(100,{});await store.preferences(displayName:'Learner');
    expect(store.requiredCount,46);expect(store.progress,0);expect(store.openingRecordEligible,false);await expectLater(store.issueOpeningRecord(),throwsFormatException);store.dispose();
  });
  test('homework code and marking remain tied to their own activity IDs', () async {
    final storage=MemoryStorage();final store=LearnerStore(storage:storage);await store.start();
    final homework=exercises.where((e)=>e.category=='Homework').toList();final a=homework[0],b=homework[1];
    store.edit('activity:${a.id}',code:'my first answer');store.edit('activity:${b.id}',code:'my second answer');await store.pending;
    await store.recordAttempt(a,{'status':'graded','passed':true,'score':100},answer:'my first answer');
    expect(store.passed(a.id),true);expect(store.passed(b.id),false);
    final copy=LearnerStore(storage:storage);await copy.start();expect(copy.draft('activity:${a.id}')['code'],'my first answer');expect(copy.draft('activity:${b.id}')['code'],'my second answer');
    expect(b.tests,isNot(equals(a.tests)));store.dispose();copy.dispose();
  });
  test('saved app files use topic/activity names and restore without mixing workspaces', () async {
    final store=LearnerStore(storage:MemoryStorage());await store.start();
    final home=exercises.firstWhere((e)=>e.category=='Homework');final project=exercises.firstWhere((e)=>e.category=='Project');
    await store.saveFile('activity:${home.id}',topicId:home.topic,category:home.category,title:home.title,content:'homework code');
    await store.saveFile('activity:${project.id}',topicId:project.topic,category:project.category,title:project.title,content:'project code');
    expect(store.files['activity:${home.id}']!['filename'],contains('running-and-saving-python-programs-homework'));
    expect(store.files['activity:${project.id}']!['filename'],contains('project'));expect(store.files.length,2);
    final copy=LearnerStore(storage:MemoryStorage());await copy.start();await copy.restore(store.exportBackup());
    expect(copy.files['activity:${home.id}']!['content'],'homework code');expect(copy.files['activity:${project.id}']!['content'],'project code');
    final older=store.snapshot()..remove('files');LearnerStore.validateBackup(jsonEncode(older));
    store.dispose();copy.dispose();
  });
  test('automatic checks mark only the matching task and award points once', () async {
    expect(exercises.any((e)=>e.type=='written'),false);
    final short=exercises.firstWhere((e)=>e.type=='short');final store=LearnerStore(storage:MemoryStorage());await store.start();
    final accepted=short.accepted.first;expect(gradeAnswer(short,accepted.toUpperCase())['passed'],true);expect(gradeAnswer(short,'unrelated answer')['passed'],false);
    await store.recordAttempt(short,gradeAnswer(short,accepted));await store.recordAttempt(short,gradeAnswer(short,accepted));
    expect(store.passed(short.id),true);expect(store.points,10);expect(store.completedCount,0);store.dispose();
  });
  test('guest notes and code persist across a fresh store', () async {
    final storage = MemoryStorage(); final first = LearnerStore(storage:storage); await first.start();
    first.edit(starterTopics.first.id, notes:'A private explanation',code:'print(42)',input:'test'); await first.pending;
    await first.visit(starterTopics.first.id);
    final second = LearnerStore(storage:storage); await second.start();
    expect(second.draft(starterTopics.first.id)['notes'],'A private explanation');
    expect(second.draft(starterTopics.first.id)['code'],'print(42)'); expect(second.lastTopic,starterTopics.first.id);
    first.dispose();second.dispose();
  });
  test('backup round trip and invalid backup leave current notes intact', () async {
    final first=LearnerStore(storage:MemoryStorage());await first.start();first.edit(starterTopics.first.id,notes:'Original');await first.pending;
    final copy=LearnerStore(storage:MemoryStorage());await copy.start();await copy.restore(first.exportBackup());
    expect(copy.draft(starterTopics.first.id)['notes'],'Original');
    final corrupt=jsonDecode(first.exportBackup()) as Map<String,dynamic>;corrupt['lastTopic']=9;
    await expectLater(copy.restore(jsonEncode(corrupt)),throwsFormatException);
    expect(copy.draft(starterTopics.first.id)['notes'],'Original');
    first.dispose();copy.dispose();
  });
  test('old title-based guest notes migrate without losing work', () async {
    final storage=MemoryStorage();storage.values['academy.guest.v3']=jsonEncode({'name':'Learner','lastTopic':starterTopics.first.title,'drafts':{starterTopics.first.title:{'notes':'Earlier note','code':'print(1)'}}});
    final store=LearnerStore(storage:storage);await store.start();expect(store.draft(starterTopics.first.id)['notes'],'Earlier note');expect(store.lastTopic,starterTopics.first.id);store.dispose();
  });
  test('written answers are review records and short answers have explicit acceptance', () {
    final written=const Exercise(id:'fixture-written',topic:'python-c0-t0',category:'Test',type:'written',title:'',prompt:'');expect(gradeAnswer(written,'save run explain')['status'],'review');expect(gradeAnswer(written,'save run explain')['passed'],false);
    final numeric=const Exercise(id:'fixture-short',topic:'python-c0-t0',category:'Test',type:'short',title:'',prompt:'',accepted:['8']);expect(gradeAnswer(numeric,' 8 ')['passed'],true);expect(gradeAnswer(numeric,'eight')['passed'],false);
  });
  test('shell history stays separate between topic workspaces and survives backup', () async {
    final store=LearnerStore(storage:MemoryStorage());await store.start();
    store.edit(courseTopics[0].id,shellHistory:['value = 7','value']);
    store.edit(courseTopics[1].id,shellHistory:['other = 2']);await store.pending;
    final copy=LearnerStore(storage:MemoryStorage());await copy.start();await copy.restore(store.exportBackup());
    expect(copy.draft(courseTopics[0].id)['shellHistory'],['value = 7','value']);
    expect(copy.draft(courseTopics[1].id)['shellHistory'],['other = 2']);
    final invalid=jsonDecode(store.exportBackup()) as Map<String,dynamic>;
    invalid['drafts'][courseTopics[0].id]['shellHistory']=[42];
    await expectLater(copy.restore(jsonEncode(invalid)),throwsFormatException);
    store.dispose();copy.dispose();
  });
  test('cloud failures remain visibly unsaved and retry saves the open work', () async {
    final storage=FailingCloud();final store=LearnerStore(storage:storage,cloud:true);await store.start();
    store.edit(starterTopics.first.id,notes:'Unsaved cloud note');await store.pending;
    expect(store.saveFailed,true);expect(store.saveStatus,'Unsaved changes');expect(storage.saved,isNull);
    expect(store.draft(starterTopics.first.id)['notes'],'Unsaved cloud note');
    storage.fail=false;await store.save();expect(store.saveFailed,false);expect(store.saveStatus,'Saved to Supabase');
    final restored=LearnerStore(storage:storage,cloud:true);await restored.start();expect(restored.draft(starterTopics.first.id)['notes'],'Unsaved cloud note');
    store.dispose();restored.dispose();
  });
  test('serial cloud saves coalesce later edits without losing the latest snapshot', () async {
    final storage=SlowCloud();final store=LearnerStore(storage:storage,cloud:true);await store.start();
    store.edit(starterTopics.first.id,code:'first');await Future<void>.delayed(Duration.zero);
    store.edit(starterTopics.first.id,code:'second');store.edit(starterTopics.first.id,code:'latest');
    storage.release.complete();await store.pending;
    expect(storage.writes.length,2);expect(jsonDecode(storage.writes.last)['drafts'][starterTopics.first.id]['code'],'latest');expect(store.saveFailed,false);store.dispose();
  });
  test('saved runtime evidence and explicitly empty code survive restore', () async {
    final store=LearnerStore(storage:MemoryStorage());await store.start();
    store.edit(starterTopics.first.id,code:'',lastRun:{'output':'Earlier output','error':'','prompts':<String>[],'code':'print("Earlier output")','recordedAt':DateTime.now().toIso8601String()});await store.pending;
    final copy=LearnerStore(storage:MemoryStorage());await copy.start();await copy.restore(store.exportBackup());
    expect(copy.draft(starterTopics.first.id)['codeEdited'],true);expect(copy.draft(starterTopics.first.id)['code'],'');
    expect((copy.draft(starterTopics.first.id)['lastRun'] as Map)['output'],'Earlier output');
    await copy.clearDeviceRecord();expect(copy.notesCount,0);expect(copy.drafts,isEmpty);expect(copy.attempts,isEmpty);expect(copy.certificates,isEmpty);expect(copy.reminders,false);
    store.dispose();copy.dispose();
  });

}
