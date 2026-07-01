import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_service.dart';
import 'local_storage_service.dart';

Future<AppStorageService> createAppStorage() async {
  final preferences = await SharedPreferences.getInstance();
  return LocalStorageService(preferences);
}
