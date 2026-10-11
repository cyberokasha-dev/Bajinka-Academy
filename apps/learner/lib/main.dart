import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learner_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AcademyApp());
}

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key, this.client});
  final SupabaseClient? client;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bajinka Academy', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087f78)), scaffoldBackgroundColor: const Color(0xfff6f8fa)),
    home: LearnerShell(client: client),
  );
}

const sections = ['Home', 'My courses', 'Practice', 'Projects', 'Notebook', 'Assessments', 'Progress', 'Certificates', 'Resources', 'Settings', 'Sources & Acknowledgements', 'Privacy Policy'];
const chapters = ['Functions and Variables', 'Conditionals', 'Loops', 'Exceptions', 'Libraries', 'Unit Tests', 'File I/O', 'Regular Expressions', 'Object-Oriented Programming', 'Et Cetera', 'Final Project and Course Assessment'];
const topics = ['Running and saving Python programs', 'print, strings, and comments', 'Variables and assignment', 'input and string methods', 'Numbers and conversion', 'Arithmetic and formatted output', 'Functions and parameters', 'Return values and program structure'];

class LearnerShell extends StatefulWidget {
  const LearnerShell({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<LearnerShell> createState() => _LearnerShellState();
}

class _LearnerShellState extends State<LearnerShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String section = 'Home';
  int? chapter;
  String? topic;
  String lessonTab = 'Learn';
  final note = TextEditingController();
  final code = TextEditingController();
  late final LearnerStore store;
  Timer? autosave;
  @override
  void initState() {
    super.initState();
    store = LearnerStore(widget.client)..addListener(refresh);
    unawaited(store.start());
  }
  String? renderedOwner;
  bool wasLoading = false;
  void refresh() {
    if (!mounted) return;
    if (renderedOwner != store.owner || (wasLoading && !store.loading)) {
      renderedOwner = store.owner;
      autosave?.cancel();
      if (topic != null) {
        note.text = store.draft(topic!)['notes'] as String;
        code.text = store.draft(topic!)['code'] as String;
      } else { note.clear(); code.clear(); }
    }
    wasLoading = store.loading;
    setState(() {});
  }
  void editDraft() {
    final id = topic;
    if (id == null) return;
    store.edit(id, note.text, code.text);
    autosave?.cancel();
    autosave = Timer(const Duration(milliseconds: 900), () => unawaited(store.save(id)));
  }
  void openTopic(String title) {
    autosave?.cancel();
    if (topic != null) unawaited(store.save(topic!));
    setState(() {
      section = 'My courses'; chapter = 0; topic = title; lessonTab = 'Learn';
      note.text = store.draft(title)['notes'] as String;
      code.text = store.draft(title)['code'] as String;
    });
    unawaited(store.profile(topic: title));
  }
  Widget signInButton() => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xff1f1f1f), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    onPressed: store.googleLogin,
    icon: Image.asset('assets/google-g.png', width: 20, height: 20),
    label: const Text('Continue with Google'),
  );
  Widget account() => panel(store.signedIn ? 'Your account' : 'Save your learning', store.signedIn
    ? 'Signed in as ${store.displayName.isEmpty ? widget.client?.auth.currentUser?.email ?? "Learner" : store.displayName}.'
    : 'Sign in with Google to save private notes, code drafts and your learning journey. Google setup is managed by the owner.');
  Widget homeProgress() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Welcome back${store.displayName.isEmpty ? "" : ", ${store.displayName}"}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), const Text('A little practice every day. Your next step starts here.'),
    const SizedBox(height: 24),
    Wrap(spacing: 16, runSpacing: 12, children: [
      metric('Topics viewed', store.countStage('viewed')),
      metric('Practised', store.countStage('practised')),
      metric('Self-reviewed', store.countStage('reviewed')),
      metric('Topic notes', store.drafts.values.where((d) => (d['notes'] as String? ?? '').isNotEmpty).length),
    ]),
    const SizedBox(height: 20),
    panel('Your progress', 'Personal study record • ${store.countStage('reviewed')} of ${topics.length} mapped topics self-reviewed. Assessed course completion begins when marking rules are published.'),
    LinearProgressIndicator(value: store.countStage('reviewed') / topics.length, minHeight: 8, borderRadius: BorderRadius.circular(8)),
    if (store.lastTopic != null && topics.contains(store.lastTopic)) panel('Continue learning', store.lastTopic!, action: () => openTopic(store.lastTopic!), button: 'Continue'),
    panel('Python Foundations', 'Functions and Variables • 8 mapped topics. Explore the course and keep your own learning notes.', action: () => select('My courses'), button: 'Open my course'),
    panel('Your learning workspace', 'Notes, Python drafts and self-review progress save on this browser or phone. Use Copy to back up your work. Account sync will be added later.'),
  ]);
  Widget metric(String label, int value) => SizedBox(width: 180, child: panel('$value', label));
  void select(String value) { autosave?.cancel(); if (topic != null) unawaited(store.save(topic!)); setState(() { section = value; chapter = null; topic = null; }); }
  @override
  void dispose() { autosave?.cancel(); store.removeListener(refresh); store.dispose(); note.dispose(); code.dispose(); super.dispose(); }
  Widget navigation() => ListView(children: [
    const Padding(padding: EdgeInsets.all(24), child: Row(children: [Icon(Icons.school_outlined, color: Color(0xff087f78)), SizedBox(width: 10), Text('Bajinka Academy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))])),
    for (final item in sections) ListTile(selected: section == item, title: Text(item), onTap: () { select(item); scaffoldKey.currentState?.closeDrawer(); }),
  ]);
  Widget panel(String title, String body, {VoidCallback? action, String? button}) => Card(margin: const EdgeInsets.symmetric(vertical: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xffe3e8ed))), child: SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Text(body), if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton(onPressed: action, child: Text(button ?? 'Open')))]))));
  Widget body() {
    if (section == 'Home' || section == 'Progress') return homeProgress();
    if (section == 'My courses') {
      if (topic != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { topic = null; }), child: const Text('← Back to topics')),
        Text(topic!, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8), const Text('My Course / Functions and Variables', style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 20),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final label in ['Learn', 'Classwork', 'Homework', 'Challenge', 'Project', 'Assessment', 'My Notes', 'My Code', 'Resources']) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: lessonTab == label, onSelected: (_) => setState(() { lessonTab = label; })))])),
        const SizedBox(height: 16),
        panel('YOUR PROGRESS', 'Viewed → Practised → Self-reviewed. Demonstrated understanding requires a marked assessment.'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final stage in ['viewed', 'practised', 'reviewed']) FilterChip(label: Text(stage == 'reviewed' ? 'Self-reviewed' : stage[0].toUpperCase() + stage.substring(1)), selected: store.draft(topic!)[stage] == true, onSelected: (value) => store.mark(topic!, stage, value))]),
        const SizedBox(height: 20),
        if (lessonTab == 'My Notes' || lessonTab == 'My Code') ...[
          Text(lessonTab, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: lessonTab == 'My Notes' ? note : code, minLines: lessonTab == 'My Notes' ? 8 : 14, maxLines: 30, style: lessonTab == 'My Code' ? const TextStyle(fontFamily: 'monospace') : null, decoration: InputDecoration(hintText: lessonTab == 'My Notes' ? 'What did you learn? Write an example in your own words…' : '# Write your Python code here', filled: true, fillColor: Colors.white, border: const OutlineInputBorder()), enabled: !store.loading, onChanged: (_) => editDraft()),
          const SizedBox(height: 12), Text(store.draft(topic!)['status'] as String),
          Wrap(spacing: 12, children: [FilledButton.icon(onPressed: () => store.save(topic!), icon: const Icon(Icons.save_outlined), label: const Text('Save on device')), OutlinedButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: lessonTab == 'My Notes' ? note.text : code.text)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied — paste into a file to keep a backup.'))); }, icon: const Icon(Icons.copy), label: const Text('Copy'))]),
          if (lessonTab == 'My Code') panel('Python workspace', 'Your draft saves locally. Code execution and automatic marking are not connected yet.'),
        ] else panel(lessonTab == 'Learn' ? 'Lesson content' : lessonTab, lessonTab == 'Learn' ? 'This topic is mapped. The course author’s targets, explanation and examples are awaiting import. You can use My Notes and My Code now.' : 'The course author will publish the exact ${lessonTab.toLowerCase()} content and marking rules here. Your study workspace is available now.'),

      ]);
      if (chapter != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { chapter = null; }), child: const Text('← Back to chapters')),
        Text(chapters[chapter!], style: Theme.of(context).textTheme.headlineSmall),
        if (chapter == 0) ...[for (final title in topics) ListTile(title: Text(title), subtitle: const Text('Draft • lesson, practice and challenge'), trailing: const Icon(Icons.chevron_right), onTap: () => openTopic(title))] else panel('Topics awaiting authoring', 'Full topic content and exact questions will be supplied by the course author.'),
        panel('Chapter assessment and cumulative project', 'Locked until authored requirements and marking rules are published.'),
      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [panel('Python Foundations', 'Independent study • 11 planned chapters • content in development'), for (var i = 0; i < chapters.length; i++) ListTile(leading: CircleAvatar(child: Text('$i')), title: Text(chapters[i]), subtitle: const Text('Draft'), trailing: const Icon(Icons.chevron_right), onTap: () => setState(() { chapter = i; }))]);
    }
    if (section == 'Notebook') return Column(children: [panel('My notebook', 'Your topic notes save on this device. Open a note to continue writing.'), if (store.drafts.values.every((d) => (d['notes'] as String? ?? '').isEmpty)) panel('Start your first note', 'Open a course topic and choose My Notes.', action: () => select('My courses'), button: 'Browse topics'), for (final entry in store.drafts.entries.where((e) => (e.value['notes'] as String? ?? '').isNotEmpty)) panel(entry.key, entry.value['notes'] as String, action: () => openTopic(entry.key), button: 'Edit note')]);
    if (section == 'Settings') return Column(children: [
      panel('Device workspace', 'Learning work is stored on this device. No login is needed. Copy important notes and code before clearing browser storage.'),
      panel('Your name', store.displayName.isEmpty ? 'Choose a name for your dashboard.' : store.displayName, action: () async {
        final input = TextEditingController(text: store.displayName);
        final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Your name'), content: TextField(controller: input, maxLength: 120), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, input.text), child: const Text('Save'))]));
        if (name != null) await store.profile(name: name);
      }, button: 'Edit name'),
    ]);
    if (section == 'Sources & Acknowledgements') return panel('Sources & Acknowledgements', 'A separate admin-managed page for sources actually used, attribution and licences. Planned reference sources include Harvard CS50P, Helsinki, MIT and Beijing Institute of Technology. These are references, not endorsements. Detailed published acknowledgements follow content review.');
    if (section == 'Privacy Policy') return panel('Privacy Policy — draft', 'Admin will publish the operator’s reviewed policy here, covering accounts, private notes, submissions, notifications, retention and user rights. The current learner workspace saves notes, code and self-review records on this device. Account login is deferred. Clearing browser or app storage removes local records. A full operator-reviewed policy is awaiting publication.');
    if (section == 'Certificates') return panel('Certificates locked', 'Complete a fully published course and its required assessments/project. Then confirm your name and study dates, preview and download your course certificate.');
    return panel(section, switch (section) {
      'Practice' => 'Admin-authored A–D questions, writing, code, debugging and a challenge for each topic. Marking rules will be shown clearly.',
      'Assessments' => 'Chapter and final assessments, saved attempts, retakes and rubric reviews. No assessments published yet.',
      'Progress' => 'Real completion, demonstrated understanding, weak topics and points will appear here.',
      'Projects' => 'Cumulative projects with code files, explanation, tests, evidence and review rubrics.',
      'Resources' => 'Admin-published videos, PDFs and reference links, organised by topic.',
      _ => 'Account, theme, accessibility, notification preferences, data export and policy links will be available here.',
    });
  }
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) {
    final wide = bounds.maxWidth >= 950;
    return Scaffold(key: scaffoldKey, appBar: AppBar(backgroundColor: Colors.white, title: const Text('Bajinka Academy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), actions: [IconButton(tooltip: 'Home', onPressed: () => select('Home'), icon: const Icon(Icons.home_outlined))]),
      drawer: wide ? null : Drawer(child: Builder(builder: (_) => navigation())),
      body: Row(children: [if (wide) SizedBox(width: 250, child: navigation()), Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(wide ? 32 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (store.loading) const LinearProgressIndicator(), if (store.message.isNotEmpty) MaterialBanner(content: Text(store.message), actions: [TextButton(onPressed: store.load, child: const Text('Retry'))]), body()])))))]));
  });
}
