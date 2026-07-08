// Defines a medication record, including timing, status, image

import 'dart:typed_data';

import 'dart:convert';

enum MedicationTiming {
  beforeMeal('Before meal'),
  afterMeal('After meal'),
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  bedtime('Bedtime'),
  custom('Custom');

  const MedicationTiming(this.label);

  final String label;
}

class Medication {
  const Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.duration,
    required this.timing,
    required this.instructions,
    required this.isActive,
    this.imageBytes,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String quantity;
  final String duration;
  final MedicationTiming timing;
  final String instructions;
  final bool isActive;
  final Uint8List? imageBytes;
  final DateTime createdAt;

  Medication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosage,
    String? quantity,
    String? duration,
    MedicationTiming? timing,
    String? instructions,
    bool? isActive,
    Uint8List? imageBytes,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      duration: duration ?? this.duration,
      timing: timing ?? this.timing,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      imageBytes: imageBytes ?? this.imageBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'duration': duration,
      'timing': timing.name,
      'instructions': instructions,
      'isActive': isActive,
      'imageBytes': imageBytes == null ? null : base64Encode(imageBytes!),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    final imageValue = json['imageBytes'] as String?;

    return Medication(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      quantity: json['quantity'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      timing: MedicationTiming.values.byName(
        json['timing'] as String? ?? MedicationTiming.afterMeal.name,
      ),
      instructions: json['instructions'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      imageBytes: imageValue == null ? null : base64Decode(imageValue),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
