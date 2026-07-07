import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/notifications/notification_service.dart';
import 'src/core/storage/app_storage_factory.dart';
import 'src/core/state/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await createAppStorage();
  final preferences = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.initialize();
  final themeStore = ThemeStore(
    initialMode: ThemeStore.loadMode(preferences),
    preferences: preferences,
  );
  runApp(
    MedicareApp(
      storage: storage,
      notifications: notifications,
      themeStore: themeStore,
    ),
  );
}
