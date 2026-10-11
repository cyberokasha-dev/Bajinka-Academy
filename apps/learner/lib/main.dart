import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'learner_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseClient? client;
  try {
    await Supabase.initialize(url: 'https://zesvwdewewylotohcsgn.supabase.co', publishableKey: 'sb_publishable_pyX5NRIIF99KroUmr5RSyQ_xNO1WdwB');
    client = Supabase.instance.client;
  } catch (_) { /* Browsing remains available if account initialisation fails. */ }
  runApp(AcademyApp(client: client));
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
      section = 'My courses'; chapter = 0; topic = title;
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
  Widget homeProgress() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    account(), if (!store.signedIn) signInButton(),
    const SizedBox(height: 16),
    panel('Your progress', store.requiredCount == 0
      ? 'No required activities are published yet. Completion is not calculated from visits.'
      : '${store.completedCount} of ${store.requiredCount} required activities completed.'),
    if (store.requiredCount > 0) LinearProgressIndicator(value: store.completedCount / store.requiredCount),
    panel('Learning record', '${store.points} points • ${store.drafts.values.where((d) => (d["notes"] as String? ?? "").isNotEmpty).length} topic notes'),
    if (store.lastTopic != null && topics.contains(store.lastTopic)) panel('Continue learning', store.lastTopic!, action: () => openTopic(store.lastTopic!), button: 'Continue'),
    panel('Python Foundations', 'Explore the planned chapters. Course content remains in development.', action: () => select('My courses'), button: 'Explore course map'),
  ]);
  void select(String value) { autosave?.cancel(); if (topic != null) unawaited(store.save(topic!)); setState(() { section = value; chapter = null; topic = null; }); }
  @override
  void dispose() { autosave?.cancel(); store.removeListener(refresh); store.dispose(); note.dispose(); code.dispose(); super.dispose(); }
  Widget navigation() => ListView(children: [
    const Padding(padding: EdgeInsets.all(24), child: Text('BAJINKA\nACADEMY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22))),
    for (final item in sections) ListTile(selected: section == item, title: Text(item), onTap: () { select(item); scaffoldKey.currentState?.closeDrawer(); }),
  ]);
  Widget panel(String title, String body, {VoidCallback? action, String? button}) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Text(body), if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton(onPressed: action, child: Text(button ?? 'Open')))])));
  Widget body() {
    if (section == 'Home' || section == 'Progress') return homeProgress();
    if (section == 'My courses') {
      if (topic != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { topic = null; }), child: const Text('← Back to topics')),
        Text(topic!, style: Theme.of(context).textTheme.headlineSmall),
        panel('Lesson awaiting publication', 'Admin will publish targets, detailed explanations, examples and resources here. No course content has been invented for this preview.'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final label in ['Learn', 'Classwork', 'Homework', 'Challenge', 'Reflection']) Chip(label: Text(label))]),
        const SizedBox(height: 16), TextField(controller: note, minLines: 5, maxLines: 12, decoration: const InputDecoration(labelText: 'My notes and explanation', border: OutlineInputBorder()), enabled: store.signedIn && !store.loading, onChanged: (_) => editDraft()),
        const SizedBox(height: 16), TextField(controller: code, minLines: 10, maxLines: 24, style: const TextStyle(fontFamily: 'monospace'), decoration: const InputDecoration(labelText: 'Python draft — execution comes later', border: OutlineInputBorder()), enabled: store.signedIn && !store.loading, onChanged: (_) => editDraft()),
        const SizedBox(height: 12), Text(store.signedIn ? store.draft(topic!)['status'] as String : 'Sign in to write and save private work.'),
        if (!store.signedIn) signInButton(),
        if (store.signedIn) Wrap(spacing: 12, children: [
          TextButton(onPressed: () => store.save(topic!), child: const Text('Retry save')),
          TextButton(onPressed: () async {
            final id = topic!;
            final accept = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
              title: const Text('Load cloud version?'),
              content: const Text('This replaces your local changes. Copy them first if you want to keep them.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Load cloud version'))]));
            if (accept != true) return;
            await store.loadCloudDraft(id);
            if (mounted && topic == id) setState(() { note.text = store.draft(id)['notes'] as String; code.text = store.draft(id)['code'] as String; });
          }, child: const Text('Load cloud version')),
        ]),
      ]);
      if (chapter != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { chapter = null; }), child: const Text('← Back to chapters')),
        Text(chapters[chapter!], style: Theme.of(context).textTheme.headlineSmall),
        if (chapter == 0) ...[for (final title in topics) ListTile(title: Text(title), subtitle: const Text('Draft • lesson, practice and challenge'), trailing: const Icon(Icons.chevron_right), onTap: () => openTopic(title))] else panel('Topics awaiting authoring', 'Full topic content and exact questions will be supplied by the course author.'),
        panel('Chapter assessment and cumulative project', 'Locked until authored requirements and marking rules are published.'),
      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [panel('Python Foundations', 'Independent study • 11 planned chapters • content in development'), for (var i = 0; i < chapters.length; i++) ListTile(leading: CircleAvatar(child: Text('$i')), title: Text(chapters[i]), subtitle: const Text('Draft'), trailing: const Icon(Icons.chevron_right), onTap: () => setState(() { chapter = i; }))]);
    }
    if (section == 'Notebook') return Column(children: [account(), if (!store.signedIn) signInButton(), for (final entry in store.drafts.entries.where((e) => (e.value['notes'] as String? ?? '').isNotEmpty)) panel(entry.key, entry.value['notes'] as String, action: () => openTopic(entry.key), button: 'Edit note')]);
    if (section == 'Settings') return Column(children: [account(),
      if (!store.signedIn) signInButton(),
      if (store.signedIn) ...[
        panel('Display name', store.displayName.isEmpty ? 'Choose the name shown in your account.' : store.displayName, action: () async {
          final input = TextEditingController(text: store.displayName);
          final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Your name'), content: TextField(controller: input, maxLength: 120), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, input.text), child: const Text('Save'))]));
          input.dispose(); if (name != null) await store.profile(name: name);
        }, button: 'Edit name'),
        SwitchListTile(title: const Text('Study reminder preference'), subtitle: const Text('Preference only — notification delivery comes in a later phase.'), value: store.reminders, onChanged: (v) => store.profile(reminder: v)),
        OutlinedButton(onPressed: () async { autosave?.cancel(); if (topic != null) await store.save(topic!); await store.logout(); }, child: const Text('Sign out')),
      ],
    ]);
    if (section == 'Sources & Acknowledgements') return panel('Sources & Acknowledgements', 'A separate admin-managed page for sources actually used, attribution and licences. Planned reference sources include Harvard CS50P, Helsinki, MIT and Beijing Institute of Technology. These are references, not endorsements. Detailed published acknowledgements follow content review.');
    if (section == 'Privacy Policy') return panel('Privacy Policy — draft', 'Admin will publish the operator’s reviewed policy here, covering accounts, private notes, submissions, notifications, retention and user rights. Google sign-in stores an account session; learner profile, notes, code drafts and progress are stored in Supabase. Local recovery copies are kept on your device. A full operator-reviewed policy is awaiting publication.');
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
    return Scaffold(key: scaffoldKey, appBar: AppBar(title: Text(section), actions: [Padding(padding: const EdgeInsets.all(16), child: Text(store.signedIn ? 'My account' : 'Phase 2'))]),
      drawer: wide ? null : Drawer(child: Builder(builder: (_) => navigation())),
      body: Row(children: [if (wide) SizedBox(width: 250, child: navigation()), Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(wide ? 32 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (store.loading) const LinearProgressIndicator(), if (store.message.isNotEmpty) MaterialBanner(content: Text(store.message), actions: [TextButton(onPressed: store.load, child: const Text('Retry'))]), body()])))))]));
  });
}
