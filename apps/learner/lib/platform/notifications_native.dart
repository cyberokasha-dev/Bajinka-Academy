import 'package:flutter_local_notifications/flutter_local_notifications.dart';
final _plugin = FlutterLocalNotificationsPlugin();
Future<String> enableReminders() async {
  await _plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  final allowed = await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  if (allowed != true) return 'Notification permission was not granted.';
  await _plugin.periodicallyShow(300, 'Time for a little Python', 'Open Bajinka Academy and continue your next topic.', RepeatInterval.daily, const NotificationDetails(android: AndroidNotificationDetails('study_reminders', 'Study reminders', channelDescription: 'Daily learning reminders', importance: Importance.defaultImportance)), androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
  return 'Daily reminders enabled. Android chooses the delivery time; battery settings can delay delivery.';
}
Future<void> disableReminders() => _plugin.cancel(300);

Future<void> resumeReminders() async { /* Android retains the scheduled reminder. */ }
