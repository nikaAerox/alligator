import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../storage/app_storage_service.dart';

class MedicationStore extends ChangeNotifier {
  MedicationStore({
    List<Medication>? initialMedications,
    List<MedicationSchedule>? initialSchedules,
    this._storage,
  }) : _medications = List.of(initialMedications ?? const []),
       _schedules = List.of(initialSchedules ?? const []);

  factory MedicationStore.seeded({AppStorageService? storage}) {
    final now = DateTime.now();

    const metforminId = 'med-1';
    const amlodipineId = 'med-2';
    const vitaminCId = 'med-3';

    return MedicationStore(
      storage: storage,
      initialMedications:
          storage?.loadMedications() ??
          [
            Medication(
              id: metforminId,
              name: 'Metformin',
              dosage: '1 tablet',
              quantity: '30 tablets',
              duration: '1 Jun - 30 Jun',
              timing: MedicationTiming.afterMeal,
              instructions: 'Take with dinner.',
              isActive: true,
              createdAt: now,
            ),
            Medication(
              id: amlodipineId,
              name: 'Amlodipine',
              dosage: '1 tablet',
              quantity: '30 tablets',
              duration: '-',
              timing: MedicationTiming.morning,
              instructions: 'Take once every morning.',
              isActive: true,
              createdAt: now,
            ),
            Medication(
              id: vitaminCId,
              name: 'Vitamin C',
              dosage: '2 tablet',
              quantity: '60 tablets',
              duration: '-',
              timing: MedicationTiming.afternoon,
              instructions: 'Take once daily.',
              isActive: true,
              createdAt: now,
            ),
          ],
      initialSchedules:
          storage?.loadSchedules() ??
          [
            MedicationSchedule(
              id: 'schedule-1',
              medicationId: amlodipineId,
              timeInMinutes: 8 * 60,
              status: MedicationStatus.pending,
              createdAt: now,
            ),
            MedicationSchedule(
              id: 'schedule-2',
              medicationId: vitaminCId,
              timeInMinutes: 13 * 60,
              status: MedicationStatus.taken,
              createdAt: now,
            ),
            MedicationSchedule(
              id: 'schedule-3',
              medicationId: metforminId,
              timeInMinutes: 20 * 60,
              status: MedicationStatus.pending,
              createdAt: now,
            ),
          ],
    );
  }

  final List<Medication> _medications;
  final List<MedicationSchedule> _schedules;
  final AppStorageService? _storage;

  List<Medication> get medications => List.unmodifiable(_medications);

  List<ScheduledMedication> get scheduledMedications {
    final items = <ScheduledMedication>[];

    for (final schedule in _schedules) {
      final medication = _findMedication(schedule.medicationId);
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
    final medication = Medication(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
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
    _medications.removeWhere((medication) => medication.id == id);
    _schedules.removeWhere((schedule) => schedule.medicationId == id);
    _saveMedicationData();
    notifyListeners();
  }

  void addSchedule({required String medicationId, required int timeInMinutes}) {
    _schedules.add(
      MedicationSchedule(
        id: 'schedule-${DateTime.now().microsecondsSinceEpoch}',
        medicationId: medicationId,
        timeInMinutes: timeInMinutes,
        status: MedicationStatus.pending,
        createdAt: DateTime.now(),
      ),
    );
    _storage?.saveSchedules(_schedules);
    notifyListeners();
  }

  void updateScheduleStatus(String scheduleId, MedicationStatus status) {
    final index = _schedules.indexWhere((item) => item.id == scheduleId);
    if (index == -1) {
      return;
    }

    _schedules[index] = _schedules[index].copyWith(status: status);
    _storage?.saveSchedules(_schedules);
    notifyListeners();
  }

  void deleteSchedule(String scheduleId) {
    _schedules.removeWhere((schedule) => schedule.id == scheduleId);
    _storage?.saveSchedules(_schedules);
    notifyListeners();
  }

  void _saveMedicationData() {
    _storage?.saveMedications(_medications);
    _storage?.saveSchedules(_schedules);
  }

  Medication? _findMedication(String id) {
    for (final medication in _medications) {
      if (medication.id == id) {
        return medication;
      }
    }
    return null;
  }
}
