// Root widget of MediCare.
// Provides app-wide state for authentication, medication, health, and theme.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/notifications/notification_service.dart';
import 'core/storage/app_storage_service.dart';
import 'core/state/auth_store.dart';
import 'core/state/health_store.dart';
import 'core/state/medication_store.dart';
import 'core/state/theme_store.dart';
import 'features/welcome/welcome_screen.dart';
import 'theme/app_theme.dart';

class MedicareApp extends StatefulWidget {
  const MedicareApp({
    super.key,
    this.storage,
    this.notifications,
    this.themeStore,
  });

  final AppStorageService? storage;
  final NotificationService? notifications;
  final ThemeStore? themeStore;

  @override
  State<MedicareApp> createState() => _MedicareAppState();
}

class _MedicareAppState extends State<MedicareApp> {
  late final ThemeStore _fallbackThemeStore = ThemeStore();

  ThemeStore get _effectiveThemeStore =>
      widget.themeStore ?? _fallbackThemeStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _effectiveThemeStore),
        ChangeNotifierProvider(
          create: (_) => AuthStore(storage: widget.storage),
        ),
        ChangeNotifierProxyProvider<AuthStore, MedicationStore>(
          create: (_) => MedicationStore.seeded(
            storage: widget.storage,
            notifications: widget.notifications,
          ),
          update: (_, authStore, medicationStore) {
            return medicationStore!
              ..setCurrentPatientId(authStore.currentPatient?.id);
          },
        ),
        ChangeNotifierProxyProvider<AuthStore, HealthStore>(
          create: (_) => HealthStore.seeded(storage: widget.storage),
          update: (_, authStore, healthStore) {
            return healthStore!
              ..setCurrentPatientId(authStore.currentPatient?.id);
          },
        ),
      ],
      child: Consumer<ThemeStore>(
        builder: (context, themeStore, _) {
          return MaterialApp(
            title: 'MediCare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeStore.mode,
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
