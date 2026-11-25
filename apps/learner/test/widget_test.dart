import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/main.dart';
import 'package:bajinka_academy/learner_store.dart';

Future<void> openSection(WidgetTester tester, String section) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(section).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard exposes practical workbench tools and no course navigation', (tester) async {
    final store = LearnerStore(storage: MemoryStorage());
    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Bajinka Workbench'), findsWidgets);
    expect(find.text('Python Studio'), findsWidgets);
    expect(find.text('Cybersecurity Lab'), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
    expect(sections, containsAll(['Dashboard', 'Python Studio', 'Cybersecurity Lab', 'Projects', 'Notebook', 'Portfolio', 'My Files']));
    expect(sections, contains('Sources & Acknowledgements'));
    expect(sections, contains('Privacy Policy'));
    expect(sections, isNot(contains('My Course')));
    expect(sections, isNot(contains('Assessments')));
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('projects can be created and stored in the workbench record', (tester) async {
    final store = LearnerStore(storage: MemoryStorage());
    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();

    await openSection(tester, 'Projects');
    await tester.tap(find.text('New project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Python Log Parser');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    await store.pending;

    expect(find.text('Python Log Parser'), findsOneWidget);
    expect(store.draft('workbench-projects')['notes'], contains('Python Log Parser'));
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('cybersecurity notes and checklist selections persist between visits', (tester) async {
    final store = LearnerStore(storage: MemoryStorage());
    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();

    await openSection(tester, 'Cybersecurity Lab');
    await tester.tap(find.text('Internet connection'));
    await tester.enterText(find.byType(TextField).last, 'Reviewed the fictional office network case.');
    await tester.pumpAndSettle();
    await store.pending;

    expect(store.draft('wb-lab')['notes'], 'Reviewed the fictional office network case.');
    expect(store.draft('wb-lab-network-builder')['notes'], contains('Internet connection'));

    await openSection(tester, 'Projects');
    await openSection(tester, 'Cybersecurity Lab');

    final item = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Internet connection'));
    expect(item.value, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField).last).controller?.text, 'Reviewed the fictional office network case.');
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('Python Studio opens its workspace page without course-topic dependencies', (tester) async {
    final store = LearnerStore(storage: MemoryStorage());
    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();

    await openSection(tester, 'Python Studio');
    expect(find.textContaining('This workspace uses Pyodide in a browser worker.'), findsOneWidget);
    expect(find.text('Open Python workspace'), findsOneWidget);
    await tester.tap(find.text('Open Python workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Python Studio'), findsWidgets);
    expect(find.text('The Python runner is available on web and Android.'), findsOneWidget);
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('phone dashboard has no overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = LearnerStore(storage: MemoryStorage());
    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets('My Files accepts and displays a general Python Studio workspace', (tester) async {
    final store = LearnerStore(storage: MemoryStorage());
    await store.start();
    await store.saveFile(
      'workbench-python',
      topicId: 'workbench-python',
      category: 'Project',
      title: 'Workbench script',
      content: 'print("ready")',
    );

    await tester.pumpWidget(AcademyApp(store: store));
    await tester.pumpAndSettle();
    await openSection(tester, 'My Files');

    expect(find.text('workbench-python-project-workbench-script.py'), findsOneWidget);
    expect(find.byTooltip('Download this saved file'), findsOneWidget);
    expect(tester.takeException(), isNull);

  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}
