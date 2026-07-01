import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/medication_schedule.dart';
import '../../core/state/medication_store.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = context.watch<MedicationStore>().scheduledMedications;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: schedules.isEmpty
          ? const _EmptyScheduleState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                return _ScheduleCard(item: schedules[index]);
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: schedules.length,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleForm(context),
        icon: const Icon(Icons.alarm_add),
        label: const Text('Reminder'),
      ),
    );
  }

  void _openScheduleForm(BuildContext context) {
    final medications = context.read<MedicationStore>().medications;
    if (medications.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a medication first')));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ScheduleFormSheet(),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final ScheduledMedication item;

  @override
  Widget build(BuildContext context) {
    final schedule = item.schedule;
    final medication = item.medication;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFF2D4),
            child: Icon(
              Icons.notifications_active,
              color: schedule.status == MedicationStatus.taken
                  ? AppTheme.success
                  : const Color(0xFF9A6A00),
            ),
          ),
          title: Text(
            schedule.displayTime,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${medication.name} - ${medication.dosage}'),
          trailing: PopupMenuButton<_ScheduleAction>(
            tooltip: 'Schedule actions',
            onSelected: (action) {
              final store = context.read<MedicationStore>();
              switch (action) {
                case _ScheduleAction.taken:
                  store.updateScheduleStatus(
                    schedule.id,
                    MedicationStatus.taken,
                  );
                case _ScheduleAction.missed:
                  store.updateScheduleStatus(
                    schedule.id,
                    MedicationStatus.missed,
                  );
                case _ScheduleAction.postponed:
                  store.updateScheduleStatus(
                    schedule.id,
                    MedicationStatus.postponed,
                  );
                case _ScheduleAction.pending:
                  store.updateScheduleStatus(
                    schedule.id,
                    MedicationStatus.pending,
                  );
                case _ScheduleAction.delete:
                  store.deleteSchedule(schedule.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ScheduleAction.taken,
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Mark taken'),
                ),
              ),
              PopupMenuItem(
                value: _ScheduleAction.missed,
                child: ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Mark missed'),
                ),
              ),
              PopupMenuItem(
                value: _ScheduleAction.postponed,
                child: ListTile(
                  leading: Icon(Icons.snooze_outlined),
                  title: Text('Postpone'),
                ),
              ),
              PopupMenuItem(
                value: _ScheduleAction.pending,
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Set pending'),
                ),
              ),
              PopupMenuItem(
                value: _ScheduleAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ],
            child: _StatusChip(status: schedule.status),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MedicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MedicationStatus.taken => AppTheme.success,
      MedicationStatus.missed => AppTheme.danger,
      MedicationStatus.postponed => AppTheme.accent,
      MedicationStatus.pending => AppTheme.primary,
    };

    return Chip(
      label: Text(status.label),
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm_outlined, size: 64),
            const SizedBox(height: 14),
            const Text(
              'No reminders yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reminder times for your medications.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleFormSheet extends StatefulWidget {
  const ScheduleFormSheet({super.key});

  @override
  State<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<ScheduleFormSheet> {
  String? _medicationId;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    final medications = context.watch<MedicationStore>().medications;
    _medicationId ??= medications.firstOrNull?.id;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Reminder',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _medicationId,
            decoration: const InputDecoration(
              labelText: 'Medication',
              prefixIcon: Icon(Icons.medication_outlined),
            ),
            items: medications
                .map(
                  (medication) => DropdownMenuItem(
                    value: medication.id,
                    child: Text(medication.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _medicationId = value),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text('Time: ${_time.format(context)}'),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.alarm_add),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  void _save() {
    final medicationId = _medicationId;
    if (medicationId == null) {
      return;
    }

    context.read<MedicationStore>().addSchedule(
      medicationId: medicationId,
      timeInMinutes: _time.hour * 60 + _time.minute,
    );
    Navigator.of(context).pop();
  }
}

enum _ScheduleAction { taken, missed, postponed, pending, delete }
