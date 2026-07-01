import '../models/health_record.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';
import '../models/medication_schedule.dart';
import '../models/patient.dart';

abstract class AppStorageService {
  List<Patient>? loadPatients();

  String? loadCurrentPatientId();

  List<Medication>? loadMedications();

  List<MedicationSchedule>? loadSchedules();

  List<MedicationHistory>? loadMedicationHistories();

  List<HealthRecord>? loadHealthRecords();

  Future<void> savePatients(List<Patient> patients);

  Future<void> saveCurrentPatientId(String? patientId);

  Future<void> saveMedications(List<Medication> medications);

  Future<void> saveSchedules(List<MedicationSchedule> schedules);

  Future<void> saveMedicationHistories(List<MedicationHistory> histories);

  Future<void> saveHealthRecords(List<HealthRecord> records);
}
