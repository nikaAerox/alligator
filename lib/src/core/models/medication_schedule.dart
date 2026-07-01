import 'medication.dart';

enum MedicationStatus {
  pending('Pending'),
  taken('Taken'),
  missed('Missed'),
  postponed('Postponed');

  const MedicationStatus(this.label);

  final String label;
}

class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.timeInMinutes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String medicationId;
  final int timeInMinutes;
  final MedicationStatus status;
  final DateTime createdAt;

  String get displayTime {
    final hour = timeInMinutes ~/ 60;
    final minute = timeInMinutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  MedicationSchedule copyWith({
    String? id,
    String? medicationId,
    int? timeInMinutes,
    MedicationStatus? status,
    DateTime? createdAt,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timeInMinutes: timeInMinutes ?? this.timeInMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'timeInMinutes': timeInMinutes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      timeInMinutes: json['timeInMinutes'] as int,
      status: MedicationStatus.values.byName(
        json['status'] as String? ?? MedicationStatus.pending.name,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ScheduledMedication {
  const ScheduledMedication({required this.schedule, required this.medication});

  final MedicationSchedule schedule;
  final Medication medication;
}
