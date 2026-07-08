// Defines health record types and stores each patient’s health readings including optional BMI calculation details

enum HealthRecordType {
  bmi('BMI', 'kg/m2'),
  bloodSugar('Blood Sugar', 'mmol/L'),
  bloodPressure('Blood Pressure', 'mmHg');

  const HealthRecordType(this.label, this.unit);

  final String label;
  final String unit;
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.recordedAt,
    this.weightKg,
    this.heightCm,
  });

  final String id;
  final String patientId;
  final HealthRecordType type;
  final String value;
  final DateTime recordedAt;
  final double? weightKg;
  final double? heightCm;

  HealthRecord copyWith({
    String? id,
    String? patientId,
    HealthRecordType? type,
    String? value,
    DateTime? recordedAt,
    double? weightKg,
    double? heightCm,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      value: value ?? this.value,
      recordedAt: recordedAt ?? this.recordedAt,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type.name,
      'value': value,
      'recordedAt': recordedAt.toIso8601String(),
      'weightKg': weightKg,
      'heightCm': heightCm,
    };
  }

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      type: HealthRecordType.values.byName(
        json['type'] as String? ?? HealthRecordType.bmi.name,
      ),
      value: json['value'] as String,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
    );
  }
}
