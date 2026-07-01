import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/health_record.dart';
import '../../core/models/medication_history.dart';
import '../../core/models/medication_schedule.dart';
import '../../core/state/health_store.dart';
import '../../core/state/medication_store.dart';
import '../../theme/app_theme.dart';
import '../health/health_screen.dart';
import '../medication/medication_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    _HomeTab(),
    MedicationScreen(),
    ScheduleScreen(),
    HealthScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meds',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Health',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  _HistoryPeriod _period = _HistoryPeriod.today;

  @override
  Widget build(BuildContext context) {
    final medicationStore = context.watch<MedicationStore>();
    final healthStore = context.watch<HealthStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdherenceCard(schedules: medicationStore.scheduledMedications),
          const SizedBox(height: 14),
          _NextDoseCard(schedules: medicationStore.scheduledMedications),
          const SizedBox(height: 14),
          _HealthSnapshotCard(records: healthStore.records),
          const SizedBox(height: 14),
          _MedicationHistoryReport(
            histories: medicationStore.medicationHistories,
            period: _period,
            onPeriodChanged: (period) => setState(() => _period = period),
          ),
          const SizedBox(height: 14),
          _SuggestionCard(
            schedules: medicationStore.scheduledMedications,
            records: healthStore.records,
          ),
        ],
      ),
    );
  }
}

enum _HistoryPeriod {
  today('Today'),
  week('Week'),
  month('Month');

  const _HistoryPeriod(this.label);

  final String label;
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.schedules});

  final List<ScheduledMedication> schedules;

  @override
  Widget build(BuildContext context) {
    final total = schedules.length;
    final taken = schedules
        .where((item) => item.schedule.status == MedicationStatus.taken)
        .length;
    final missed = schedules
        .where((item) => item.schedule.status == MedicationStatus.missed)
        .length;
    final postponed = schedules
        .where((item) => item.schedule.status == MedicationStatus.postponed)
        .length;
    final adherence = total == 0 ? 0.0 : taken / total;
    final percentage = (adherence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: adherence,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFE7EFEF),
                    color: _adherenceColor(adherence),
                  ),
                  Center(
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication Adherence',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text('$taken taken, $missed missed, $postponed postponed'),
                  const SizedBox(height: 8),
                  Text(
                    total == 0
                        ? 'Add reminders to start tracking your medication routine.'
                        : _adherenceMessage(adherence),
                    style: const TextStyle(color: Color(0xFF627174)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard({required this.schedules});

  final List<ScheduledMedication> schedules;

  @override
  Widget build(BuildContext context) {
    final next = schedules
        .where((item) => item.schedule.status == MedicationStatus.pending)
        .firstOrNull;

    return Card(
      child: next == null
          ? const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE1F3E9),
                child: Icon(Icons.check_circle, color: AppTheme.success),
              ),
              title: Text('Next Reminder'),
              subtitle: Text('No pending medication reminders'),
            )
          : ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF2D4),
                child: Icon(
                  Icons.notifications_active,
                  color: Color(0xFF9A6A00),
                ),
              ),
              title: const Text('Next Reminder'),
              subtitle: Text(
                '${next.medication.name} - ${next.schedule.displayTime}',
              ),
              trailing: FilledButton.tonal(
                onPressed: () {
                  context.read<MedicationStore>().updateScheduleStatus(
                    next.schedule.id,
                    MedicationStatus.taken,
                  );
                },
                child: const Text('Taken'),
              ),
            ),
    );
  }
}

class _HealthSnapshotCard extends StatelessWidget {
  const _HealthSnapshotCard({required this.records});

  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Snapshot',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'BMI',
                    value: _valueFor(records, HealthRecordType.bmi),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Sugar',
                    value: _valueFor(records, HealthRecordType.bloodSugar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'BP',
                    value: _valueFor(records, HealthRecordType.bloodPressure),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.schedules, required this.records});

  final List<ScheduledMedication> schedules;
  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      _medicationSuggestion(schedules),
      ...records.map(_healthSuggestion),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Reports & Suggestions',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final suggestion in suggestions) ...[
              Text(suggestion),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MedicationHistoryReport extends StatelessWidget {
  const _MedicationHistoryReport({
    required this.histories,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<MedicationHistory> histories;
  final _HistoryPeriod period;
  final ValueChanged<_HistoryPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterHistories(histories, period);
    final taken = _countStatus(filtered, MedicationStatus.taken);
    final missed = _countStatus(filtered, MedicationStatus.missed);
    final postponed = _countStatus(filtered, MedicationStatus.postponed);
    final total = taken + missed + postponed;
    final adherence = total == 0 ? 0 : ((taken / total) * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Medication Intake History',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Text(
                  '$adherence%',
                  style: TextStyle(
                    color: _adherenceColor(adherence / 100),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<_HistoryPeriod>(
              segments: _HistoryPeriod.values
                  .map(
                    (item) =>
                        ButtonSegment(value: item, label: Text(item.label)),
                  )
                  .toList(),
              selected: {period},
              onSelectionChanged: (selection) {
                onPeriodChanged(selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF5D8490);
                  }
                  return Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppTheme.ink;
                }),
              ),
            ),
            const SizedBox(height: 18),
            if (total == 0)
              const _EmptyHistoryReport()
            else ...[
              Center(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _HistoryDonutPainter(
                      taken: taken,
                      missed: missed,
                      postponed: postponed,
                    ),
                    child: Center(
                      child: Text(
                        '$taken/$total\nTaken',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _LegendItem(color: Color(0xFF176C8C), label: 'Taken'),
                  SizedBox(width: 14),
                  _LegendItem(color: AppTheme.danger, label: 'Missed'),
                  SizedBox(width: 14),
                  _LegendItem(color: AppTheme.success, label: 'Postponed'),
                ],
              ),
              const SizedBox(height: 14),
              for (final history in filtered.take(3)) ...[
                _HistoryListItem(history: history),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryDonutPainter extends CustomPainter {
  const _HistoryDonutPainter({
    required this.taken,
    required this.missed,
    required this.postponed,
  });

  final int taken;
  final int missed;
  final int postponed;

  @override
  void paint(Canvas canvas, Size size) {
    final total = taken + missed + postponed;
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final values = [
      (taken, const Color(0xFF176C8C)),
      (missed, AppTheme.danger),
      (postponed, AppTheme.success),
    ];
    var start = -90.0;
    for (final item in values) {
      if (item.$1 == 0) {
        continue;
      }
      final sweep = item.$1 / total * 360;
      paint.color = item.$2;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start * 3.141592653589793 / 180,
        sweep * 3.141592653589793 / 180,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryDonutPainter oldDelegate) {
    return oldDelegate.taken != taken ||
        oldDelegate.missed != missed ||
        oldDelegate.postponed != postponed;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  const _HistoryListItem({required this.history});

  final MedicationHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${history.medicationName} - ${history.dosage}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _StatusMiniBadge(status: history.status),
        ],
      ),
    );
  }
}

class _StatusMiniBadge extends StatelessWidget {
  const _StatusMiniBadge({required this.status});

  final MedicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MedicationStatus.taken => const Color(0xFF176C8C),
      MedicationStatus.missed => AppTheme.danger,
      MedicationStatus.postponed => AppTheme.success,
      MedicationStatus.pending => AppTheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyHistoryReport extends StatelessWidget {
  const _EmptyHistoryReport();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'No intake history for this period yet.',
          style: TextStyle(color: Color(0xFF627174)),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF627174))),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

Color _adherenceColor(double value) {
  if (value >= 0.8) return AppTheme.success;
  if (value >= 0.5) return AppTheme.accent;
  return AppTheme.danger;
}

String _adherenceMessage(double value) {
  if (value >= 0.8) {
    return 'Great consistency. Keep following your medication schedule.';
  }
  if (value >= 0.5) {
    return 'You are making progress. Try to reduce missed or pending doses.';
  }
  return 'Your adherence is low. Use reminders and update your intake status.';
}

String _valueFor(List<HealthRecord> records, HealthRecordType type) {
  final record = records.where((item) => item.type == type).firstOrNull;
  return record?.value ?? '-';
}

List<MedicationHistory> _filterHistories(
  List<MedicationHistory> histories,
  _HistoryPeriod period,
) {
  final now = DateTime.now();
  final start = switch (period) {
    _HistoryPeriod.today => DateTime(now.year, now.month, now.day),
    _HistoryPeriod.week => now.subtract(const Duration(days: 7)),
    _HistoryPeriod.month => DateTime(now.year, now.month - 1, now.day),
  };

  return histories.where((history) {
    return history.actionAt.isAfter(start) ||
        history.actionAt.isAtSameMomentAs(start);
  }).toList();
}

int _countStatus(List<MedicationHistory> histories, MedicationStatus status) {
  return histories.where((history) => history.status == status).length;
}

String _medicationSuggestion(List<ScheduledMedication> schedules) {
  if (schedules.isEmpty) {
    return 'Add medication reminders so MediCare can prepare adherence reports.';
  }

  final missed = schedules
      .where((item) => item.schedule.status == MedicationStatus.missed)
      .length;
  if (missed > 0) {
    return 'You have $missed missed medication reminder(s). Try to take medicine at the scheduled time.';
  }

  final pending = schedules
      .where((item) => item.schedule.status == MedicationStatus.pending)
      .length;
  if (pending > 0) {
    return 'You have $pending pending medication reminder(s) today.';
  }

  return 'All medication reminders are updated. Good job keeping your records complete.';
}

String _healthSuggestion(HealthRecord record) {
  switch (record.type) {
    case HealthRecordType.bmi:
      final bmi = double.tryParse(record.value) ?? 0;
      if (bmi < 18.5) {
        return 'BMI: Your BMI is low. Try to eat balanced meals and maintain a healthy lifestyle.';
      }
      if (bmi <= 24.9) {
        return 'BMI: Great! Your BMI is healthy. Keep eating balanced meals and stay active.';
      }
      if (bmi <= 29.9) {
        return 'BMI: Your BMI is above the healthy range. Try to control your diet and exercise regularly.';
      }
      return 'BMI: Your BMI is high. Consider meal planning, exercise, and professional advice if needed.';
    case HealthRecordType.bloodSugar:
      final sugar = double.tryParse(record.value) ?? 0;
      if (sugar < 4.0) {
        return 'Blood sugar: Low reading. Eat or drink something with sugar and monitor your condition.';
      }
      if (sugar <= 5.5) {
        return 'Blood sugar: Normal reading. Keep maintaining a balanced diet and healthy lifestyle.';
      }
      if (sugar <= 6.9) {
        return 'Blood sugar: Slightly high. Reduce sugary foods and exercise regularly.';
      }
      return 'Blood sugar: High reading. Monitor your diet and consult a healthcare professional if it remains high.';
    case HealthRecordType.bloodPressure:
      final parts = record.value.split('/');
      final systolic = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
      final diastolic = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      if (systolic < 90 || diastolic < 60) {
        return 'Blood pressure: Low reading. Stay hydrated and seek medical advice if you feel dizzy or weak.';
      }
      if (systolic <= 119 && diastolic <= 79) {
        return 'Blood pressure: Normal reading. Keep maintaining a healthy lifestyle.';
      }
      if (systolic <= 139 && diastolic <= 89) {
        return 'Blood pressure: Slightly high. Reduce salt intake and exercise regularly.';
      }
      return 'Blood pressure: High reading. Monitor it regularly and consult a healthcare professional if needed.';
  }
}
