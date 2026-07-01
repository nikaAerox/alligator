class NotificationService {
  Future<void> initialize() async {}

  Future<void> scheduleMedicationReminder({
    required String scheduleId,
    required String medicationName,
    required String dosage,
    required int timeInMinutes,
  }) async {}

  Future<void> cancelMedicationReminder(String scheduleId) async {}
}
