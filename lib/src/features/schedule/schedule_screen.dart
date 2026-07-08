// Schedule page for creating reminders, selecting reminders, and managing reminder status.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/medication_schedule.dart';
import '../../core/state/medication_store.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Stores the IDs of reminders selected by the user.
  final Set<String> _selectedScheduleIds = <String>{};

  // Builds the schedule list, selection controls, and add reminder button.
  @override
  Widget build(BuildContext context) {
    final store = context.watch<MedicationStore>();
    final contentTextColor = _contentTextColor(context);
    final schedules = store.scheduledMedications;
    final selectedSchedules = schedules
        .where((item) => _selectedScheduleIds.contains(item.schedule.id))
        .toList();
    final allSelectedAreDaily =
        selectedSchedules.isNotEmpty &&
        selectedSchedules.every((item) => item.schedule.isDaily);
    final dailyButtonLabel = allSelectedAreDaily
        ? 'Remove Daily'
        : 'Remind Daily';
    final dailyButtonIcon = allSelectedAreDaily
        ? Icons.repeat_on_outlined
        : Icons.repeat;

    return DefaultTextStyle.merge(
      style: TextStyle(color: contentTextColor),
      child: IconTheme.merge(
        data: IconThemeData(color: contentTextColor),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 92),
              child: Column(
                children: [
                  if (_selectedScheduleIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: PressableScale(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (_selectedScheduleIds.isEmpty) {
                              return;
                            }
                            // Marks selected reminders as daily or removes the daily flag.
                            store.setSchedulesDaily(
                              scheduleIds: _selectedScheduleIds,
                              isDaily: !allSelectedAreDaily,
                            );
                            setState(() => _selectedScheduleIds.clear());
                          },
                          icon: Icon(dailyButtonIcon),
                          label: Text(dailyButtonLabel),
                        ),
                      ),
                    ),
                  Expanded(
                    child: schedules.isEmpty
                        ? const _EmptyScheduleState()
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              _selectedScheduleIds.isNotEmpty ? 14 : 14,
                              16,
                              92,
                            ),
                            itemBuilder: (context, index) {
                              final item = schedules[index];
                              return _ScheduleCard(
                                item: item,
                                selected: _selectedScheduleIds.contains(
                                  item.schedule.id,
                                ),
                                onToggleSelected: () {
                                  setState(() {
                                    if (!_selectedScheduleIds.remove(
                                      item.schedule.id,
                                    )) {
                                      _selectedScheduleIds.add(
                                        item.schedule.id,
                                      );
                                    }
                                  });
                                },
                                onEdit: () =>
                                    _openScheduleForm(context, existing: item),
                                onSetPending: () {
                                  store.updateScheduleStatus(
                                    item.schedule.id,
                                    MedicationStatus.pending,
                                  );
                                },
                                onDelete: () {
                                  store.deleteSchedule(item.schedule.id);
                                  setState(
                                    () => _selectedScheduleIds.remove(
                                      item.schedule.id,
                                    ),
                                  );
                                },
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemCount: schedules.length,
                          ),
                  ),
                ],
              ),
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
        ),
      ),
    );
  }

  // Opens the reminder form, or warns the user if no medication exists yet.
  void _openScheduleForm(
    BuildContext context, {
    ScheduledMedication? existing,
  }) {
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
      builder: (_) => ScheduleFormSheet(existing: existing),
    );
  }
}

// Shows one reminder card with action menu and selection checkbox.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.item,
    required this.selected,
    required this.onToggleSelected,
    required this.onEdit,
    required this.onSetPending,
    required this.onDelete,
  });

  final ScheduledMedication item;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEdit;
  final VoidCallback onSetPending;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final schedule = item.schedule;
    final medication = item.medication;
    final textColor = _contentTextColor(context);

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
            style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${medication.name} - ${medication.dosage}',
                style: TextStyle(color: textColor),
              ),
              if (schedule.isDaily)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: _DailyChip(),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: selected ? 'Unselect reminder' : 'Select reminder',
                onPressed: onToggleSelected,
                icon: Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                ),
              ),
              PopupMenuButton<_ScheduleAction>(
                tooltip: 'Schedule actions',
                onSelected: (action) {
                  switch (action) {
                    case _ScheduleAction.edit:
                      onEdit();
                      break;
                    case _ScheduleAction.pending:
                      onSetPending();
                      break;
                    case _ScheduleAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ScheduleAction.edit,
                    child: Center(child: _ScheduleMenuPill(label: 'Edit')),
                  ),
                  PopupMenuItem(
                    value: _ScheduleAction.pending,
                    child: Center(
                      child: _ScheduleMenuPill(label: 'Set pending'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ScheduleAction.delete,
                    child: Center(child: _ScheduleMenuPill(label: 'Delete')),
                  ),
                ],
                child: _StatusChip(status: schedule.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lets the user mark a reminder as daily.
class _DailyChip extends StatelessWidget {
  const _DailyChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Daily'),
      side: BorderSide.none,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
      labelStyle: const TextStyle(
        color: AppTheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// Displays the schedule action menu items.
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

// Shows the status chip for pending, taken, postponed, or missed.
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

// Empty state when no reminders are saved.
class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    final textColor = _contentTextColor(context);
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create reminder times for your medications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Form sheet for adding or editing a reminder.
class ScheduleFormSheet extends StatefulWidget {
  const ScheduleFormSheet({super.key, this.existing});

  final ScheduledMedication? existing;

  @override
  State<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<ScheduleFormSheet> {
  String? _medicationId;
  late TimeOfDay _time;

  // Loads the selected medication and time for editing.
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _medicationId = existing?.medication.id ?? existing?.schedule.medicationId;
    final initialMinutes = existing?.schedule.timeInMinutes ?? 8 * 60;
    _time = TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    final medications = context.watch<MedicationStore>().medications;
    _medicationId ??= medications.firstOrNull?.id;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Reminder' : 'Add Reminder',
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
              label: Text('Time: ${_displayTime()}'),
            ),
          ),
          const SizedBox(height: 22),
          PressableScale(
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(isEditing ? Icons.save : Icons.alarm_add),
              label: Text(isEditing ? 'Update Reminder' : 'Add Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  // Returns a readable 12-hour time string.
  String _displayTime() {
    final hour = _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod;
    final minute = _time.minute.toString().padLeft(2, '0');
    final period = _time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Opens the time picker and updates the selected time.
  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  // Saves a new reminder or updates the existing reminder.
  void _save() {
    final medicationId = _medicationId;
    if (medicationId == null) {
      return;
    }

    final store = context.read<MedicationStore>();
    final timeInMinutes = _time.hour * 60 + _time.minute;

    if (widget.existing == null) {
      store.addSchedule(
        medicationId: medicationId,
        timeInMinutes: timeInMinutes,
      );
    } else {
      store.updateScheduleDetails(
        scheduleId: widget.existing!.schedule.id,
        medicationId: medicationId,
        timeInMinutes: timeInMinutes,
      );
    }

    Navigator.of(context).pop();
  }
}

enum _ScheduleAction { edit, pending, delete }

Color _contentTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : AppTheme.ink;
}
