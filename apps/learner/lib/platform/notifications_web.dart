import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
Timer? _timer;
Future<String> enableReminders() async {
  try {
    final permission = (await web.Notification.requestPermission().toDart).toDart;
    if (permission != 'granted') return 'Notification permission was not granted.';
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) { web.Notification('A little Python practice', web.NotificationOptions(body: 'Continue your next topic in Bajinka Academy.')); });
    web.Notification('Study reminders enabled', web.NotificationOptions(body: 'A reminder every 30 minutes while this page stays open.'));
    return 'Reminders enabled while this page is open. Closed-browser reminders need push delivery, which is deferred.';
  } catch (_) { return 'This browser does not support notifications. You can still use the study dashboard.'; }
}
Future<void> disableReminders() async { _timer?.cancel(); _timer = null; }

Future<void> resumeReminders() async { try { if (web.Notification.permission == 'granted') { _timer?.cancel(); _timer = Timer.periodic(const Duration(minutes: 30), (_) { web.Notification('A little Python practice', web.NotificationOptions(body: 'Continue your next topic in Bajinka Academy.')); }); } } catch (_) {} }
