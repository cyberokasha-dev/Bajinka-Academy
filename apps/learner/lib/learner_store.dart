import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearnerStore extends ChangeNotifier {
  LearnerStore(this.client);
  final SupabaseClient? client;
  final local = SharedPreferencesAsync();
  StreamSubscription<AuthState>? subscription;
  String? owner;
  String displayName = '';
  String? lastTopic;
  String message = '';
  bool loading = false;
  bool reminders = false;
  final Map<String, Map<String, dynamic>> drafts = {};
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> progress = [];
  Future<void> pending = Future.value();
  int epoch = 0;
  int changeCounter = 0;
  bool get signedIn => owner != null;
  int get requiredCount => activities.where((a) => a['required'] == true).length;
  int get completedCount {
    final required = activities.where((a) => a['required'] == true).map((a) => a['id']).toSet();
    return progress.where((p) => p['completed_at'] != null && required.contains(p['activity_id'])).length;
  }
  int get points => progress.fold(0, (sum, p) => sum + (p['points'] as num).toInt());
  Future<void> start() async {
    subscription = client?.auth.onAuthStateChange.listen((event) {
      final next = event.session?.user.id;
      if (next != owner) unawaited(load());
    });
    await load();
  }
  Future<void> load() async {
    final current = ++epoch;
    owner = client?.auth.currentUser?.id;
    drafts.clear(); activities.clear(); progress.clear();
    displayName = ''; lastTopic = null; reminders = false;
    loading = true; message = ''; notifyListeners();
    final uid = owner;
    if (uid == null || client == null) {
      loading = false; notifyListeners(); return;
    }
    try {
      final cached = await local.getString('academy.v2.$uid');
      if (current != epoch) return;
      if (cached != null) {
        final records = Map<String, dynamic>.from(jsonDecode(cached));
        for (final entry in records.entries) drafts[entry.key] = Map<String, dynamic>.from(entry.value);
      }
      final results = await Future.wait<dynamic>([
        Future<dynamic>(() async => await client!.from('academy_profiles').select().eq('user_id', uid).maybeSingle()),
        Future<dynamic>(() async => await client!.from('academy_drafts').select().eq('user_id', uid)),
        Future<dynamic>(() async => await client!.from('academy_activities').select().eq('course_id', 'python-foundations-v1')),
        Future<dynamic>(() async => await client!.from('academy_progress').select().eq('user_id', uid)),
      ]);
      if (current != epoch) return;
      final profile = results[0] as Map<String, dynamic>?;
      displayName = profile?['display_name'] as String? ?? '';
      lastTopic = profile?['last_topic'] as String?;
      reminders = profile?['study_reminders'] == true;
      for (final raw in results[1] as List) {
        final row = Map<String, dynamic>.from(raw);
        final id = row['topic_id'] as String;
        if (drafts[id]?['dirty'] != true) drafts[id] = {...row, 'dirty': false, 'status': 'Saved'};
      }
      activities = (results[2] as List).map((r) => Map<String, dynamic>.from(r)).toList();
      progress = (results[3] as List).map((r) => Map<String, dynamic>.from(r)).toList();
      message = drafts.values.any((d) => d['dirty'] == true) ? 'Recovered local drafts. Open the topic and choose Retry save.' : '';
    } catch (_) {
      if (current == epoch) message = 'Could not load cloud data. Local drafts are available; retry connection.';
    } finally {
      if (current == epoch) { loading = false; notifyListeners(); }
    }
  }
  Future<void> googleLogin() async {
    if (client == null) { message = 'Account service unavailable. Reload and try again.'; notifyListeners(); return; }
    try {
      if (!kIsWeb) {
        message = 'Google login is being configured for Android. Use the learner website for now.';
        notifyListeners(); return;
      }
      await client!.auth.signInWithOAuth(OAuthProvider.google,
        redirectTo: '${Uri.base.origin}${Uri.base.path}',
        queryParams: {'prompt': 'select_account'});
    } catch (_) {
      message = 'Google sign-in is not available yet. The owner must enable Google in Supabase and configure the return URL.';
      notifyListeners();
    }
  }
  Future<void> logout() async {
    await pending;
    await client?.auth.signOut();
    await load();
  }
  Map<String, dynamic> draft(String topic) => drafts[topic] ?? {'notes': '', 'code': '', 'revision': 0, 'dirty': false, 'status': 'No saved draft'};
  void edit(String topic, String notes, String code) {
    if (!signedIn) return;
    final previous = draft(topic);
    drafts[topic] = {...previous, 'notes': notes, 'code': code, 'dirty': true, 'status': 'Unsaved changes', 'change': ++changeCounter};
    final uid = owner!;
    final snapshot = jsonEncode(drafts);
    pending = pending.then((_) async {
      try { await local.setString('academy.v2.$uid', snapshot); }
      catch (_) { if (owner == uid) { message = 'Local backup failed. Copy your work or save to the cloud.'; notifyListeners(); } }
    });
    notifyListeners();
  }
  Future<void> save(String topic) {
    final uid = owner;
    if (uid == null) return Future.value();
    pending = pending.then((_) => _save(topic, uid));
    return pending;
  }
  Future<void> _save(String topic, String uid) async {
    if (owner != uid || client == null) return;
    final current = Map<String, dynamic>.from(draft(topic));
    if (current['dirty'] != true) return;
    drafts[topic]!['status'] = 'Saving'; notifyListeners();
    try {
      final raw = await client!.rpc('academy_save_draft', params: {
        'p_topic': topic, 'p_notes': current['notes'], 'p_code': current['code'], 'p_revision': current['revision'] ?? 0,
      });
      if (owner != uid) return;
      final row = Map<String, dynamic>.from(raw);
      if (drafts[topic]?['change'] == current['change']) {
        drafts[topic] = {...row, 'dirty': false, 'status': 'Saved', 'change': current['change']};
      } else {
        drafts[topic]!['revision'] = row['revision'];
        drafts[topic]!['status'] = 'Unsaved changes';
      }
      await local.setString('academy.v2.$uid', jsonEncode(drafts));
    } on PostgrestException catch (e) {
      if (owner == uid) drafts[topic]!['status'] = e.message.contains('DRAFT_CONFLICT')
        ? 'Conflict: newer cloud version exists. Copy your changes before loading cloud version.'
        : 'Save failed — local draft retained';
    } catch (_) {
      if (owner == uid) drafts[topic]!['status'] = 'Offline or save failed — local draft retained';
    }
    if (owner == uid) notifyListeners();
  }
  Future<void> loadCloudDraft(String topic) async {
    final uid = owner;
    if (uid == null || client == null) return;
    await pending;
    try {
      final row = await client!.from('academy_drafts').select().eq('user_id', uid).eq('topic_id', topic).maybeSingle();
      if (owner != uid) return;
      drafts[topic] = {...?row, 'notes': row?['notes'] ?? '', 'code': row?['code'] ?? '', 'revision': row?['revision'] ?? 0, 'dirty': false, 'status': 'Cloud version loaded'};
      await local.setString('academy.v2.$uid', jsonEncode(drafts));
    } catch (_) { message = 'Cloud version could not be loaded.'; }
    notifyListeners();
  }
  Future<void> profile({String? name, String? topic, bool? reminder}) async {
    final uid = owner;
    if (uid == null || client == null) return;
    final values = {'user_id': uid, if (name != null) 'display_name': name.trim(), if (topic != null) 'last_topic': topic, if (reminder != null) 'study_reminders': reminder, 'updated_at': DateTime.now().toUtc().toIso8601String()};
    try {
      await client!.from('academy_profiles').upsert(values);
      if (owner != uid) return;
      if (name != null) displayName = name.trim();
      if (topic != null) lastTopic = topic;
      if (reminder != null) reminders = reminder;
    } catch (_) { message = 'Account preferences could not be saved. Try again.'; }
    notifyListeners();
  }
  @override
  void dispose() { subscription?.cancel(); super.dispose(); }
}
