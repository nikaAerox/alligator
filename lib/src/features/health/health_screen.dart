import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/health_record.dart';
import '../../core/state/health_store.dart';
import '../../theme/app_theme.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<HealthStore>().records;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Records')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        itemBuilder: (context, index) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _HealthRecordCard(record: records[index]),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemCount: records.length,
      ),
    );
  }
}

class _HealthRecordCard extends StatelessWidget {
  const _HealthRecordCard({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final status = _healthStatus(record);

    return Card(
      color: const Color(0xFFFCF6ED),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD6CDC0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.type.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF141414),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => _openEditForm(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4D7480),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    minimumSize: const Size(70, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(child: _ReadingValue(record: record)),
            const SizedBox(height: 8),
            Center(child: _StatusBadge(status: status)),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFF9E9589)),
            const SizedBox(height: 8),
            Text(
              status.suggestion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => HealthRecordFormSheet(record: record),
    );
  }
}

class _ReadingValue extends StatelessWidget {
  const _ReadingValue({required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    final unit = switch (record.type) {
      HealthRecordType.bmi => '',
      HealthRecordType.bloodSugar => ' mmol/L',
      HealthRecordType.bloodPressure => ' mmHg',
    };

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: record.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          TextSpan(
            text: unit,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _HealthStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class HealthRecordFormSheet extends StatefulWidget {
  const HealthRecordFormSheet({super.key, required this.record});

  final HealthRecord record;

  @override
  State<HealthRecordFormSheet> createState() => _HealthRecordFormSheetState();
}

class _HealthRecordFormSheetState extends State<HealthRecordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.record.weightKg?.toStringAsFixed(0) ?? '',
    );
    _heightController = TextEditingController(
      text: widget.record.heightCm?.toStringAsFixed(0) ?? '',
    );
    _valueController = TextEditingController(text: widget.record.value);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit ${widget.record.type.label}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              ..._buildFields(),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  backgroundColor: const Color(0xFF4D7480),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate & Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (widget.record.type) {
      case HealthRecordType.bmi:
        return [
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            validator: _requiredPositiveNumber,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height',
              suffixText: 'cm',
              prefixIcon: Icon(Icons.height),
            ),
            validator: _requiredPositiveNumber,
          ),
        ];
      case HealthRecordType.bloodSugar:
        return [
          TextFormField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Blood sugar value',
              suffixText: 'mmol/L',
              prefixIcon: Icon(Icons.bloodtype_outlined),
            ),
            validator: _requiredPositiveNumber,
          ),
        ];
      case HealthRecordType.bloodPressure:
        return [
          TextFormField(
            controller: _valueController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Blood pressure value',
              suffixText: 'mmHg',
              prefixIcon: Icon(Icons.monitor_heart_outlined),
              hintText: 'Example: 120/80',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              final parts = text.split('/');
              if (parts.length != 2) {
                return 'Use format like 120/80';
              }
              final systolic = int.tryParse(parts[0]);
              final diastolic = int.tryParse(parts[1]);
              if (systolic == null || diastolic == null) {
                return 'Use numbers only';
              }
              if (systolic <= 0 || diastolic <= 0) {
                return 'Enter a positive value';
              }
              return null;
            },
          ),
        ];
    }
  }

  String? _requiredPositiveNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) {
      return 'Enter a number';
    }
    if (number <= 0) {
      return 'Enter a positive value';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = context.read<HealthStore>();
    final record = widget.record;

    // BMI calculation
    switch (record.type) {
      case HealthRecordType.bmi:
        final weight = double.parse(_weightController.text.trim());
        final heightCm = double.parse(_heightController.text.trim());
        final heightM = heightCm / 100;
        final bmi = weight / (heightM * heightM);
        store.updateRecord(
          record.copyWith(
            value: bmi.toStringAsFixed(1),
            weightKg: weight,
            heightCm: heightCm,
          ),
        );
      case HealthRecordType.bloodSugar:
      case HealthRecordType.bloodPressure:
        store.updateRecord(record.copyWith(value: _valueController.text));
    }

    Navigator.of(context).pop();
  }
}

_HealthStatus _healthStatus(HealthRecord record) {
  switch (record.type) {
    // Determines the BMI level based on the record type and value
    case HealthRecordType.bmi:
      final bmi = double.tryParse(record.value) ?? 0;
      if (bmi < 18.5) {
        return const _HealthStatus(
          'Underweight',
          AppTheme.accent,
          'Your BMI is low. Try to eat balanced meals and maintain a healthy lifestyle.',
        );
      }
      if (bmi <= 24.9) {
        return const _HealthStatus(
          'Healthy Weight',
          AppTheme.success,
          'Great! Your BMI is healthy. Keep eating balanced meals and stay active.',
        );
      }
      if (bmi <= 29.9) {
        return const _HealthStatus(
          'Overweight',
          AppTheme.danger,
          'Your BMI is above the healthy range. Try to control your diet and exercise regularly.',
        );
      }
      return const _HealthStatus(
        'Obese',
        AppTheme.danger,
        'Your BMI is high. Try to plan your meals and exercise regularly. Consider consulting a healthcare professional if needed.',
      );
    // Determines the blood sugar level based on the record type and value
    case HealthRecordType.bloodSugar:
      final sugar = double.tryParse(record.value) ?? 0;
      if (sugar < 4.0) {
        return const _HealthStatus(
          'Low Blood Sugar',
          AppTheme.danger,
          'Your blood sugar is low. Eat or drink something with sugar and monitor your condition.',
        );
      }
      if (sugar <= 5.5) {
        return const _HealthStatus(
          'Normal',
          AppTheme.success,
          'Great! Your blood sugar is normal. Keep maintaining a balanced diet and healthy lifestyle.',
        );
      }
      if (sugar <= 6.9) {
        return const _HealthStatus(
          'Prediabetes',
          AppTheme.accent,
          'Your blood sugar is slightly high. Reduce sugary foods and exercise regularly.',
        );
      }
      return const _HealthStatus(
        'High Blood Sugar',
        AppTheme.danger,
        'Your blood sugar is high. Monitor your diet and consult a healthcare professional if it remains high.',
      );
    // Determines the blood pressure level based on the record type and value
    case HealthRecordType.bloodPressure:
      final parts = record.value.split('/');
      final systolic = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
      final diastolic = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      if (systolic < 90 || diastolic < 60) {
        return const _HealthStatus(
          'Low Blood Pressure',
          AppTheme.accent,
          'Your blood pressure is low. Stay hydrated and seek medical advice if you feel dizzy or weak.',
        );
      }
      if (systolic <= 119 && diastolic <= 79) {
        return const _HealthStatus(
          'Normal',
          AppTheme.success,
          'Great! Your blood pressure is normal. Keep maintaining a healthy lifestyle.',
        );
      }
      if (systolic <= 139 && diastolic <= 89) {
        return const _HealthStatus(
          'Elevated',
          AppTheme.accent,
          'Your blood pressure is slightly high. Reduce salt intake and exercise regularly.',
        );
      }
      return const _HealthStatus(
        'High Blood Pressure',
        AppTheme.danger,
        'Your blood pressure is high. Monitor it regularly and consult a healthcare professional if needed.',
      );
  }
}

class _HealthStatus {
  const _HealthStatus(this.label, this.color, this.suggestion);

  final String label;
  final Color color;
  final String suggestion;
}
