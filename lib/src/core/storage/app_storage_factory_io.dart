import 'app_storage_service.dart';
import 'sqlite_storage_service.dart';

Future<AppStorageService> createAppStorage() {
  return SqliteStorageService.create();
}
