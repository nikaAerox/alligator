import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/health_record.dart';
import '../models/medication.dart';
import '../models/medication_history.dart';
import '../models/medication_schedule.dart';
import '../models/patient.dart';
import 'app_storage_service.dart';

class SqliteStorageService implements AppStorageService {
  SqliteStorageService._(
    this._database,
    this._medications,
    this._schedules,
    this._histories,
    this._healthRecords,
    this._patients,
    this._currentPatientId,
  );

  static const _databaseName = 'medicare.db';
  static const _databaseVersion = 6;

  static const _medicationsTable = 'medications';
  static const _schedulesTable = 'medication_schedules';
  static const _historiesTable = 'medication_histories';
  static const _healthRecordsTable = 'health_records';
  static const _patientsTable = 'patients';
  static const _settingsTable = 'app_settings';

  final Database _database;
  List<Medication> _medications;
  List<MedicationSchedule> _schedules;
  List<MedicationHistory> _histories;
  List<HealthRecord> _healthRecords;
  List<Patient> _patients;
  String? _currentPatientId;

  static Future<SqliteStorageService> create() async {
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, _databaseName),
      version: _databaseVersion,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );

    final service = SqliteStorageService._(database, [], [], [], [], [], null);
    await service._loadCache();
    return service;
  }

  static Future<void> _createSchema(Database db, int version) async {
    await _createPatientSchema(db);

    await db.execute('''
      CREATE TABLE $_medicationsTable (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        quantity TEXT NOT NULL,
        duration TEXT NOT NULL,
        timing TEXT NOT NULL,
        instructions TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        imageBytes BLOB,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_schedulesTable (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        medicationId TEXT NOT NULL,
        timeInMinutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        scheduledFor TEXT,
        isDaily INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (medicationId)
          REFERENCES $_medicationsTable (id)
          ON DELETE CASCADE
      )
    ''');

    await _createHistorySchema(db);

    await db.execute('''
      CREATE TABLE $_healthRecordsTable (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        recordedAt TEXT NOT NULL,
        weightKg REAL,
        heightCm REAL
      )
    ''');
  }

  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createPatientSchema(db);
    }
    if (oldVersion < 3) {
      await _createHistorySchema(db);
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(db, _medicationsTable, 'patientId TEXT');
      await _addColumnIfMissing(db, _historiesTable, 'patientId TEXT');
      await _addColumnIfMissing(db, _healthRecordsTable, 'patientId TEXT');
    }
    if (oldVersion < 5) {
      await _addColumnIfMissing(db, _schedulesTable, 'scheduledFor TEXT');
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        _schedulesTable,
        'isDaily INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
  ) async {
    final columnName = columnDefinition.split(' ').first;
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    }
  }

  static Future<void> _createHistorySchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_historiesTable (
        id TEXT PRIMARY KEY,
        patientId TEXT NOT NULL,
        medicationId TEXT NOT NULL,
        scheduleId TEXT NOT NULL,
        medicationName TEXT NOT NULL,
        dosage TEXT NOT NULL,
        status TEXT NOT NULL,
        actionAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createPatientSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_patientsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _loadCache() async {
    final medicationRows = await _database.query(_medicationsTable);
    final scheduleRows = await _database.query(_schedulesTable);
    final historyRows = await _database.query(_historiesTable);
    final healthRows = await _database.query(_healthRecordsTable);
    final patientRows = await _database.query(_patientsTable);
    final settingRows = await _database.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: ['currentPatientId'],
      limit: 1,
    );

    _medications = medicationRows.map(_medicationFromRow).toList();
    _schedules = scheduleRows.map(_scheduleFromRow).toList();
    _histories = historyRows.map(_historyFromRow).toList();
    _healthRecords = healthRows.map(_healthRecordFromRow).toList();
    _patients = patientRows.map(_patientFromRow).toList();
    _currentPatientId = settingRows.isEmpty
        ? null
        : settingRows.first['value'] as String?;
  }

  @override
  List<Patient>? loadPatients() {
    return _patients.isEmpty ? null : List.unmodifiable(_patients);
  }

  @override
  String? loadCurrentPatientId() {
    return _currentPatientId;
  }

  @override
  List<Medication>? loadMedications() {
    return _medications.isEmpty ? null : List.unmodifiable(_medications);
  }

  @override
  List<MedicationSchedule>? loadSchedules() {
    return _schedules.isEmpty ? null : List.unmodifiable(_schedules);
  }

  @override
  List<MedicationHistory>? loadMedicationHistories() {
    return _histories.isEmpty ? null : List.unmodifiable(_histories);
  }

  @override
  List<HealthRecord>? loadHealthRecords() {
    return _healthRecords.isEmpty ? null : List.unmodifiable(_healthRecords);
  }

  @override
  Future<void> savePatients(List<Patient> patients) async {
    _patients = List.of(patients);
    await _database.transaction((txn) async {
      await txn.delete(_patientsTable);
      for (final patient in patients) {
        await txn.insert(
          _patientsTable,
          _patientToRow(patient),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveCurrentPatientId(String? patientId) async {
    _currentPatientId = patientId;
    if (patientId == null) {
      await _database.delete(
        _settingsTable,
        where: 'key = ?',
        whereArgs: ['currentPatientId'],
      );
      return;
    }

    await _database.insert(_settingsTable, {
      'key': 'currentPatientId',
      'value': patientId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveMedications(List<Medication> medications) async {
    _medications = List.of(medications);
    await _database.transaction((txn) async {
      await txn.delete(_medicationsTable);
      for (final medication in medications) {
        await txn.insert(
          _medicationsTable,
          _medicationToRow(medication),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveSchedules(List<MedicationSchedule> schedules) async {
    _schedules = List.of(schedules);
    await _database.transaction((txn) async {
      await txn.delete(_schedulesTable);
      for (final schedule in schedules) {
        await txn.insert(
          _schedulesTable,
          _scheduleToRow(schedule),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveMedicationHistories(
    List<MedicationHistory> histories,
  ) async {
    _histories = List.of(histories);
    await _database.transaction((txn) async {
      await txn.delete(_historiesTable);
      for (final history in histories) {
        await txn.insert(
          _historiesTable,
          _historyToRow(history),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> saveHealthRecords(List<HealthRecord> records) async {
    _healthRecords = List.of(records);
    await _database.transaction((txn) async {
      await txn.delete(_healthRecordsTable);
      for (final record in records) {
        await txn.insert(
          _healthRecordsTable,
          _healthRecordToRow(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Map<String, Object?> _medicationToRow(Medication medication) {
    return {
      'id': medication.id,
      'patientId': medication.patientId,
      'name': medication.name,
      'dosage': medication.dosage,
      'quantity': medication.quantity,
      'duration': medication.duration,
      'timing': medication.timing.name,
      'instructions': medication.instructions,
      'isActive': medication.isActive ? 1 : 0,
      'imageBytes': medication.imageBytes,
      'createdAt': medication.createdAt.toIso8601String(),
    };
  }

  Medication _medicationFromRow(Map<String, Object?> row) {
    return Medication(
      id: row['id']! as String,
      patientId: row['patientId'] as String? ?? '',
      name: row['name']! as String,
      dosage: row['dosage']! as String,
      quantity: row['quantity']! as String,
      duration: row['duration']! as String,
      timing: MedicationTiming.values.byName(row['timing']! as String),
      instructions: row['instructions']! as String,
      isActive: (row['isActive']! as int) == 1,
      imageBytes: row['imageBytes'] == null
          ? null
          : Uint8List.fromList(row['imageBytes'] as List<int>),
      createdAt: DateTime.parse(row['createdAt']! as String),
    );
  }

  Map<String, Object?> _scheduleToRow(MedicationSchedule schedule) {
    return {
      'id': schedule.id,
      'medicationId': schedule.medicationId,
      'timeInMinutes': schedule.timeInMinutes,
      'status': schedule.status.name,
      'createdAt': schedule.createdAt.toIso8601String(),
      'scheduledFor': schedule.scheduledFor?.toIso8601String(),
      'isDaily': schedule.isDaily ? 1 : 0,
    };
  }

  MedicationSchedule _scheduleFromRow(Map<String, Object?> row) {
    return MedicationSchedule(
      id: row['id']! as String,
      medicationId: row['medicationId']! as String,
      timeInMinutes: row['timeInMinutes']! as int,
      status: MedicationStatus.values.byName(row['status']! as String),
      createdAt: DateTime.parse(row['createdAt']! as String),
      scheduledFor: DateTime.tryParse(row['scheduledFor'] as String? ?? ''),
      isDaily: (row['isDaily'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> _historyToRow(MedicationHistory history) {
    return {
      'id': history.id,
      'patientId': history.patientId,
      'medicationId': history.medicationId,
      'scheduleId': history.scheduleId,
      'medicationName': history.medicationName,
      'dosage': history.dosage,
      'status': history.status.name,
      'actionAt': history.actionAt.toIso8601String(),
    };
  }

  MedicationHistory _historyFromRow(Map<String, Object?> row) {
    return MedicationHistory(
      id: row['id']! as String,
      patientId: row['patientId'] as String? ?? '',
      medicationId: row['medicationId']! as String,
      scheduleId: row['scheduleId']! as String,
      medicationName: row['medicationName']! as String,
      dosage: row['dosage']! as String,
      status: MedicationStatus.values.byName(row['status']! as String),
      actionAt: DateTime.parse(row['actionAt']! as String),
    );
  }

  Map<String, Object?> _healthRecordToRow(HealthRecord record) {
    return {
      'id': record.id,
      'patientId': record.patientId,
      'type': record.type.name,
      'value': record.value,
      'recordedAt': record.recordedAt.toIso8601String(),
      'weightKg': record.weightKg,
      'heightCm': record.heightCm,
    };
  }

  HealthRecord _healthRecordFromRow(Map<String, Object?> row) {
    return HealthRecord(
      id: row['id']! as String,
      patientId: row['patientId'] as String? ?? '',
      type: HealthRecordType.values.byName(row['type']! as String),
      value: row['value']! as String,
      recordedAt: DateTime.parse(row['recordedAt']! as String),
      weightKg: row['weightKg'] as double?,
      heightCm: row['heightCm'] as double?,
    );
  }

  Map<String, Object?> _patientToRow(Patient patient) {
    return {
      'id': patient.id,
      'name': patient.name,
      'email': patient.email,
      'password': patient.password,
      'createdAt': patient.createdAt.toIso8601String(),
    };
  }

  Patient _patientFromRow(Map<String, Object?> row) {
    return Patient(
      id: row['id']! as String,
      name: row['name']! as String,
      email: row['email']! as String,
      password: row['password']! as String,
      createdAt: DateTime.parse(row['createdAt']! as String),
    );
  }
}
