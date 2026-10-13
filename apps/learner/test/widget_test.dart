import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/main.dart';
import 'package:bajinka_academy/learner_store.dart';
void main() {
  testWidgets('published loop lessons and workspaces remain available', (tester) async {
    await tester.pumpWidget(AcademyApp(store:LearnerStore(storage:MemoryStorage())));await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open my course →'));await tester.tap(find.text('Open my course →'));await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('chapter-2')));await tester.tap(find.byKey(const ValueKey('chapter-2')));await tester.pumpAndSettle();
    expect(find.text('while loops and termination'),findsOneWidget);
    await tester.ensureVisible(find.text('while loops and termination'));await tester.tap(find.text('while loops and termination'));await tester.pumpAndSettle();
    expect(find.text('Lesson awaiting authoring'),findsNothing);expect(find.text('Try it in the Python terminal'),findsOneWidget);expect(find.text('My Notes'),findsOneWidget);expect(tester.takeException(),isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets('guest can save a note without login', (tester) async {
    final store=LearnerStore(storage:MemoryStorage());await tester.pumpWidget(AcademyApp(store:store));await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume your last topic →'));await tester.tap(find.text('Resume your last topic →'));await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My Notes'));await tester.tap(find.text('My Notes'));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),'My own explanation');await tester.pumpAndSettle();expect(store.draft('python-c0-t0')['notes'],'My own explanation');expect(find.text('Saved on this device'),findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets('phone dashboard has no overflow', (tester) async {
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AcademyApp(store:LearnerStore(storage:MemoryStorage())));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets('assessment lists the fourteen published topic banks', (tester) async {
    await tester.pumpWidget(AcademyApp(store:LearnerStore(storage:MemoryStorage())));await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));await tester.pumpAndSettle();
    await tester.tap(find.text('Assessments'));await tester.pumpAndSettle();
    expect(find.byType(TextFormField),findsNothing);
    expect(find.text('Topic knowledge checks'),findsOneWidget);expect(find.text('Comparisons and Boolean values'),findsOneWidget);
    expect(tester.takeException(),isNull);
  }, variant:TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets('a published topic opens its own homework and assessment tabs', (tester) async {
    await tester.pumpWidget(AcademyApp(store:LearnerStore(storage:MemoryStorage())));await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Resume your last topic →'));await tester.tap(find.text('Resume your last topic →'));await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Homework'));await tester.tap(find.text('Homework'));await tester.pumpAndSettle();
    expect(find.text('Environment greeting'),findsOneWidget);expect(find.text('Three configuration values'),findsNothing);
    await tester.ensureVisible(find.text('Assessment'));await tester.tap(find.text('Assessment'));await tester.pumpAndSettle();
    expect(find.text('Source-file convention'),findsOneWidget);expect(find.text('Closing a shell'),findsOneWidget);expect(tester.takeException(),isNull);
  },variant:TargetPlatformVariant({TargetPlatform.linux}));
  testWidgets('My Files displays the named saved version without a download action', (tester) async {
    final store=LearnerStore(storage:MemoryStorage());
    // The save queue schedules an event-loop task; run it outside the widget fake clock.
    await tester.runAsync(() async {
      await store.start();
      await store.saveFile('python-c0-t0',topicId:'python-c0-t0',category:'Practice',title:'',content:'print(7)');
    });
    await tester.pumpWidget(AcademyApp(store:store));await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));await tester.pumpAndSettle();await tester.tap(find.text('My Files'));await tester.pumpAndSettle();
    expect(find.text('running-and-saving-python-programs-practice.py'),findsOneWidget);expect(find.byTooltip('Download this saved file'),findsOneWidget);expect(tester.takeException(),isNull);
  },variant:TargetPlatformVariant({TargetPlatform.linux}));

}
