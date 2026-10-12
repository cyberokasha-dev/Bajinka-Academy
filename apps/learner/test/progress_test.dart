import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/course_content.dart';
import 'package:bajinka_academy/learner_store.dart';
void main() {
  test('empty curriculum cannot award completion or a new record', () async {
    final store = LearnerStore(storage:MemoryStorage());await store.start();
    expect(courseTopics.length,43);expect(courseTopics.every((t)=>!t.ready && t.goal.isEmpty && t.example.isEmpty && t.output.isEmpty),true);expect(exercises,isEmpty);
    await store.setReview('opening-project',true);await store.recordAssessment(100,{});await store.preferences(displayName:'Learner');
    expect(store.requiredCount,0);expect(store.progress,0);expect(store.openingRecordEligible,false);await expectLater(store.issueOpeningRecord(),throwsFormatException);store.dispose();
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

