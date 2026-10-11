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
    theme: academyTheme(Brightness.light), darkTheme: academyTheme(Brightness.dark),

    home: LearnerShell(client: client),
  );
}

const teal = Color(0xff0eaaa7);
const navy = Color(0xff1e2e52);
const border = Color(0xffe0e3eb);
ThemeData academyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(useMaterial3: true, brightness: brightness, fontFamily: 'Arial', colorScheme: ColorScheme.fromSeed(seedColor: teal, brightness: brightness).copyWith(primary: teal, surface: dark ? const Color(0xff172033) : Colors.white));
  return base.copyWith(scaffoldBackgroundColor: dark ? const Color(0xff101827) : const Color(0xfffbfcfd),
    textTheme: base.textTheme.apply(bodyColor: dark ? const Color(0xffe2e8f0) : navy, displayColor: dark ? Colors.white : navy),
    dividerColor: border, appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xff101827) : const Color(0xfffbfcfd), foregroundColor: dark ? Colors.white : navy, elevation: 0, surfaceTintColor: Colors.transparent),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
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
  bool dark = false;
  final pageScroll = ScrollController();
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
    if (pageScroll.hasClients) pageScroll.jumpTo(0);
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
    const SizedBox(height: 6), const Text('Your private Python study space. Learn at your own pace — no deadlines, no streak penalties.', style: TextStyle(color: Color(0xff69758e), fontSize: 16)),
    const SizedBox(height: 28),
    panel('Continue learning', store.lastTopic ?? 'Start with Running and saving Python programs.', action: () => openTopic(store.lastTopic ?? topics.first), button: 'Resume your last topic  →', icon: Icons.school_outlined),
    const SizedBox(height: 16),
    surface(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [Icon(Icons.menu_book_outlined, color: teal, size: 20), SizedBox(width: 10), Expanded(child: Text('Python Foundations: Independent Study', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 8), const Text('In development', style: TextStyle(fontSize: 12, color: Color(0xff69758e))),
      const SizedBox(height: 20), const Text('Your progress', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), LinearProgressIndicator(value: store.countStage('reviewed') / topics.length, minHeight: 8, backgroundColor: const Color(0xffeef2f6), borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 8), Text('${store.countStage('reviewed')}/${topics.length} opening chapter topics self-reviewed', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xff69758e))),
      Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => select('My courses'), child: const Text('Open my course  →'))),
    ])),
    const SizedBox(height: 30), const Text('Learning record', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    const SizedBox(height: 16), Wrap(spacing: 16, runSpacing: 12, children: [metric('Topics viewed', store.countStage('viewed')), metric('Practised', store.countStage('practised')), metric('Self-reviewed', store.countStage('reviewed')), metric('Topic notes', store.drafts.values.where((d) => (d['notes'] as String? ?? '').isNotEmpty).length)]),
    const SizedBox(height: 20), const Text('Saved on this device. Assessed completion and account sync will be connected later.', style: TextStyle(color: Color(0xff69758e), fontSize: 13)),
  ]);
  Widget metric(String label, int value) => SizedBox(width: 180, child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text(label, style: const TextStyle(color: Color(0xff69758e)))])));
  void select(String value) { autosave?.cancel(); if (topic != null) unawaited(store.save(topic!)); setState(() { section = value; chapter = null; topic = null; }); if (pageScroll.hasClients) pageScroll.jumpTo(0); }
  @override
  void dispose() { autosave?.cancel(); store.removeListener(refresh); store.dispose(); note.dispose(); code.dispose(); pageScroll.dispose(); super.dispose(); }
  Widget navigation() => ListView(children: [
    const Padding(padding: EdgeInsets.all(24), child: Text('Bajinka Python Academy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
    for (var i = 0; i < sections.length; i++) ListTile(leading: Icon([Icons.dashboard_outlined, Icons.menu_book_outlined, Icons.edit_note, Icons.folder_outlined, Icons.description_outlined, Icons.fact_check_outlined, Icons.insights_outlined, Icons.workspace_premium_outlined, Icons.link, Icons.settings_outlined, Icons.info_outline, Icons.privacy_tip_outlined][i], size: 20), selected: section == sections[i], selectedTileColor: teal.withValues(alpha: 0.08), title: Text(sections[i] == 'Home' ? 'Dashboard' : sections[i] == 'My courses' ? 'My Course' : sections[i] == 'Practice' ? 'Practice and Homework' : sections[i]), onTap: () { select(sections[i]); scaffoldKey.currentState?.closeDrawer(); }),
  ]);
  Widget surface(Widget child, {double padding = 24}) => Container(width: double.infinity, padding: EdgeInsets.all(padding), decoration: BoxDecoration(color: dark ? const Color(0xff172033) : Colors.white, border: Border.all(color: dark ? const Color(0xff334155) : border), borderRadius: BorderRadius.circular(6)), child: child);
  Widget panel(String title, String body, {VoidCallback? action, String? button, IconData? icon}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [if (icon != null) ...[Icon(icon, color: teal, size: 22), const SizedBox(width: 12)], Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))]), const SizedBox(height: 12), Text(body, style: const TextStyle(height: 1.55)), if (action != null) Padding(padding: const EdgeInsets.only(top: 8), child: TextButton(onPressed: action, child: Text(button ?? 'Open')))])));
  Widget lessonContent() => panel(lessonTab == 'Learn' ? 'Lesson content' : lessonTab, 'Your existing Base44 course content is awaiting approved import. My Notes and My Code are available now.');
  Widget studyProgress() => surface(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR PROGRESS', style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Color(0xff69758e))), const SizedBox(height: 10), Wrap(spacing: 22, runSpacing: 12, children: [for (final stage in ['viewed', 'practised', 'reviewed', 'demonstrated']) InkWell(onTap: stage == 'demonstrated' ? null : () => store.mark(topic!, stage, store.draft(topic!)[stage] != true), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(store.draft(topic!)[stage] == true ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 16, color: stage == 'demonstrated' ? const Color(0xffa0a9b8) : teal), const SizedBox(width: 7), Text(stage == 'reviewed' ? 'Self-reviewed' : stage == 'demonstrated' ? 'Demonstrated understanding' : stage[0].toUpperCase() + stage.substring(1), style: const TextStyle(fontSize: 12, color: Color(0xff69758e)))]))])]), padding: 16);
  Widget body() {
    if (section == 'Home' || section == 'Progress') return homeProgress();
    if (section == 'My courses') {
      if (topic != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(onPressed: () => setState(() { topic = null; }), child: const Text('← Back to topics')),
        Text(topic!, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16), const Text('My Course / Functions and Variables', style: TextStyle(color: Color(0xff69758e), fontSize: 12)),
        const SizedBox(height: 20),
        Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: border))), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final label in ['Learn', 'Classwork', 'Homework', 'Challenge', 'Project', 'Assessment', 'My Notes', 'My Code', 'Resources']) InkWell(onTap: () => setState(() { lessonTab = label; }), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: lessonTab == label ? teal : Colors.transparent, width: 2))), child: Text(label, style: TextStyle(fontSize: 14, color: lessonTab == label ? (dark ? Colors.white : navy) : const Color(0xff636b7e), fontWeight: lessonTab == label ? FontWeight.w600 : FontWeight.w400))))]))),
        const SizedBox(height: 20), if (lessonTab == 'Learn') ...[studyProgress(), const SizedBox(height: 26)],
        if (lessonTab == 'My Notes' || lessonTab == 'My Code') ...[
          Text(lessonTab, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: lessonTab == 'My Notes' ? note : code, minLines: lessonTab == 'My Notes' ? 8 : 14, maxLines: 30, style: lessonTab == 'My Code' ? const TextStyle(fontFamily: 'monospace') : null, decoration: InputDecoration(hintText: lessonTab == 'My Notes' ? 'What did you learn? Write an example in your own words…' : '# Write your Python code here', filled: true, fillColor: Colors.white, border: const OutlineInputBorder()), enabled: !store.loading, onChanged: (_) => editDraft()),
          const SizedBox(height: 12), Text(store.draft(topic!)['status'] as String),
          Wrap(spacing: 12, children: [FilledButton.icon(onPressed: () => store.save(topic!), icon: const Icon(Icons.save_outlined), label: const Text('Save on device')), OutlinedButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: lessonTab == 'My Notes' ? note.text : code.text)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied — paste into a file to keep a backup.'))); }, icon: const Icon(Icons.copy), label: const Text('Copy'))]),
          if (lessonTab == 'My Code') panel('Python workspace', 'Your draft saves locally. Code execution and automatic marking are not connected yet.'),
        ] else lessonContent(),

      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('My Course', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 20),
        panel('Python Foundations: Independent Study', 'In development • 11 planned chapters • 8 opening chapter topics'),
        const SizedBox(height: 20),
        for (var i = 0; i < chapters.length; i++) ...[
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(children: [SizedBox(width: 32, child: Text('$i.', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xff69758e)))), Expanded(child: Text(chapters[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), const Text('DRAFT', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xffa0a9b8)))])),
          if (i == 0) Padding(padding: const EdgeInsets.only(left: 12), child: Container(decoration: const BoxDecoration(border: Border(left: BorderSide(color: border))), child: Column(children: [for (final title in topics) ListTile(dense: true, minLeadingWidth: 12, leading: const Icon(Icons.radio_button_unchecked, size: 15, color: Color(0xffb8bfcc)), title: Text(title, style: TextStyle(fontSize: 14, color: dark ? Colors.white : navy)), onTap: () => openTopic(title))]))),
        ],
      ]);
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
    final wide = bounds.maxWidth >= 700;
    return Theme(data: academyTheme(dark ? Brightness.dark : Brightness.light), child: Scaffold(key: scaffoldKey,
      appBar: AppBar(centerTitle: true, toolbarHeight: 60, title: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.school_outlined, color: teal, size: 20), const SizedBox(width: 8), Flexible(child: Text('Bajinka Python Academy', style: TextStyle(fontSize: wide ? 16 : 14, fontWeight: FontWeight.w700)))]), bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)), actions: [IconButton(tooltip: dark ? 'Light mode' : 'Dark mode', onPressed: () => setState(() { dark = !dark; }), icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20))]),
      drawer: Drawer(backgroundColor: dark ? const Color(0xff101827) : const Color(0xfffbfcfd), shape: const RoundedRectangleBorder(), child: navigation()),
      body: SingleChildScrollView(controller: pageScroll, padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: wide ? 32 : 24), child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: section == 'Home' || section == 'Progress' ? 1200 : 736), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (store.loading) const LinearProgressIndicator(), if (store.message.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(store.message)), body(), const SizedBox(height: 48), const Divider(), Wrap(spacing: 16, children: [TextButton(onPressed: () => select('Sources & Acknowledgements'), child: const Text('Sources & Acknowledgements')), TextButton(onPressed: () => select('Privacy Policy'), child: const Text('Privacy Policy'))])])))),
    ));
  });
}
