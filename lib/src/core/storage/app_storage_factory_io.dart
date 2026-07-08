// Creates SQLite storage for mobile/desktop.

import 'app_storage_service.dart';
import 'sqlite_storage_service.dart';

// Creates the SQLite-based storage service for non-web platforms.
Future<AppStorageService> createAppStorage() {
  return SqliteStorageService.create();
}
