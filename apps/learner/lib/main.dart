import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course_content.dart';
import 'learner_store.dart';
import 'files_and_records.dart';
import 'platform/runner.dart';
import 'platform/notifications.dart';

SemanticsHandle? accessibility;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  accessibility = SemanticsBinding.instance.ensureSemantics();
  runApp(const AcademyApp());
}
const teal = Color(0xff0eaaa7), navy = Color(0xff1e2e52), border = Color(0xffe0e3eb);
ThemeData academyTheme(bool dark) {
  final base = ThemeData(useMaterial3: true, brightness: dark ? Brightness.dark : Brightness.light, fontFamily: 'Arial', colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: dark ? Brightness.dark : Brightness.light).copyWith(primary: teal, surface: dark ? const Color(0xff172033) : Colors.white));
  return base.copyWith(scaffoldBackgroundColor: dark ? const Color(0xff101827) : const Color(0xfffbfcfd), textTheme: base.textTheme.apply(bodyColor: dark ? const Color(0xffe2e8f0) : navy, displayColor: dark ? Colors.white : navy), dividerColor: dark ? const Color(0xff334155) : border,
    appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xff101827) : const Color(0xfffbfcfd), foregroundColor: dark ? Colors.white : navy, elevation: 0, surfaceTintColor: Colors.transparent),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
  );
}
class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key, this.store});
  final LearnerStore? store;
  @override Widget build(BuildContext context) => MaterialApp(title: 'Bajinka Python Academy', debugShowCheckedModeBanner: false, theme: academyTheme(false), home: LearnerShell(store: store));
}
const sections = ['Home', 'My Course', 'Practice and Homework', 'Projects', 'Notebook', 'Assessments', 'Progress', 'Revision', 'Achievements and Certificates', 'Resources', 'Settings', 'Sources & Acknowledgements', 'Privacy Policy'];
const sectionIcons = [Icons.dashboard_outlined, Icons.menu_book_outlined, Icons.edit_note, Icons.folder_outlined, Icons.description_outlined, Icons.fact_check_outlined, Icons.insights_outlined, Icons.refresh, Icons.workspace_premium_outlined, Icons.link, Icons.settings_outlined, Icons.info_outline, Icons.privacy_tip_outlined];
class LearnerShell extends StatefulWidget {
  const LearnerShell({super.key, this.store});
  final LearnerStore? store;
  @override State<LearnerShell> createState() => _LearnerShellState();
}
class _LearnerShellState extends State<LearnerShell> {
  final scaffold = GlobalKey<ScaffoldState>();
  final scroll = ScrollController();
  late final LearnerStore store;
  String section = 'Home', tab = 'Learn', search = '';
  Topic? topic;
  int? selectedChapter;
  final expandedChapters = <int>{0};
  final note = TextEditingController();
  final nameController = TextEditingController();
  final assessmentAnswers = <String, String>{};
  bool assessmentSubmitted = false;
  @override void initState() {
    super.initState(); store = widget.store ?? LearnerStore(); store.addListener(refresh); unawaited(store.start().then((_) async { if (store.reminders) await resumeReminders(); }));
  }
  void refresh() { if (mounted) setState(() {}); }
  void select(String value) { setState(() { section = value; topic = null; selectedChapter = null; }); if (scroll.hasClients) scroll.jumpTo(0); }
  void openTopic(Topic value, {String activeTab = 'Learn'}) {
    setState(() { section = 'My Course'; topic = value; selectedChapter = value.chapter; tab = activeTab; note.text = store.draft(value.id)['notes'] as String? ?? ''; });
    unawaited(store.visit(value.id)); if (scroll.hasClients) scroll.jumpTo(0);
  }
  Future<void> action(Future<void> Function() task, {String? success}) async {
    try { await task(); if (mounted && success != null) toast(success); } catch (e) { if (mounted) toast('Could not finish: ${e is FormatException ? e.message : 'please try again.'}'); }
  }
  void toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  Color get muted => store.dark ? const Color(0xffaab7cd) : const Color(0xff69758e);
  Widget surface(Widget child, {double padding = 24}) => Container(width: double.infinity, padding: EdgeInsets.all(padding), decoration: BoxDecoration(color: store.dark ? const Color(0xff172033) : Colors.white, border: Border.all(color: store.dark ? const Color(0xff334155) : border), borderRadius: BorderRadius.circular(6)), child: child);
  Widget heading(String text) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)));
  Widget panel(String title, String body, {VoidCallback? onTap, String label = 'Open', IconData? icon}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [if (icon != null) ...[Icon(icon, size: 22, color: teal), const SizedBox(width: 12)], Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)))]), const SizedBox(height: 12), Text(body, style: const TextStyle(height: 1.6)), if (onTap != null) Padding(padding: const EdgeInsets.only(top: 8), child: TextButton(onPressed: onTap, child: Text(label)))])));
  Widget metric(String title, int value) => SizedBox(width: 170, child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text(title, style: TextStyle(color: muted))])));
  Widget home() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    heading('Welcome back${store.name.isEmpty ? '' : ', ${store.name}'}'),
    Text('Your private Python study space. Learn at your own pace — no deadlines, no streak penalties.', style: TextStyle(fontSize: 16, color: muted)), const SizedBox(height: 28),
    panel('Continue learning', store.lastTopic == null ? starterTopics.first.title : topicById(store.lastTopic!).title, icon: Icons.school_outlined, onTap: () => openTopic(store.lastTopic == null ? starterTopics.first : topicById(store.lastTopic!)), label: 'Resume your last topic →'),
    const SizedBox(height: 16), surface(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Python Foundations: Independent Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('Expanded lessons and practice • full-course assessment in development', style: TextStyle(fontSize: 12, color: muted)), const SizedBox(height: 20), const Text('Your progress'), const SizedBox(height: 8), LinearProgressIndicator(value: store.progress, minHeight: 8, backgroundColor: store.dark ? const Color(0xff334155) : const Color(0xffeef2f6), borderRadius: BorderRadius.circular(8)), const SizedBox(height: 8), Text('${store.completedCount}/${store.requiredCount} required starter activities passed local checks', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: muted)), Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => select('My Course'), child: const Text('Open my course →'))),
    ])), const SizedBox(height: 28), const Text('Learning record', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 16),
    Wrap(spacing: 16, runSpacing: 12, children: [metric('Topics viewed', store.countStage('viewed')), metric('Activities attempted', exercises.where((e)=>store.attempts[e.id]?.isNotEmpty == true).length), metric('Topic notes', store.notesCount), metric('Points', store.points)]),
    if (store.weak.isNotEmpty) panel('Your revision queue', '${store.weak.length} topics to revisit. Resolve a topic after reviewing its example and explaining it in your own words.', onTap: () => select('Revision'), label: 'Review topics →'),
    const SizedBox(height: 24), Text('Notes, drafts, attempts and progress save on this device. Download a backup to move them to another browser or phone.', style: TextStyle(color: muted, height: 1.5)),
  ]);
  Widget course() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('My Course'), panel('Python Foundations: Independent Study', 'Every topic has a lesson, runnable example and independent practice. Full-course assessments are still being prepared.'), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Find a topic', border: OutlineInputBorder()), onChanged: (value) => setState(() { search = value.toLowerCase(); })), const SizedBox(height: 20),
    for (var i = 0; i < chapters.length; i++) if (search.isEmpty || courseTopics.any((t) => t.chapter == i && t.title.toLowerCase().contains(search))) ...[
      Semantics(button: true, label: '${chapters[i]} chapter', child: InkWell(key: ValueKey('chapter-$i'), onTap: () => setState(() { if (!expandedChapters.add(i)) expandedChapters.remove(i); }), child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(children: [SizedBox(width: 32, child: Text('$i.', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: muted))), Expanded(child: Text(chapters[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), Text(courseTopics.any((t)=>t.chapter==i&&t.ready) ? 'LESSONS' : 'DRAFT', style: TextStyle(fontSize: 9, letterSpacing: 1, color: muted)), const SizedBox(width: 12), Icon(expandedChapters.contains(i) || search.isNotEmpty ? Icons.expand_less : Icons.expand_more, size: 20)])))),
      if (expandedChapters.contains(i) || search.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 12), child: Container(decoration: const BoxDecoration(border: Border(left: BorderSide(color: border))), child: Column(children: [for (final t in courseTopics.where((t) => t.chapter == i && (search.isEmpty || t.title.toLowerCase().contains(search)))) ListTile(dense: true, minLeadingWidth: 12, leading: Icon(store.draft(t.id)['viewed'] == true ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 16, color: store.draft(t.id)['viewed'] == true ? teal : muted), title: Text(t.title, style: const TextStyle(fontSize: 14)), subtitle: t.ready ? null : const Text('Draft outline • lesson awaiting authoring', style: TextStyle(fontSize: 11)), onTap: () => openTopic(t))]))),
    ], if (search.isNotEmpty && !courseTopics.any((t) => t.title.toLowerCase().contains(search))) panel('No matching topic', 'Try another word.'),
  ]);
  Widget progressStrip() => surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('YOUR PROGRESS', style: TextStyle(fontSize: 11, letterSpacing: .8, color: muted)), const SizedBox(height: 12), Wrap(spacing: 22, runSpacing: 12, children: [
    for (final stage in ['viewed','practised','reviewed']) Semantics(button: true, toggled: store.draft(topic!.id)[stage] == true, child: InkWell(onTap: stage == 'viewed' ? null : () => store.mark(topic!.id, stage, store.draft(topic!.id)[stage] != true), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(store.draft(topic!.id)[stage] == true ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 16, color: teal), const SizedBox(width: 7), Text(stage == 'reviewed' ? 'Self-reviewed' : stage == 'viewed' ? 'Viewed' : 'Practised', style: TextStyle(fontSize: 12, color: muted))]))),
    Row(mainAxisSize: MainAxisSize.min, children: [Icon(exercises.where((e) => e.topic == topic!.id && e.type == 'code').isNotEmpty && exercises.where((e) => e.topic == topic!.id && e.type == 'code').every((e) => store.passed(e.id)) ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 16, color: muted), const SizedBox(width: 7), Text('Code checks passed', style: TextStyle(fontSize: 12, color: muted))]),
  ])]), padding: 16);
  Widget lesson() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () { expandedChapters.add(topic!.chapter); select('My Course'); }, child: const Text('← Back to course'))), heading(topic!.title), Text('My Course / ${chapters[topic!.chapter]} / ${topic!.title}', style: TextStyle(fontSize: 12, color: muted)), const SizedBox(height: 20),
    Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final label in ['Learn','Classwork','Homework','Challenge','Project','Assessment','My Notes','My Code','Resources']) Semantics(button: true, selected: tab == label, child: InkWell(onTap: () => setState(() { tab = label; }), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tab == label ? teal : Colors.transparent, width: 2))), child: Text(label, style: TextStyle(fontSize: 14, color: tab == label ? (store.dark ? Colors.white : navy) : muted, fontWeight: tab == label ? FontWeight.w600 : FontWeight.w400)))))]))), const SizedBox(height: 20),
    if (tab == 'Learn') ...[progressStrip(), const SizedBox(height: 26), if (topic!.ready) ...[
      const Text('Targets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text('I can ${topic!.goal[0].toLowerCase()}${topic!.goal.substring(1)}', style: const TextStyle(height: 1.6)), const SizedBox(height: 28), const Text('Lesson', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 12), SelectableText(topic!.lesson, style: const TextStyle(fontSize: 16, height: 1.7)), const SizedBox(height: 20), codeBlock(topic!.example), const SizedBox(height: 12), Text('Expected result: ${topic!.output}', style: TextStyle(color: muted, height: 1.5)), const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => setState(() { tab = 'My Code'; }), child: const Text('Try it in My Code →'))),
    ] else panel('Lesson awaiting authoring', 'This outline is available for planning and notes. It has no published lesson or assessment requirements yet.'),
      CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Add to my revision queue'), value: store.weak.contains(topic!.id), onChanged: (v) => store.reviewTopic(topic!.id, v == true)),
      const SizedBox(height:24), const Text('Try it in the Python terminal',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Code, input and your last run save on this device. Predict a result, run it, then change one value.'),const SizedBox(height:16),codeWorkspace(topic!),
    ] else if (tab == 'My Notes') notesEditor(topic!.id) else if (tab == 'My Code') codeWorkspace(topic!) else if (tab == 'Resources') resourceList() else if (tab == 'Assessment') panel('Opening chapter assessment', 'A fresh eight-question self-study check. Attempts and best scores stay on this device.', onTap: () => select('Assessments'), label: 'Open assessment →') else ...[
      if (forTopic(topic!.id, tab).isEmpty) panel(tab, 'No $tab has been authored for this topic yet. This draft does not add course completion requirements.'),
      for (final e in forTopic(topic!.id, tab)) ExerciseCard(key: ValueKey(e.id), exercise: e, store: store),
    ],
  ]);
  Widget codeBlock(String text) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: store.dark ? const Color(0xff101827) : const Color(0xffeef2f6), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>action(() async { await Clipboard.setData(ClipboardData(text:text)); },success:'Code copied.'),icon:const Icon(Icons.copy,size:16),label:const Text('Copy code'))),SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.6))]));
  Widget notesEditor(String id) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('My Notes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 12), TextField(key: ValueKey('notes-$id'), controller: note, minLines: 8, maxLines: 25, decoration: const InputDecoration(hintText: 'Explain it in your own words. Include a prediction, example, and what changed.', border: OutlineInputBorder()), onChanged: (value) => store.edit(id, notes: value)), const SizedBox(height: 12), Text(store.saveStatus, style: const TextStyle(fontSize: 12)), const SizedBox(height: 12), Wrap(spacing: 10, children: [FilledButton.icon(onPressed: store.save, icon: const Icon(Icons.save_outlined), label: const Text('Save on device')), OutlinedButton.icon(onPressed: () => action(() async { await downloadText('$id-notes.txt', note.text); }), icon: const Icon(Icons.download_outlined), label: const Text('Download notes')), TextButton(onPressed: () => action(() async { await Clipboard.setData(ClipboardData(text: note.text)); }, success: 'Copied.'), child: const Text('Copy'))])]);
  Widget codeWorkspace(Topic value) => Column(children: [
    Align(alignment:Alignment.centerLeft,child:OutlinedButton.icon(onPressed:()=>action(() async {final source=await pickText(['py']);if(source==null||!mounted)return;final current=store.draft(value.id)['code'] as String? ?? '';if(current.trim().isNotEmpty){final replace=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Replace this code draft?'),content:const Text('Download your current Python file first if you want to keep both.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Replace draft'))]));if(replace!=true)return;}store.edit(value.id,code:source,revision:'${DateTime.now().microsecondsSinceEpoch}');}),icon:const Icon(Icons.file_open_outlined),label:const Text('Import Python file'))),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FullRunner(title: value.title, store: store, draftId: value.id, initial: value.example))).then((_){if(mounted)store.edit(value.id,revision:'view-${DateTime.now().microsecondsSinceEpoch}');}), icon: const Icon(Icons.open_in_full), label: const Text('Full-screen workspace'))),
    RunnerPanel(key: ValueKey('topic-runner-${value.id}'), store: store, draftId: value.id, initial: value.example),
  ]);
  Widget notebook() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Notebook'), TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search notes', border: OutlineInputBorder()), onChanged: (v) => setState(() { search = v.toLowerCase(); })), const SizedBox(height: 16),
    panel('General notebook', 'A place for ideas that belong to more than one topic.', onTap: () { setState(() { topic = null; note.text = store.draft('general')['notes'] as String? ?? ''; section = 'General notes'; }); }, label: 'Open general notes →'),
    if (store.notesCount == 0) panel('Start your first topic note', 'Open a topic and choose My Notes.', onTap: () => select('My Course'), label: 'Browse topics →'),
    for (final t in courseTopics) if ((store.draft(t.id)['notes'] as String? ?? '').isNotEmpty && (search.isEmpty || '${t.title} ${store.draft(t.id)['notes']}'.toLowerCase().contains(search))) panel(t.title, store.draft(t.id)['notes'] as String, onTap: () => openTopic(t, activeTab: 'My Notes'), label: 'Edit note →'),
  ]);
  Widget practice({bool projectOnly = false}) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading(projectOnly ? 'Projects' : 'Practice and Homework'), Text(projectOnly ? 'Output checks are automatic. Review the stated design and written evidence separately.' : 'Practice activities are independently authored. Retakes create new saved attempts; repeated passes do not duplicate points.', style: TextStyle(color: muted, height: 1.5)), const SizedBox(height: 20),
    for (final e in exercises.where((e) => projectOnly ? e.category == 'Project' : e.category != 'Project')) Padding(padding: const EdgeInsets.only(bottom: 12), child: surface(ListTile(contentPadding: EdgeInsets.zero, title: Text(e.title), subtitle: Text('${e.category} • ${topicById(e.topic).title} • ${store.passed(e.id) ? 'Passed local checks' : e.type == 'written' ? 'Rubric review' : 'Ready'}'), trailing: const Icon(Icons.chevron_right), onTap: () => openTopic(topicById(e.topic), activeTab: e.category)))),
    if (projectOnly) CheckboxListTile(title: const Text('I reviewed the project design and explanation'), subtitle: const Text('Check the calculation function, meaningful names, and explanations of two test cases. This records self-review, not a reviewer award.'), value: store.reviews['opening-project'] == true, onChanged: store.passed('opening-project') ? (v) => store.setReview('opening-project', v == true) : null),
  ]);
  Widget assessment() {
    final questions = starterExercises.where((e) => e.category == 'Classwork').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Assessments'), panel('Opening chapter self-study check', 'Eight objective questions • 80% pass threshold • open-book • local marking. A full-course examination is not published yet.'),
      Text('Best score: ${store.assessmentBest.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 12),
      for (final e in questions) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.prompt, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 12),
        if (e.type == 'choice') for (var i = 0; i < e.options.length; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: OutlinedButton(onPressed: assessmentSubmitted ? null : () => setState(() { assessmentAnswers[e.id] = '$i'; }), style: OutlinedButton.styleFrom(backgroundColor: assessmentAnswers[e.id] == '$i' ? teal.withValues(alpha: .12) : null), child: Text('${String.fromCharCode(65+i)}. ${e.options[i]}')))
        else TextFormField(key: ValueKey('assessment-${e.id}-$assessmentSubmitted'), initialValue: assessmentAnswers[e.id] ?? '', enabled: !assessmentSubmitted, decoration: const InputDecoration(labelText: 'Your answer', border: OutlineInputBorder()), onChanged: (v) => assessmentAnswers[e.id] = v),
        if (assessmentSubmitted) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${gradeAnswer(e, assessmentAnswers[e.id] ?? '')['passed'] == true ? 'Correct' : 'Review needed'}. ${e.solution}', style: const TextStyle(height: 1.5))),
      ]))),
      Wrap(spacing: 12, children: [FilledButton(onPressed: assessmentSubmitted ? null : () async {
        if (questions.any((e) => (assessmentAnswers[e.id] ?? '').trim().isEmpty)) { toast('Answer all eight questions before submitting.'); return; }
        final score = (questions.where((e) => gradeAnswer(e, assessmentAnswers[e.id]!)['passed'] == true).length / questions.length * 100).round();
        await store.recordAssessment(score, Map.from(assessmentAnswers)); if (mounted) setState(() { assessmentSubmitted = true; });
      }, child: const Text('Submit assessment')), OutlinedButton(onPressed: () => setState(() { assessmentAnswers.clear(); assessmentSubmitted = false; }), child: const Text('Start a fresh attempt'))]),
      const SizedBox(height: 24), const Text('Saved assessment attempts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), for (final a in (store.attempts['opening-assessment'] ?? []).reversed) ListTile(title: Text('${a['score']}%'), subtitle: Text(a['submittedAt'] as String)),
    ]);
  }
  Widget progressPage() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Progress'), panel('Activity completion', '${store.completedCount} of ${store.requiredCount} required starter activities passed local checks. Optional challenges do not increase the required total. Self-reviewed topics and visits do not award activity completion.'), LinearProgressIndicator(value: store.progress, minHeight: 8), const SizedBox(height: 20),
    for (final t in courseTopics) ListTile(title: Text(t.title), subtitle: Text('${exercises.where((e) => e.topic == t.id && e.type == 'code' && store.passed(e.id)).length}/${exercises.where((e) => e.topic == t.id && e.type == 'code').length} code activities passed • ${store.draft(t.id)['reviewed']==true?'self-reviewed':'reflection pending'}'), trailing: const Icon(Icons.chevron_right), onTap: () => openTopic(t)),
    panel('Points', '${store.points} points. Each uniquely passed exercise earns 10 engagement points. Points do not certify understanding.'),
  ]);
  Widget revision() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Revision'), if (store.weak.isEmpty) panel('Your revision queue is clear', 'Add a topic from its Learn screen or return here after a failed objective check. Resolving it records your own review.'),
    for (final id in store.weak) Padding(padding: const EdgeInsets.only(bottom: 16), child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(topicById(id).title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), const Text('Predict an example, run it, then explain why the output makes sense. Try a different input.'), Wrap(spacing: 10, children: [TextButton(onPressed: () => openTopic(topicById(id)), child: const Text('Review topic →')), TextButton(onPressed: () => store.reviewTopic(id, false), child: const Text('Mark my review resolved'))])]))),
  ]);
  Future<void> confirmName() async {
    nameController.text = store.name;
    final value = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text('Your study record details'), content: TextField(controller: nameController, maxLength: 120, decoration: const InputDecoration(labelText: 'Name on the record')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), TextButton(onPressed: () { if (nameController.text.trim().isNotEmpty) Navigator.pop(c, nameController.text.trim()); }, child: const Text('Save details'))]));
    if (value != null) await store.preferences(displayName: value);
  }
  Widget certificates() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Achievements and Certificates'), panel('Full course certificate — locked', 'A full-course certificate needs the published course requirements, full-course assessment and final project review. Those assessment requirements are still being prepared. Local visits or points cannot unlock it.'),
    panel('Opening chapter independent study record', store.issuedOpeningRecord != null ? 'Issued on ${store.issuedOpeningRecord!['issuedAt']}. Download returns the same record ID, issue date and details.' : store.openingRecordEligible ? 'Eligible: all required starter checks, the opening assessment, and project self-review are recorded.' : 'Requirements: ${store.completedCount}/${store.requiredCount} required starter checks; assessment ${store.assessmentBest.toStringAsFixed(0)}% (80% required); project design/explanation ${store.reviews['opening-project'] == true ? 'self-reviewed' : 'review pending'}.'),
    panel('Download your learning progress', 'A PDF showing your current learning evidence, name and dates. It clearly states the local test and self-review basis and is not a full-course qualification.'),
    Wrap(spacing: 12, runSpacing: 8, children: [OutlinedButton(onPressed: confirmName, child: const Text('Confirm my name')), OutlinedButton(onPressed: () => action(() => previewRecord(store)), child: const Text('Preview progress PDF')), FilledButton.icon(onPressed: () => action(() async { await downloadRecord(store); }), icon: const Icon(Icons.download), label: const Text('Download progress PDF')), FilledButton(onPressed: store.openingRecordEligible || store.issuedOpeningRecord != null ? () => action(() async { if(store.issuedOpeningRecord == null && store.name.trim().isEmpty){await confirmName();if(store.name.trim().isEmpty)return;}await downloadRecord(store, opening: true); }) : null, child: const Text('Download opening chapter record'))]),
  ]);
  Widget resourceList() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Resources'), for (final resource in const [
    ['Python Tutorial','https://docs.python.org/3/tutorial/','Core language explanations and examples.'], ['Python built-in functions','https://docs.python.org/3/library/functions.html','Reference for print, input, int and other functions.'], ['Python language reference','https://docs.python.org/3/reference/','Precise syntax and language behaviour.'], ['Pyodide documentation','https://pyodide.org/en/stable/usage/','The browser Python runtime used by the workspace.'],
  ]) panel(resource[0], resource[2], onTap: () => action(() async { if (!await launchUrl(Uri.parse(resource[1]), mode: LaunchMode.externalApplication)) throw const FormatException('Resource could not be opened.'); }), label: 'Open reference ↗')]);
  Widget settings() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Settings'), panel('Device workspace', 'No login is required. Work stays on this browser or phone. Use a backup to transfer your learning; clearing browser or app storage removes the local copy.'), panel('Your name', store.name.isEmpty ? 'Choose a name for your dashboard and study records.' : store.name, onTap: confirmName, label: 'Edit name'),
    SwitchListTile(title: const Text('Dark mode'), value: store.dark, onChanged: (v) => store.preferences(night: v)), ListTile(title: const Text('Reading text size'), subtitle: Slider(value: store.textScale, min: 1, max: 1.4, divisions: 4, label: '${(store.textScale*100).round()}%', onChanged: (v) => store.preferences(scale: v))),
    SwitchListTile(title: const Text('Study reminders'), subtitle: const Text('Android: a daily local reminder. Web: every 30 minutes while this page remains open. Permission is requested only when enabled.'), value: store.reminders, onChanged: (v) => action(() async { if (v) { final result = await enableReminders(); if (!mounted) return; toast(result); await store.preferences(reminder: result.startsWith('Daily reminders enabled') || result.startsWith('Reminders enabled')); } else { await disableReminders(); await store.preferences(reminder: false); } })),
    const SizedBox(height: 20), panel('Backup and restore', 'Download a JSON backup containing your notes, code, attempts, revision queue and preferences. Keep it private. Restore validates the file before replacing this device record.'), Wrap(spacing: 12, runSpacing: 8, children: [FilledButton.icon(onPressed: () => action(() async { await store.pending; await downloadText('Bajinka-learning-backup.json', store.exportBackup()); }), icon: const Icon(Icons.download), label: const Text('Download backup')), OutlinedButton.icon(onPressed: () => action(() async {
      final text = await pickText(['json']); if (text == null) return; LearnerStore.validateBackup(text); if (!mounted) return;
      final accept = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Restore this backup?'), content: const Text('It replaces this device’s current learning record. Download a backup of your current work first.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restore'))]));
      if (accept == true) { await store.restore(text); if (mounted) toast('Backup restored.'); }
    }), icon: const Icon(Icons.upload_file), label: const Text('Restore backup'))]),
    const SizedBox(height:24), OutlinedButton.icon(onPressed:()=>action(() async {final remove=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Remove learning from this device?'),content:const Text('This clears your saved name, notes, code, attempts, progress and study records on this device. Download a backup first. This cannot be undone without your backup.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Keep my learning')),TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Remove device learning'))]));if(remove!=true)return;await disableReminders();await store.clearDeviceRecord();if(mounted){select('Home');toast('Device learning removed. Your downloaded backups are unchanged.');}}),icon:const Icon(Icons.delete_outline),label:const Text('Remove learning from this device')),
  ]);
  Widget body() => switch(section) {
    'Home' => home(), 'My Course' => topic == null ? course() : lesson(), 'Practice and Homework' => practice(), 'Projects' => practice(projectOnly: true), 'Notebook' => notebook(), 'General notes' => notesEditor('general'), 'Assessments' => assessment(), 'Progress' => progressPage(), 'Revision' => revision(), 'Achievements and Certificates' => certificates(), 'Resources' => resourceList(), 'Settings' => settings(),
    'Sources & Acknowledgements' => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Sources & Acknowledgements'), panel('Independently authored learning material', 'The lessons and activities are independently authored for Bajinka Academy. Python language documentation is a technical reference. Reference links identify background materials; they do not imply university endorsement.'), panel('Course sequence', 'The broad chapter sequence follows the public CS50P-inspired course map already used by this project. Harvard, Helsinki, MIT and Beijing Institute of Technology are reference candidates for later content review. The academy is independent and these institutions do not endorse its study records.'), panel('Software acknowledgements', 'Python is developed by the Python community. Pyodide runs Python in the local workspace. Flutter provides the learner interface. Their names and documentation links identify the tools used; no university qualification is claimed.'), resourceList()]),
    'Privacy Policy' => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading('Data and privacy information'), panel('What this release stores', 'Your chosen name, notes, Python drafts, entered program input, exercise answers, attempt results, study dates, revision topics and preferences are stored locally on this browser or Android installation. Login and cloud sync are deferred. The app does not send this learning record to Supabase.'), panel('Code execution and third parties', 'Python executes in a worker on your device. Loading its runtime contacts jsDelivr to download Pyodide files, so that provider receives ordinary network request information. Opening a reference link visits its external website. No advertising or billing is enabled in this release.'), panel('Your controls', 'Download notes, Python files and a full JSON backup in Settings. Backups contain your private learning work. Remove the local record in Settings using Remove learning from this device, or through browser site-storage controls or Android app storage settings. Uninstalling or clearing storage can remove unsaved backups. Notification permission is optional and can be revoked in device or browser settings.'), panel('Publication details pending', 'Operator contact details and the final reviewed policy for future account sync, learner submissions, retention and admin access must be supplied before those services launch. This page describes the current device workspace.')]),
    _ => home(),
  };
  @override Widget build(BuildContext context) => Theme(data: academyTheme(store.dark), child: Builder(builder: (context) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(store.textScale)), child: Scaffold(key: scaffold,
    appBar: AppBar(centerTitle: true, toolbarHeight: 60, title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.school_outlined, color: teal, size: 20), SizedBox(width: 8), Flexible(child: Text('Bajinka Python Academy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))]), bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)), actions: [IconButton(tooltip: store.dark ? 'Light mode' : 'Dark mode', onPressed: () => store.preferences(night: !store.dark), icon: Icon(store.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20))]),
    drawer: Drawer(shape: const RoundedRectangleBorder(), child: ListView(children: [const Padding(padding: EdgeInsets.all(24), child: Text('Bajinka Python Academy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))), for (var i = 0; i < sections.length; i++) ListTile(leading: Icon(sectionIcons[i], size: 20), selected: section == sections[i], selectedTileColor: teal.withValues(alpha: .08), title: Text(sections[i] == 'Home' ? 'Dashboard' : sections[i]), onTap: () { search = ''; select(sections[i]); scaffold.currentState?.closeDrawer(); })])),
    body: SingleChildScrollView(controller: scroll, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28), child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: section == 'Home' ? 1200 : 736), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (store.loading) const LinearProgressIndicator(), if (store.message.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(store.message)), body(), const SizedBox(height: 48), const Divider(), Wrap(spacing: 16, children: [TextButton(onPressed: () => select('Sources & Acknowledgements'), child: const Text('Sources & Acknowledgements')), TextButton(onPressed: () => select('Privacy Policy'), child: const Text('Privacy Policy'))])])))),
  ))));
  @override void dispose() { store.removeListener(refresh); store.dispose(); scroll.dispose(); note.dispose(); nameController.dispose(); super.dispose(); }
}

class RunnerPanel extends StatelessWidget {
  const RunnerPanel({super.key, required this.store, required this.draftId, this.initial = '', this.exercise, this.height = 720, this.helpUsed = false});
  final LearnerStore store;
  final String draftId, initial;
  final Exercise? exercise;
  final double height;
  final bool helpUsed;
  @override Widget build(BuildContext context) {
    final draft = store.draft(draftId);
    return SizedBox(height: height, child: PythonRunner(key: ValueKey('runner-$draftId'), config: {'code':draft['codeEdited'] == true || (draft['code'] as String? ?? '').isNotEmpty ? draft['code'] : initial, 'input':draft['input'] ?? '', 'tests':exercise?.tests ?? [], 'dark':store.dark, 'revision':draft['editorRevision'], 'lastRun':draft['lastRun']}, onMessage: (m) {
      if (m['type'] == 'draft') store.edit(draftId, code:m['code'] as String? ?? '', input:m['input'] as String? ?? '');
      if (m['type'] == 'result' && exercise != null) unawaited(store.recordAttempt(exercise!, Map<String, dynamic>.from(m['result']), answer:m['code'] as String? ?? '', helpUsed:helpUsed));
      if (m['type'] == 'clear') store.edit(draftId,lastRun:{'output':'','error':'','prompts':<String>[],'code':draft['code'] as String? ?? '', 'cleared':true,'recordedAt':DateTime.now().toIso8601String()});
      if (m['type'] == 'run' && m['runtime'] is Map) store.edit(draftId,lastRun:{...Map<String,dynamic>.from(m['runtime']), 'code':m['code'] as String? ?? '', 'recordedAt':DateTime.now().toIso8601String()});
      if (m['type'] == 'run' && m['success'] == true) { final id = exercise?.topic ?? draftId; unawaited(store.mark(id, 'practised', true)); }
      if (m['type'] == 'download') unawaited(downloadText('${draftId.replaceAll(':','-')}.py', m['code'] as String? ?? ''));
    }));
  }
}
class FullRunner extends StatelessWidget {
  const FullRunner({super.key, required this.title, required this.store, required this.draftId, this.initial = '', this.exercise});
  final String title, draftId, initial;
  final LearnerStore store;
  final Exercise? exercise;
  @override Widget build(BuildContext context) => Theme(data: academyTheme(store.dark), child: Scaffold(appBar: AppBar(title: Text(title, style: const TextStyle(fontSize: 16))), body: RunnerPanel(store:store, draftId:draftId, initial:initial, exercise:exercise, height:MediaQuery.sizeOf(context).height-90)));
}
class ExerciseCard extends StatefulWidget {
  const ExerciseCard({super.key, required this.exercise, required this.store});
  final Exercise exercise;
  final LearnerStore store;
  @override State<ExerciseCard> createState() => _ExerciseCardState();
}
class _ExerciseCardState extends State<ExerciseCard> {
  late final TextEditingController response;
  void recordHelp() { helpUsed=true; widget.store.edit(draftId,helpUsed:true); }
  String answer = '', feedback = '';
  bool helpUsed = false, reveal = false;
  String get draftId => 'activity:${widget.exercise.id}';
  @override void initState() { super.initState(); helpUsed = widget.store.draft(draftId)['helpUsed'] == true; answer = widget.store.draft(draftId)['response'] as String? ?? ''; response = TextEditingController(text:answer); }
  void edit(String value) { answer = value; widget.store.edit(draftId, response:value); }
  @override Widget build(BuildContext context) {
    final e=widget.exercise;
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color:widget.store.dark ? const Color(0xff172033) : Colors.white,border:Border.all(color:border),borderRadius:BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(e.title, style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)), const SizedBox(height:16), Text(e.prompt,style:const TextStyle(height:1.6)), const SizedBox(height:16),
      if(e.type=='code') ...[const Padding(padding:EdgeInsets.only(bottom:12),child:Text('Output checks accept equivalent code. Requested design features and explanations need separate review.',style:TextStyle(fontSize:12))),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>FullRunner(title:e.title,store:widget.store,draftId:draftId,exercise:e))).then((_){if(mounted)widget.store.edit(draftId,revision:'view-${DateTime.now().microsecondsSinceEpoch}');}),icon:const Icon(Icons.open_in_full),label:const Text('Full-screen workspace'))),RunnerPanel(store:widget.store,draftId:draftId,exercise:e,helpUsed:helpUsed)]
      else ...[
        if(e.type=='choice') for(var i=0;i<e.options.length;i++) Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(onPressed:()=>setState((){edit('$i');}),style:OutlinedButton.styleFrom(backgroundColor:answer=='$i'?teal.withValues(alpha:.12):null),child:Text('${String.fromCharCode(65+i)}. ${e.options[i]}')))
        else TextField(controller:response,minLines:e.type=='written'?5:1,maxLines:e.type=='written'?12:1,decoration:const InputDecoration(labelText:'Your answer',border:OutlineInputBorder()),onChanged:edit),
        const SizedBox(height:12),FilledButton(onPressed:() async { if(answer.trim().isEmpty){setState((){feedback='Write or choose an answer first.';});return;}final result=gradeAnswer(e,answer);await widget.store.recordAttempt(e,result,answer:answer,helpUsed:helpUsed);if(mounted)setState((){feedback=result['feedback'] as String;});},child:Text(e.type=='written'?'Save for review':'Check answer')), if(feedback.isNotEmpty) Padding(padding:const EdgeInsets.only(top:12),child:Text(feedback)),
      ],
      for(var i=0;i<e.hints.length;i++) ExpansionTile(tilePadding:EdgeInsets.zero,title:Text('Hint ${i+1}',style:const TextStyle(fontSize:14)),onExpansionChanged:(open){if(open)setState((){recordHelp();});},children:[Padding(padding:const EdgeInsets.only(bottom:16),child:Text(e.hints[i]))]),
      if(e.solution.isNotEmpty) TextButton(onPressed:()=>setState((){reveal=!reveal;recordHelp();}),child:Text(reveal?'Hide worked solution':'Reveal worked solution')),
      if(reveal) Container(padding:const EdgeInsets.all(16),color:widget.store.dark?const Color(0xff101827):const Color(0xffeef2f6),child:SelectableText(e.solution,style:const TextStyle(fontFamily:'monospace',height:1.6))),
      if(e.type=='written') const Padding(padding:EdgeInsets.only(top:12),child:Text('Self-review rubric: address every part of the question; give a correct prediction or conclusion; explain your reasoning with a concrete example. This is saved as self-review and does not award an automatic pass.')),
      const Divider(height:32),Text('Saved attempts (${widget.store.attempts[e.id]?.length??0})',style:const TextStyle(fontWeight:FontWeight.w700)),
      for(final a in (widget.store.attempts[e.id]??[]).reversed) ExpansionTile(tilePadding:EdgeInsets.zero,title:Text(a['status']=='review'?'Review pending':a['passed']==true?'Passed local checks':'Try again',style:const TextStyle(fontSize:14)),subtitle:Text('${a['submittedAt']} • ${a['helpUsed']==true?'help used':'no recorded help'}',style:const TextStyle(fontSize:11)),children:[if(a['feedback'] is String) Align(alignment:Alignment.centerLeft,child:Padding(padding:const EdgeInsets.only(bottom:12),child:Text(a['feedback'] as String))),for(final result in (a['tests'] as List? ?? [])) Padding(padding:const EdgeInsets.only(bottom:12),child:Align(alignment:Alignment.centerLeft,child:SelectableText('${result['passed']==true?'Passed':'Review needed'} • ${result['comparison']??'normalized'} comparison\nExpected: ${result['expected']}\nActual: ${result['actual']}${(result['error'] as String? ?? '').isNotEmpty?'\n${result['error']}':''}',style:const TextStyle(fontFamily:'monospace',fontSize:12)))),Align(alignment:Alignment.centerLeft,child:SelectableText(a['answer'] as String? ?? '',style:const TextStyle(fontFamily:'monospace')))]),
    ])));
  }
  @override void dispose(){response.dispose();super.dispose();}
}
