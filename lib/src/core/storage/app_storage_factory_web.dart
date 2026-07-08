// Creates local-storage service for web.

import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_service.dart';
import 'local_storage_service.dart';

// Creates the browser local storage service for web platforms.
Future<AppStorageService> createAppStorage() async {
  final preferences = await SharedPreferences.getInstance();
  return LocalStorageService(preferences);
}
