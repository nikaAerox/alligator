// Handles Android/iOS notifications, including scheduling reminders
// Playing alarm sound, and processing Taken/Postpone actions.

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_types.dart';

class NotificationService {
  NotificationService();

  static const _channelId = 'medication_reminders_alarm';
  static const _channelName = 'Medication Reminders';
  static const _channelDescription = 'Reminders for scheduled medication times';
  static const _soundName = 'homecoming_samsung_oneui_alarm';
  static const _actionTaken = 'medication_taken';
  static const _actionPostponed = 'medication_postponed';
  static NotificationActionHandler? _actionHandler;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.requestFullScreenIntentPermission();
    }
  }

  void setActionHandler(NotificationActionHandler handler) {
    _actionHandler = handler;
  }

  Future<void> scheduleMedicationReminder({
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledFor,
  }) async {
    final id = _notificationId(scheduleId);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Medication reminder',
      body: 'Time to take $medicationName ($dosage)',
      scheduledDate: tz.TZDateTime.from(scheduledFor, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: const RawResourceAndroidNotificationSound(_soundName),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              _actionTaken,
              'Taken',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              _actionPostponed,
              'Postpone',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: scheduleId,
    );
  }

  Future<void> cancelMedicationReminder(String scheduleId) {
    return _plugin.cancel(id: _notificationId(scheduleId));
  }

  Future<void> cancelAllMedicationReminders() {
    return _plugin.cancelAll();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _dispatchNotificationResponse(response);
  }

  static void _dispatchNotificationResponse(NotificationResponse response) {
    final scheduleId = response.payload;
    if (scheduleId == null || scheduleId.isEmpty) {
      return;
    }

    final action = switch (response.actionId) {
      _actionTaken => 'taken',
      _actionPostponed => 'postponed',
      _ => null,
    };

    if (action == null) {
      return;
    }

    _actionHandler?.call(
      NotificationAction(scheduleId: scheduleId, action: action),
    );
  }

  int _notificationId(String source) {
    return source.hashCode & 0x7fffffff;
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService._dispatchNotificationResponse(response);
}
