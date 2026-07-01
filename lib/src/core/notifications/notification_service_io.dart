import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleMedicationReminder({
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required int timeInMinutes,
  }) async {
    final id = _notificationId(scheduleId);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Medication reminder',
      body: 'Time to take $medicationName ($dosage)',
      scheduledDate: _nextInstanceOfTime(timeInMinutes),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders for scheduled medication times',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedicationReminder(String scheduleId) {
    return _plugin.cancel(id: _notificationId(scheduleId));
  }

  tz.TZDateTime _nextInstanceOfTime(int timeInMinutes) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = timeInMinutes ~/ 60;
    final minute = timeInMinutes % 60;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  int _notificationId(String source) {
    return source.hashCode & 0x7fffffff;
  }
}
