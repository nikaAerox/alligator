import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/medication_schedule.dart';
import '../../core/state/medication_store.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = context.watch<MedicationStore>().scheduledMedications;

    return Stack(
      children: [
        schedules.isEmpty
            ? const _EmptyScheduleState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
                itemBuilder: (context, index) {
                  return _ScheduleCard(item: schedules[index]);
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: schedules.length,
              ),
        Positioned(
          right: 16,
          bottom: 18,
          child: PressableScale(
            child: FloatingActionButton.extended(
              heroTag: 'schedule_add_button',
              onPressed: () => _openScheduleForm(context),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
              icon: const Icon(Icons.alarm_add),
              label: const Text('Reminder'),
            ),
          ),
        ),
      ],
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
      color: const Color(0xFFFCF6ED),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD6CDC0)),
      ),
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
                value: _ScheduleAction.pending,
                child: _ScheduleMenuPill(label: 'Set pending'),
              ),
              PopupMenuItem(
                value: _ScheduleAction.delete,
                child: _ScheduleMenuPill(label: 'Delete'),
              ),
            ],
            child: _StatusChip(status: schedule.status),
          ),
        ),
      ),
    );
  }
}

class _ScheduleMenuPill extends StatelessWidget {
  const _ScheduleMenuPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.button,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 146,
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
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
          PressableScale(
            child: OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule),
              label: Text('Time: ${_time.format(context)}'),
            ),
          ),
          const SizedBox(height: 22),
          PressableScale(
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.alarm_add),
              label: const Text('Add Reminder'),
            ),
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

enum _ScheduleAction { pending, delete }
