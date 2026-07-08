// Manages the current user’s health records.
// Creates default empty records for BMI, blood sugar, and blood pressure when a new user logs in for the first time.

import 'package:flutter/foundation.dart';

import '../models/health_record.dart';
import '../storage/app_storage_service.dart';

class HealthStore extends ChangeNotifier {
  HealthStore({List<HealthRecord>? initialRecords, this._storage})
    : _records = List.of(initialRecords ?? const []);

  factory HealthStore.seeded({AppStorageService? storage}) {
    return HealthStore(
      storage: storage,
      initialRecords: storage?.loadHealthRecords(),
    );
  }

  final List<HealthRecord> _records;
  final AppStorageService? _storage;
  String? _currentPatientId;

  // Returns only the health records that belong to the current user.
  List<HealthRecord> get records {
    final patientId = _currentPatientId;
    if (patientId == null) {
      return const [];
    }
    return List.unmodifiable(
      _records.where((record) => record.patientId == patientId),
    );
  }

  // Sets the active patient ID and prepares default health records if needed.
  void setCurrentPatientId(String? patientId) {
    if (_currentPatientId == patientId) {
      return;
    }
    _currentPatientId = patientId;
    if (patientId != null) {
      _ensureEmptyRecords(patientId);
    }
    notifyListeners();
  }

  // Updates an existing health record and saves it to storage.
  void updateRecord(HealthRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      return;
    }

    _records[index] = record.copyWith(
      patientId: record.patientId,
      value: record.value.trim(),
      recordedAt: DateTime.now(),
    );
    _storage?.saveHealthRecords(_records);
    notifyListeners();
  }

  // Creates default zero-value health records for a new patient. (ensures every user starts with the same health record layout.)
  void _ensureEmptyRecords(String patientId) {
    final hasRecords = _records.any((record) => record.patientId == patientId);
    if (hasRecords) {
      return;
    }

    final now = DateTime.now();
    _records.addAll([
      HealthRecord(
        id: 'health-$patientId-bmi',
        patientId: patientId,
        type: HealthRecordType.bmi,
        value: '0',
        recordedAt: now,
      ),
      HealthRecord(
        id: 'health-$patientId-blood-sugar',
        patientId: patientId,
        type: HealthRecordType.bloodSugar,
        value: '0',
        recordedAt: now,
      ),
      HealthRecord(
        id: 'health-$patientId-blood-pressure',
        patientId: patientId,
        type: HealthRecordType.bloodPressure,
        value: '0/0',
        recordedAt: now,
      ),
    ]);
    _storage?.saveHealthRecords(_records);
  }
}
