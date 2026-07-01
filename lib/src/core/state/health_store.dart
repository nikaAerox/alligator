import 'package:flutter/foundation.dart';

import '../models/health_record.dart';
import '../storage/app_storage_service.dart';

class HealthStore extends ChangeNotifier {
  HealthStore({List<HealthRecord>? initialRecords, this._storage})
    : _records = List.of(initialRecords ?? const []);

  factory HealthStore.seeded({AppStorageService? storage}) {
    final now = DateTime.now();

    return HealthStore(
      storage: storage,
      initialRecords:
          storage?.loadHealthRecords() ??
          [
            HealthRecord(
              id: 'health-1',
              type: HealthRecordType.bmi,
              value: '23.5',
              recordedAt: now,
              weightKg: 64,
              heightCm: 165,
            ),
            HealthRecord(
              id: 'health-2',
              type: HealthRecordType.bloodSugar,
              value: '6.2',
              recordedAt: now,
            ),
            HealthRecord(
              id: 'health-3',
              type: HealthRecordType.bloodPressure,
              value: '145/90',
              recordedAt: now,
            ),
          ],
    );
  }

  final List<HealthRecord> _records;
  final AppStorageService? _storage;

  List<HealthRecord> get records => List.unmodifiable(_records);

  void updateRecord(HealthRecord record) {
    final index = _records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      return;
    }

    _records[index] = record.copyWith(
      value: record.value.trim(),
      recordedAt: DateTime.now(),
    );
    _storage?.saveHealthRecords(_records);
    notifyListeners();
  }
}
