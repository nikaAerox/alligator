// Web placeholder for notification handling, since live mobile notifications are not implemented on web.

import 'notification_types.dart';

class NotificationService {
  Future<void> initialize() async {}

  void setActionHandler(NotificationActionHandler handler) {}

  Future<void> scheduleMedicationReminder({
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledFor,
  }) async {}

  Future<void> cancelMedicationReminder(String scheduleId) async {}

  Future<void> cancelAllMedicationReminders() async {}
}
