import 'package:flutter/material.dart';

void main() => runApp(const AcademyApp());

class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bajinka Academy', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff087f78)), scaffoldBackgroundColor: const Color(0xfff6f8fa)),
    home: const LearnerShell(),
  );
}

const sections = ['Home', 'My courses', 'Practice', 'Projects', 'Notebook', 'Assessments', 'Progress', 'Certificates', 'Resources', 'Settings', 'Sources & Acknowledgements', 'Privacy Policy'];
const chapters = ['Functions and Variables', 'Conditionals', 'Loops', 'Exceptions', 'Libraries', 'Unit Tests', 'File I/O', 'Regular Expressions', 'Object-Oriented Programming', 'Et Cetera', 'Final Project and Course Assessment'];
const topics = ['Running and saving Python programs', 'print, strings, and comments', 'Variables and assignment', 'input and string methods', 'Numbers and conversion', 'Arithmetic and formatted output', 'Functions and parameters', 'Return values and program structure'];

class LearnerShell extends StatefulWidget {
  const LearnerShell({super.key});
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
  final Map<String, String> notes = {};
  final Map<String, String> codes = {};
  void select(String value) => setState(() { section = value; chapter = null; topic = null; });
  @override
  void dispose() { note.dispose(); code.dispose(); super.dispose(); }
  Widget navigation() => ListView(children: [
    const Padding(padding: EdgeInsets.all(24), child: Text('BAJINKA\nACADEMY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22))),
    for (final item in sections) ListTile(selected: section == item, title: Text(item), onTap: () { select(item); scaffoldKey.currentState?.closeDrawer(); }),
  ]);
  Widget panel(String title, String body, {VoidCallback? action, String? button}) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12), Text(body), if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: FilledButton(onPressed: action, child: Text(button ?? 'Open')))])));
  Widget body() {
    if (section == 'Home') return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('A place to understand, practise and build.', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 20), panel('Your learning journey', 'Your real progress will appear after account setup. This preview contains no completed work or grades.', action: () => select('My courses'), button: 'Explore course map'),
      panel('Learn with purpose', 'Read → predict → explain → practise → solve an unfamiliar challenge → revisit.'),
      panel('Private notes', 'Capture your questions inside a lesson. Phase 1 notes stay in this session only; persistent saving comes next.'),
    ]);
    if (section == 'My courses') {
      if (topic != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { topic = null; }), child: const Text('← Back to topics')),
        Text(topic!, style: Theme.of(context).textTheme.headlineSmall),
        panel('Lesson awaiting publication', 'Admin will publish targets, detailed explanations, examples and resources here. No course content has been invented for this preview.'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final label in ['Learn', 'Classwork', 'Homework', 'Challenge', 'Reflection']) Chip(label: Text(label))]),
        const SizedBox(height: 16), TextField(controller: note, minLines: 5, maxLines: 12, decoration: const InputDecoration(labelText: 'My notes and explanation', border: OutlineInputBorder()), onChanged: (v) => notes[topic!] = v),
        const SizedBox(height: 16), TextField(controller: code, minLines: 10, maxLines: 24, style: const TextStyle(fontFamily: 'monospace'), decoration: const InputDecoration(labelText: 'Python draft — execution comes later', border: OutlineInputBorder()), onChanged: (v) => codes[topic!] = v),
        const SizedBox(height: 12), const Text('Session draft only. Refreshing or closing the app clears this preview work.'),
      ]);
      if (chapter != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { chapter = null; }), child: const Text('← Back to chapters')),
        Text(chapters[chapter!], style: Theme.of(context).textTheme.headlineSmall),
        if (chapter == 0) ...[for (final title in topics) ListTile(title: Text(title), subtitle: const Text('Draft • lesson, practice and challenge'), trailing: const Icon(Icons.chevron_right), onTap: () => setState(() { topic = title; note.text = notes[title] ?? ''; code.text = codes[title] ?? ''; }))] else panel('Topics awaiting authoring', 'Full topic content and exact questions will be supplied by the course author.'),
        panel('Chapter assessment and cumulative project', 'Locked until authored requirements and marking rules are published.'),
      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [panel('Python Foundations', 'Independent study • 11 planned chapters • content in development'), for (var i = 0; i < chapters.length; i++) ListTile(leading: CircleAvatar(child: Text('$i')), title: Text(chapters[i]), subtitle: const Text('Draft'), trailing: const Icon(Icons.chevron_right), onTap: () => setState(() { chapter = i; }))]);
    }
    if (section == 'Notebook') return Column(children: [panel('Your session notes', 'Persistent private notes, search and export will be connected in a later phase.'), for (final entry in notes.entries.where((e) => e.value.isNotEmpty)) panel(entry.key, entry.value)]);
    if (section == 'Sources & Acknowledgements') return panel('Sources & Acknowledgements', 'A separate admin-managed page for sources actually used, attribution and licences. Planned reference sources include Harvard CS50P, Helsinki, MIT and Beijing Institute of Technology. These are references, not endorsements. Detailed published acknowledgements follow content review.');
    if (section == 'Privacy Policy') return panel('Privacy Policy — draft', 'Admin will publish the operator’s reviewed policy here, covering accounts, private notes, submissions, notifications, retention and user rights. This preview has no backend data collection.');
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
    return Scaffold(key: scaffoldKey, appBar: AppBar(title: Text(section), actions: const [Padding(padding: EdgeInsets.all(16), child: Text('Phase 1 preview'))]),
      drawer: wide ? null : Drawer(child: Builder(builder: (_) => navigation())),
      body: Row(children: [if (wide) SizedBox(width: 250, child: navigation()), Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(wide ? 32 : 16), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050), child: body()))))]));
  });
}
