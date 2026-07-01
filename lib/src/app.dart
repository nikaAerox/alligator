import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/notifications/notification_service.dart';
import 'core/storage/app_storage_service.dart';
import 'core/state/auth_store.dart';
import 'core/state/health_store.dart';
import 'core/state/medication_store.dart';
import 'features/auth/login_screen.dart';
import 'theme/app_theme.dart';

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key, this.storage, this.notifications});

  final AppStorageService? storage;
  final NotificationService? notifications;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore(storage: storage)),
        ChangeNotifierProvider(
          create: (_) => MedicationStore.seeded(
            storage: storage,
            notifications: notifications,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthStore.seeded(storage: storage),
        ),
      ],
      child: MaterialApp(
        title: 'MediCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
  }
}
