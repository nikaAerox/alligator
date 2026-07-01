import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_record.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';
import '../models/medication_schedule.dart';
import '../models/patient.dart';
import 'app_storage_service.dart';

class LocalStorageService implements AppStorageService {
  LocalStorageService(this._preferences);

  static const _medicationsKey = 'medications';
  static const _schedulesKey = 'medication_schedules';
  static const _historiesKey = 'medication_histories';
  static const _healthRecordsKey = 'health_records';
  static const _patientsKey = 'patients';
  static const _currentPatientIdKey = 'current_patient_id';

  final SharedPreferences _preferences;

  @override
  List<Patient>? loadPatients() {
    final source = _preferences.getString(_patientsKey);
    if (source == null) {
      return null;
    }

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((item) => Patient.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  String? loadCurrentPatientId() {
    return _preferences.getString(_currentPatientIdKey);
  }

  @override
  List<Medication>? loadMedications() {
    final source = _preferences.getString(_medicationsKey);
    if (source == null) {
      return null;
    }

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map(
          (item) => Medication.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  List<MedicationSchedule>? loadSchedules() {
    final source = _preferences.getString(_schedulesKey);
    if (source == null) {
      return null;
    }

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map(
          (item) => MedicationSchedule.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  List<MedicationHistory>? loadMedicationHistories() {
    final source = _preferences.getString(_historiesKey);
    if (source == null) {
      return null;
    }

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map(
          (item) => MedicationHistory.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  List<HealthRecord>? loadHealthRecords() {
    final source = _preferences.getString(_healthRecordsKey);
    if (source == null) {
      return null;
    }

    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              HealthRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> savePatients(List<Patient> patients) {
    final encoded = jsonEncode(
      patients.map((patient) => patient.toJson()).toList(),
    );
    return _preferences.setString(_patientsKey, encoded);
  }

  @override
  Future<void> saveCurrentPatientId(String? patientId) {
    if (patientId == null) {
      return _preferences.remove(_currentPatientIdKey);
    }
    return _preferences.setString(_currentPatientIdKey, patientId);
  }

  @override
  Future<void> saveMedications(List<Medication> medications) {
    final encoded = jsonEncode(
      medications.map((medication) => medication.toJson()).toList(),
    );
    return _preferences.setString(_medicationsKey, encoded);
  }

  @override
  Future<void> saveSchedules(List<MedicationSchedule> schedules) {
    final encoded = jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
    return _preferences.setString(_schedulesKey, encoded);
  }

  @override
  Future<void> saveMedicationHistories(List<MedicationHistory> histories) {
    final encoded = jsonEncode(
      histories.map((history) => history.toJson()).toList(),
    );
    return _preferences.setString(_historiesKey, encoded);
  }

  @override
  Future<void> saveHealthRecords(List<HealthRecord> records) {
    final encoded = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    return _preferences.setString(_healthRecordsKey, encoded);
  }
}
