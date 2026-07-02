import 'package:flutter/foundation.dart';

import '../models/patient.dart';
import '../storage/app_storage_service.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({AppStorageService? storage})
    : _storage = storage,
      _patients = List.of(storage?.loadPatients() ?? const []) {
    final currentPatientId = storage?.loadCurrentPatientId();
    if (currentPatientId != null) {
      _currentPatient = _findPatientById(currentPatientId);
    }
  }

  final AppStorageService? _storage;
  final List<Patient> _patients;
  Patient? _currentPatient;

  Patient? get currentPatient => _currentPatient;

  bool get isLoggedIn => _currentPatient != null;

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      return 'Enter your name';
    }
    if (!_isValidEmail(normalizedEmail)) {
      return 'Enter a valid email';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    if (_patients.any((patient) => patient.email == normalizedEmail)) {
      return 'Email already registered';
    }

    final patient = Patient(
      id: 'patient-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      createdAt: DateTime.now(),
    );
    _patients.add(patient);
    _currentPatient = patient;
    await _saveAuthData();
    notifyListeners();
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final patient = _patients.where((item) {
      return item.email == normalizedEmail && item.password == password;
    }).firstOrNull;

    if (patient == null) {
      return 'Invalid email or password';
    }

    _currentPatient = patient;
    await _storage?.saveCurrentPatientId(patient.id);
    notifyListeners();
    return null;
  }

  Future<String?> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final current = _currentPatient;
    if (current == null) {
      return 'No user is logged in';
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      return 'Enter your name';
    }
    if (!_isValidEmail(normalizedEmail)) {
      return 'Enter a valid email';
    }
    if (_patients.any(
      (patient) => patient.id != current.id && patient.email == normalizedEmail,
    )) {
      return 'Email already registered';
    }
    if (password != null && password.isNotEmpty && password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    final updated = current.copyWith(
      name: name.trim(),
      email: normalizedEmail,
      password: password == null || password.isEmpty
          ? current.password
          : password,
    );
    final index = _patients.indexWhere((patient) => patient.id == current.id);
    if (index == -1) {
      return 'Profile could not be updated';
    }

    _patients[index] = updated;
    _currentPatient = updated;
    await _saveAuthData();
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentPatient = null;
    await _storage?.saveCurrentPatientId(null);
    notifyListeners();
  }

  Patient? _findPatientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) {
        return patient;
      }
    }
    return null;
  }

  Future<void> _saveAuthData() async {
    await _storage?.savePatients(_patients);
    await _storage?.saveCurrentPatientId(_currentPatient?.id);
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }
}
