import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'course_content.dart';

abstract class DeviceStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}
class PreferenceStorage implements DeviceStorage {
  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync get prefs => _prefs ??= SharedPreferencesAsync();
  @override Future<String?> read(String key) => prefs.getString(key);
  @override Future<void> write(String key, String value) => prefs.setString(key, value);
}
class MemoryStorage implements DeviceStorage {
  final values = <String, String>{};
  @override Future<String?> read(String key) async => values[key];
  @override Future<void> write(String key, String value) async { values[key] = value; }
}

class LearnerStore extends ChangeNotifier {
  LearnerStore({DeviceStorage? storage}) : storage = storage ?? PreferenceStorage();
  final DeviceStorage storage;
  static const key = 'academy.guest.v4';
  final drafts = <String, Map<String, dynamic>>{};
  final attempts = <String, List<Map<String, dynamic>>>{};
  final weak = <String>{};
  final reviews = <String, bool>{};
  final certificates = <Map<String, dynamic>>[];
  String name = '', message = '', saveStatus = 'Saved on this device';
  String? lastTopic;
  String startedAt = DateTime.now().toIso8601String();
  bool loading = true, dark = false, reminders = false;
  double textScale = 1;
  Future<void> pending = Future.value();
  bool alive = true;
  void changed() { if (alive) notifyListeners(); }
  Future<void> start() async {
    try {
      final cached = await storage.read(key);
      if (cached != null) {
        applySnapshot(validateBackup(cached));
      } else {
        final old = await storage.read('academy.guest.v3');
        if (old != null) {
          final previous = Map<String, dynamic>.from(jsonDecode(old));
          name = previous['name'] as String? ?? '';
          for (final entry in Map<String, dynamic>.from(previous['drafts'] ?? {}).entries) {
            final matches = starterTopics.where((t) => t.title == entry.key);
            if (matches.isNotEmpty) drafts[matches.first.id] = Map<String, dynamic>.from(entry.value);
          }
          final matches = starterTopics.where((t) => t.title == previous['lastTopic']);
          if (matches.isNotEmpty) lastTopic = matches.first.id;
          await storage.write(key, exportBackup());
        }
      }
    } catch (_) { message = 'Device storage could not be loaded. Download a backup of important work before leaving.'; saveStatus = 'Storage unavailable'; }
    loading = false; changed();
  }
  Map<String, dynamic> draft(String id) => drafts[id] ?? {'notes': '', 'code': '', 'input': '', 'viewed': false, 'practised': false, 'reviewed': false};
  void edit(String id, {String? notes, String? code, String? input, String? response, bool? helpUsed, String? revision, Map<String,dynamic>? lastRun}) {
    drafts[id] = {...draft(id), if (notes != null) 'notes': notes, if (code != null) 'code': code, if (code != null) 'codeEdited': true, if (lastRun != null) 'lastRun': lastRun, if (input != null) 'input': input, if (response != null) 'response': response, if (helpUsed != null) 'helpUsed': helpUsed, if (revision != null) 'editorRevision': revision, 'updatedAt': DateTime.now().toIso8601String()};
    unawaited(save());
  }
  Future<void> visit(String id) async {
    lastTopic = id;
    drafts[id] = {...draft(id), 'viewed': true};
    await save();
  }
  Future<void> mark(String id, String stage, bool value) async {
    if (!['viewed', 'practised', 'reviewed'].contains(stage)) return;
    drafts[id] = {...draft(id), stage: value}; await save();
  }
  Future<void> reviewTopic(String id, bool value) async {
    if (value) { weak.add(id); } else { weak.remove(id); }
    await save();
  }
  Future<void> setReview(String id, bool value) async { reviews[id] = value; await save(); }
  Future<void> preferences({String? displayName, bool? night, double? scale, bool? reminder}) async {
    if (displayName != null) name = displayName.trim();
    if (night != null) dark = night;
    if (scale != null) textScale = scale.clamp(1, 1.4);
    if (reminder != null) reminders = reminder;
    await save();
  }
  Future<void> save() {
    saveStatus = 'Saving on this device…'; changed();
    final snapshot = exportBackup();
    pending = pending.then((_) async {
      try { await storage.write(key, snapshot); saveStatus = 'Saved on this device'; message = ''; }
      catch (_) { saveStatus = 'Save failed — work is still open'; message = 'Device storage failed. Download a backup before closing this page.'; }
      changed();
    });
    return pending;
  }
  Future<void> recordAttempt(Exercise exercise, Map<String, dynamic> result, {String answer = '', bool helpUsed = false}) async {
    final record = <String, dynamic>{'id': '${DateTime.now().microsecondsSinceEpoch}', 'exercise': exercise.id, 'topic': exercise.topic, 'version': 1, 'submittedAt': DateTime.now().toIso8601String(), 'answer': answer, ...result, 'helpUsed': helpUsed || draft('activity:${exercise.id}')['helpUsed'] == true};
    final history = attempts.putIfAbsent(exercise.id, () => []);
    history.add(record);
    if (history.length > 30) history.removeAt(0);
    drafts[exercise.topic] = {...draft(exercise.topic), 'practised': true};
    if (result['status'] == 'graded' && result['passed'] != true) weak.add(exercise.topic);
    await save();
  }
  bool passed(String id) => attempts[id]?.any((a) => a['status'] == 'graded' && a['passed'] == true) ?? false;
  int get requiredCount => exercises.where((e) => e.required).length;
  int get completedCount => exercises.where((e) => e.required && passed(e.id)).length;
  int get points => exercises.where((e) => passed(e.id)).length * 10;
  int countStage(String stage) => drafts.values.where((d) => d[stage] == true).length;
  int get notesCount => drafts.values.where((d) => (d['notes'] as String? ?? '').trim().isNotEmpty).length;
  double get progress => requiredCount == 0 ? 0 : completedCount / requiredCount;
  bool get openingRecordEligible => requiredCount > 0 && completedCount == requiredCount && reviews['opening-project'] == true && assessmentBest >= 80;
  bool get fullCourseEligible => false; // Full-course assessment and review requirements are not published yet.
  double get assessmentBest => (attempts['opening-assessment'] ?? []).fold<double>(0, (value, a) => (a['score'] as num? ?? 0).toDouble() > value ? (a['score'] as num).toDouble() : value);
  Future<void> recordAssessment(int score, Map<String, String> answers) async {
    attempts.putIfAbsent('opening-assessment', () => []).add({'id':'${DateTime.now().microsecondsSinceEpoch}', 'submittedAt':DateTime.now().toIso8601String(), 'score':score, 'answers':answers, 'status':'graded', 'version':1});
    await save();
  }
  Map<String,dynamic>? get issuedOpeningRecord {
    for (final record in certificates) { if (record['kind'] == 'opening-study-record') return record; }
    return null;
  }
  Future<Map<String,dynamic>> issueOpeningRecord() async {
    final existing = issuedOpeningRecord;
    if (existing != null) return Map<String,dynamic>.from(existing);
    if (!openingRecordEligible) throw const FormatException('Complete the required checks, assessment and project review first.');
    if (name.trim().isEmpty) throw const FormatException('Confirm your name before issuing your study record.');
    final now = DateTime.now();
    final record = <String,dynamic>{'kind':'opening-study-record','id':'BAJINKA-C0-${now.microsecondsSinceEpoch}','name':name.trim(),'issuedAt':now.toIso8601String(),'startedAt':startedAt,'completed':completedCount,'required':requiredCount,'assessment':assessmentBest,'projectReviewed':true};
    certificates.add(record); await save(); return Map<String,dynamic>.from(record);
  }
  Map<String, dynamic> snapshot() => {'format':'bajinka-device-backup','version':1,'name':name,'lastTopic':lastTopic,'startedAt':startedAt,'dark':dark,'textScale':textScale,'reminders':reminders,'drafts':drafts,'attempts':attempts,'weak':weak.toList(),'reviews':reviews,'certificates':certificates};
  String exportBackup() => const JsonEncoder.withIndent('  ').convert(snapshot());
  static Map<String, dynamic> validateBackup(String raw) {
    if (utf8.encode(raw).length > 5000000) throw const FormatException('Backup exceeds 5 MB.');
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['format'] != 'bajinka-device-backup' || decoded['version'] != 1) throw const FormatException('Not a supported Bajinka backup.');
    if (decoded['drafts'] is! Map || decoded['attempts'] is! Map || decoded['reviews'] is! Map || decoded['weak'] is! List || decoded['certificates'] is! List || decoded['name'] is! String || decoded['startedAt'] is! String) throw const FormatException('Backup fields are invalid.');
    if (decoded['lastTopic'] != null && decoded['lastTopic'] is! String) throw const FormatException('Last topic is invalid.');
    if (DateTime.tryParse(decoded['startedAt'] as String) == null) throw const FormatException('Study date is invalid.');
    if (decoded['dark'] is! bool || decoded['reminders'] is! bool) throw const FormatException('Preferences are invalid.');
    final allowed = courseTopics.map((t) => t.id).toSet()..add('general')..add('opening-assessment')..addAll(exercises.map((e) => 'activity:${e.id}'));
    for (final entry in (decoded['drafts'] as Map).entries) {
      if (!allowed.contains(entry.key) || entry.value is! Map) throw const FormatException('Unknown topic or invalid draft.');
      for (final field in ['notes','code','input','response','editorRevision']) { if ((entry.value as Map)[field] != null && (entry.value as Map)[field] is! String) throw const FormatException('Draft text is invalid.'); }
      final lastRun = (entry.value as Map)['lastRun'];
      if (lastRun != null && (lastRun is! Map || lastRun['output'] is! String || lastRun['error'] is! String || lastRun['code'] is! String || lastRun['recordedAt'] is! String || lastRun['prompts'] is! List || (lastRun['prompts'] as List).any((p) => p is! String))) throw const FormatException('Saved run details are invalid.');
      for (final field in ['viewed','practised','reviewed','helpUsed','codeEdited']) { if ((entry.value as Map)[field] != null && (entry.value as Map)[field] is! bool) throw const FormatException('Draft progress is invalid.'); }
    }
    final validExercises = exercises.map((e) => e.id).toSet()..add('opening-assessment');
    for (final entry in (decoded['attempts'] as Map).entries) {
      if (!validExercises.contains(entry.key) || entry.value is! List || (entry.value as List).any((e) => e is! Map || (e['score'] != null && e['score'] is! num) || e['submittedAt'] is! String || (e['answer'] != null && e['answer'] is! String))) throw const FormatException('Attempts are invalid.');
    }
    for (final history in (decoded['attempts'] as Map).values) {
      for (final attempt in history as List) {
        for (final field in ['passed','helpUsed']) { if (attempt[field] != null && attempt[field] is! bool) throw const FormatException('Attempt flags are invalid.'); }
        if (attempt['feedback'] != null && attempt['feedback'] is! String) throw const FormatException('Attempt feedback is invalid.');
        final tests = attempt['tests'];
        if (tests != null && (tests is! List || tests.any((t) => t is! Map || t['actual'] is! String || t['error'] is! String || t['passed'] is! bool))) throw const FormatException('Attempt test details are invalid.');
      }
    }
    if ((decoded['weak'] as List).any((e) => e is! String || !allowed.contains(e))) throw const FormatException('Revision topics are invalid.');
    if ((decoded['reviews'] as Map).values.any((e) => e is! bool)) throw const FormatException('Review values are invalid.');
    if ((decoded['certificates'] as List).any((e) => e is! Map)) throw const FormatException('Records are invalid.');
    if (decoded['textScale'] is! num || (decoded['textScale'] as num) < 1 || (decoded['textScale'] as num) > 1.4) throw const FormatException('Text size is invalid.');
    return decoded;
  }
  void applySnapshot(Map<String, dynamic> data) {
    name = data['name'] as String;
    lastTopic = data['lastTopic'] as String?;
    if (lastTopic != null && !courseTopics.any((t) => t.id == lastTopic)) lastTopic = null;
    startedAt = data['startedAt'] as String;
    dark = data['dark'] == true; reminders = data['reminders'] == true; textScale = (data['textScale'] as num).toDouble();
    drafts.clear(); attempts.clear(); weak.clear(); reviews.clear(); certificates.clear();
    for (final e in (data['drafts'] as Map).entries) { drafts[e.key as String] = Map<String, dynamic>.from(e.value); }
    for (final e in (data['attempts'] as Map).entries) { attempts[e.key as String] = (e.value as List).map((a) => Map<String, dynamic>.from(a)).toList(); }
    weak.addAll((data['weak'] as List).cast<String>());
    reviews.addAll(Map<String, bool>.from(data['reviews'] as Map));
    certificates.addAll((data['certificates'] as List).map((a) => Map<String, dynamic>.from(a)));
  }
  Future<void> clearDeviceRecord() async {
    await pending;
    final empty = LearnerStore(storage:MemoryStorage());
    applySnapshot(empty.snapshot()); empty.dispose(); await save();
  }
  Future<void> restore(String raw) async { final data = validateBackup(raw); await pending; applySnapshot(data); await save(); }
  @override void dispose() { alive = false; super.dispose(); }
}

Map<String, dynamic> gradeAnswer(Exercise e, String response) {
  if (e.type == 'written') return {'status':'review','passed':false,'feedback':'Saved for rubric review. A keyword match cannot mark this explanation.'};
  final correct = e.type == 'choice' ? response == e.answer : e.accepted.any((a) => a.trim().toLowerCase() == response.trim().toLowerCase());
  return {'status':'graded','passed':correct,'score':correct ? 100 : 0,'feedback':correct ? 'Correct. Explain your reasoning before moving on.' : 'Try again. Review the relevant example and use a hint if needed.'};
}
