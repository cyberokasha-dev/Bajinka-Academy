import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/course_content.dart';
import 'package:bajinka_academy/learner_store.dart';
void main() {
  test('optional work and visits do not inflate required completion', () async {
    final store = LearnerStore(storage: MemoryStorage()); await store.start();
    await store.mark(starterTopics.first.id, 'reviewed', true);
    expect(store.completedCount, 0);
    final optional = exercises.firstWhere((e) => !e.required && e.type == 'code');
    await store.recordAttempt(optional, {'status':'graded','passed':true,'score':100});
    expect(store.completedCount, 0);
    final required = exercises.firstWhere((e) => e.required);
    await store.recordAttempt(required, {'status':'graded','passed':true,'score':100});
    await store.recordAttempt(required, {'status':'graded','passed':true,'score':100});
    expect(store.completedCount, 1); expect(store.points, 20); expect(store.openingRecordEligible, false);
    store.dispose();
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
    final written=exercises.firstWhere((e)=>e.type=='written');expect(gradeAnswer(written,'save run explain')['status'],'review');expect(gradeAnswer(written,'save run explain')['passed'],false);
    final numeric=exercises.firstWhere((e)=>e.type=='short');expect(gradeAnswer(numeric,' 8 ')['passed'],true);expect(gradeAnswer(numeric,'eight')['passed'],false);
  });
  test('help disclosure persists and cannot be cleared by runner result', () async {
    final storage=MemoryStorage();final first=LearnerStore(storage:storage);await first.start();
    final exercise=exercises.firstWhere((e)=>e.type=='code');
    first.edit('activity:${exercise.id}',helpUsed:true);await first.pending;
    final second=LearnerStore(storage:storage);await second.start();
    await second.recordAttempt(exercise,{'status':'graded','passed':true,'score':100,'helpUsed':false});
    expect(second.attempts[exercise.id]!.last['helpUsed'],true);
    first.dispose();second.dispose();
  });
  test('opening record gates issuance and preserves details on re-download', () async {
    final store=LearnerStore(storage:MemoryStorage());await store.start();
    await expectLater(store.issueOpeningRecord(),throwsFormatException);
    for(final e in exercises.where((e)=>e.required)){await store.recordAttempt(e,{'status':'graded','passed':true,'score':100});}
    await store.setReview('opening-project',true);await store.recordAssessment(100,{});
    await expectLater(store.issueOpeningRecord(),throwsFormatException);
    await store.preferences(displayName:'Learner One');final first=await store.issueOpeningRecord();
    await store.preferences(displayName:'Learner Two');await store.setReview('opening-project',false);
    final second=await store.issueOpeningRecord();
    expect(second['id'],first['id']);expect(second['issuedAt'],first['issuedAt']);expect(second['name'],'Learner One');
    expect(store.certificates.length,1);expect(store.fullCourseEligible,false);store.dispose();
  });

}
