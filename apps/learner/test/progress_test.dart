import 'package:flutter_test/flutter_test.dart';
import 'package:bajinka_academy/learner_store.dart';
void main() {
  test('optional work does not inflate required course completion', () {
    final store = LearnerStore(null);
    store.activities = [
      {'id': 'required', 'required': true},
      {'id': 'optional', 'required': false},
    ];
    store.progress = [
      {'activity_id': 'optional', 'completed_at': '2026-10-11', 'points': 10},
      {'activity_id': 'required', 'completed_at': null, 'points': 0},
    ];
    expect(store.requiredCount, 1);
    expect(store.completedCount, 0);
    store.progress[1]['completed_at'] = '2026-10-11';
    expect(store.completedCount, 1);
    store.dispose();
  });
}
