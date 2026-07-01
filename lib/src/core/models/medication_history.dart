import 'medication_schedule.dart';

class MedicationHistory {
  const MedicationHistory({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.medicationName,
    required this.dosage,
    required this.status,
    required this.actionAt,
  });

  final String id;
  final String medicationId;
  final String scheduleId;
  final String medicationName;
  final String dosage;
  final MedicationStatus status;
  final DateTime actionAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduleId': scheduleId,
      'medicationName': medicationName,
      'dosage': dosage,
      'status': status.name,
      'actionAt': actionAt.toIso8601String(),
    };
  }

  factory MedicationHistory.fromJson(Map<String, dynamic> json) {
    return MedicationHistory(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      scheduleId: json['scheduleId'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      status: MedicationStatus.values.byName(json['status'] as String),
      actionAt:
          DateTime.tryParse(json['actionAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
