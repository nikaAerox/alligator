import 'package:flutter/foundation.dart';

import '../notifications/notification_service.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';
import '../models/medication_schedule.dart';
import '../storage/app_storage_service.dart';

class MedicationStore extends ChangeNotifier {
  MedicationStore({
    List<Medication>? initialMedications,
    List<MedicationSchedule>? initialSchedules,
    List<MedicationHistory>? initialHistories,
    this._storage,
    this._notifications,
  }) : _medications = List.of(initialMedications ?? const []),
       _schedules = List.of(initialSchedules ?? const []),
       _histories = List.of(initialHistories ?? const []) {
    _notifications?.setActionHandler(_handleNotificationAction);
    _restorePendingNotifications();
  }

  factory MedicationStore.seeded({
    AppStorageService? storage,
    NotificationService? notifications,
  }) {
    return MedicationStore(
      storage: storage,
      notifications: notifications,
      initialMedications: storage?.loadMedications(),
      initialSchedules: storage?.loadSchedules(),
      initialHistories: storage?.loadMedicationHistories(),
    );
  }

  final List<Medication> _medications;
  final List<MedicationSchedule> _schedules;
  final List<MedicationHistory> _histories;
  final AppStorageService? _storage;
  final NotificationService? _notifications;
  String? _currentPatientId;

  List<Medication> get medications {
    return List.unmodifiable(_medicationsForCurrentPatient());
  }

  List<MedicationHistory> get medicationHistories {
    final patientId = _currentPatientId;
    final items =
        _histories.where((history) => history.patientId == patientId).toList()
          ..sort((a, b) => b.actionAt.compareTo(a.actionAt));
    return List.unmodifiable(items);
  }

  List<ScheduledMedication> get scheduledMedications {
    final items = <ScheduledMedication>[];

    for (final schedule in _schedules) {
      final medication = _findCurrentMedication(schedule.medicationId);
      if (medication != null) {
        items.add(
          ScheduledMedication(schedule: schedule, medication: medication),
        );
      }
    }

    items.sort(
      (a, b) => a.schedule.timeInMinutes.compareTo(b.schedule.timeInMinutes),
    );
    return List.unmodifiable(items);
  }

  void setCurrentPatientId(String? patientId) {
    if (_currentPatientId == patientId) {
      return;
    }
    _currentPatientId = patientId;
    _notifications?.cancelAllMedicationReminders();
    if (patientId != null) {
      syncOverduePendingReminders();
      _restorePendingNotifications();
    }
    notifyListeners();
  }

  void addMedication({
    required String name,
    required String dosage,
    required String quantity,
    required String duration,
    required MedicationTiming timing,
    required String instructions,
    required bool isActive,
    Uint8List? imageBytes,
  }) {
    final patientId = _currentPatientId;
    if (patientId == null) {
      return;
    }

    final medication = Medication(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      patientId: patientId,
      name: name.trim(),
      dosage: dosage.trim(),
      quantity: quantity.trim(),
      duration: duration.trim(),
      timing: timing,
      instructions: instructions.trim(),
      isActive: isActive,
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
    );

    _medications.insert(0, medication);
    _saveMedicationData();
    notifyListeners();
  }

  void updateMedication(Medication medication) {
    final index = _medications.indexWhere((item) => item.id == medication.id);
    if (index == -1) {
      return;
    }

    _medications[index] = medication.copyWith(
      patientId: medication.patientId,
      name: medication.name.trim(),
      dosage: medication.dosage.trim(),
      quantity: medication.quantity.trim(),
      duration: medication.duration.trim(),
      instructions: medication.instructions.trim(),
      isActive: medication.isActive,
      imageBytes: medication.imageBytes,
    );
    _saveMedicationData();
    notifyListeners();
  }

  void deleteMedication(String id) {
    final removedScheduleIds = _schedules
        .where((schedule) => schedule.medicationId == id)
        .map((schedule) => schedule.id)
        .toList();

    _medications.removeWhere((medication) => medication.id == id);
    _schedules.removeWhere((schedule) => schedule.medicationId == id);
    _histories.removeWhere((history) => history.medicationId == id);
    for (final scheduleId in removedScheduleIds) {
      _notifications?.cancelMedicationReminder(scheduleId);
    }
    _saveMedicationData();
    notifyListeners();
  }

  void addSchedule({required String medicationId, required int timeInMinutes}) {
    if (_currentPatientId == null) {
      return;
    }
    final schedule = MedicationSchedule(
      id: 'schedule-${DateTime.now().microsecondsSinceEpoch}',
      medicationId: medicationId,
      timeInMinutes: timeInMinutes,
      status: MedicationStatus.pending,
      createdAt: DateTime.now(),
      scheduledFor: _nextReminderTime(timeInMinutes),
    );
    _schedules.add(schedule);
    _storage?.saveSchedules(_schedules);
    _scheduleNotification(schedule);
    notifyListeners();
  }

  void updateScheduleStatus(String scheduleId, MedicationStatus status) {
    final index = _schedules.indexWhere((item) => item.id == scheduleId);
    if (index == -1) {
      return;
    }

    final current = _schedules[index];
    final updatedSchedule = status == MedicationStatus.pending
        ? current.copyWith(
            status: status,
            scheduledFor: _nextReminderTime(current.timeInMinutes),
          )
        : current.copyWith(status: status);
    _schedules[index] = updatedSchedule;
    if (status != MedicationStatus.pending) {
      _addHistory(updatedSchedule, status);
    }
    _storage?.saveSchedules(_schedules);
    _storage?.saveMedicationHistories(_histories);
    if (status == MedicationStatus.pending) {
      _scheduleNotification(updatedSchedule);
    } else {
      _notifications?.cancelMedicationReminder(scheduleId);
    }
    notifyListeners();
  }

  void deleteSchedule(String scheduleId) {
    _schedules.removeWhere((schedule) => schedule.id == scheduleId);
    _storage?.saveSchedules(_schedules);
    _notifications?.cancelMedicationReminder(scheduleId);
    notifyListeners();
  }

  void syncOverduePendingReminders({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    var changed = false;

    for (var index = 0; index < _schedules.length; index++) {
      final schedule = _schedules[index];
      if (schedule.status != MedicationStatus.pending) {
        continue;
      }

      final dueAt = schedule.scheduledFor ?? _nextReminderTime(
        schedule.timeInMinutes,
        currentTime,
      );

      if (schedule.scheduledFor == null) {
        _schedules[index] = schedule.copyWith(scheduledFor: dueAt);
        changed = true;
      }

      if (!currentTime.isBefore(dueAt.add(const Duration(minutes: 5)))) {
        _schedules[index] = _schedules[index].copyWith(
          status: MedicationStatus.missed,
        );
        _addHistory(_schedules[index], MedicationStatus.missed);
        _notifications?.cancelMedicationReminder(schedule.id);
        changed = true;
      }
    }

    if (changed) {
      _storage?.saveSchedules(_schedules);
      _storage?.saveMedicationHistories(_histories);
      notifyListeners();
    }
  }

  void _saveMedicationData() {
    _storage?.saveMedications(_medications);
    _storage?.saveSchedules(_schedules);
    _storage?.saveMedicationHistories(_histories);
  }

  List<Medication> _medicationsForCurrentPatient() {
    final patientId = _currentPatientId;
    if (patientId == null) {
      return const [];
    }
    return _medications
        .where((medication) => medication.patientId == patientId)
        .toList();
  }

  void _scheduleNotification(MedicationSchedule schedule) {
    final medication = _findCurrentMedication(schedule.medicationId);
    if (medication == null || !medication.isActive) {
      return;
    }

    final scheduledFor = schedule.scheduledFor ??
        _nextReminderTime(schedule.timeInMinutes);

    _notifications?.scheduleMedicationReminder(
      scheduleId: schedule.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      scheduledFor: scheduledFor,
    );
  }

  void _restorePendingNotifications() {
    final now = DateTime.now();
    var changed = false;
    for (final schedule in _schedules) {
      if (schedule.status == MedicationStatus.pending &&
          _findCurrentMedication(schedule.medicationId) != null) {
        final dueAt = schedule.scheduledFor ?? _nextReminderTime(
          schedule.timeInMinutes,
          now,
        );
        if (schedule.scheduledFor == null) {
          final index = _schedules.indexWhere((item) => item.id == schedule.id);
          if (index != -1) {
            _schedules[index] = _schedules[index].copyWith(scheduledFor: dueAt);
            changed = true;
          }
        }
        if (dueAt.isAfter(now)) {
          _scheduleNotification(schedule.copyWith(scheduledFor: dueAt));
        }
      }
    }

    if (changed) {
      _storage?.saveSchedules(_schedules);
    }
  }

  void _handleNotificationAction(NotificationAction action) {
    final status = switch (action.action) {
      'taken' => MedicationStatus.taken,
      'postponed' => MedicationStatus.postponed,
      'missed' => MedicationStatus.missed,
      _ => null,
    };

    if (status == null) {
      return;
    }

    updateScheduleStatus(action.scheduleId, status);
  }

  DateTime _nextReminderTime(int timeInMinutes, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final hour = timeInMinutes ~/ 60;
    final minute = timeInMinutes % 60;
    var scheduled = DateTime(
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

  void _addHistory(MedicationSchedule schedule, MedicationStatus status) {
    final medication = _findCurrentMedication(schedule.medicationId);
    if (medication == null) {
      return;
    }

    _histories.insert(
      0,
      MedicationHistory(
        id: 'history-${DateTime.now().microsecondsSinceEpoch}',
        patientId: medication.patientId,
        medicationId: medication.id,
        scheduleId: schedule.id,
        medicationName: medication.name,
        dosage: medication.dosage,
        status: status,
        actionAt: DateTime.now(),
      ),
    );
  }

  Medication? _findCurrentMedication(String id) {
    final patientId = _currentPatientId;
    if (patientId == null) {
      return null;
    }
    for (final medication in _medications) {
      if (medication.id == id && medication.patientId == patientId) {
        return medication;
      }
    }
    return null;
  }
}
