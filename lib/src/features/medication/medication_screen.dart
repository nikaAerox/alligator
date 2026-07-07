import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/models/medication.dart';
import '../../core/state/medication_store.dart';
import '../../shared/widgets/pressable_scale.dart';
import '../../theme/app_theme.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medications = context.watch<MedicationStore>().medications;
    final contentTextColor = _contentTextColor(context);
    final filteredMedications = medications.where((medication) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return medication.name.toLowerCase().contains(query) ||
          medication.dosage.toLowerCase().contains(query) ||
          medication.quantity.toLowerCase().contains(query);
    }).toList();

    return DefaultTextStyle.merge(
      style: TextStyle(color: contentTextColor),
      child: IconTheme.merge(
        data: IconThemeData(color: contentTextColor),
        child: Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _MedicationSearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                  );
                }

                if (filteredMedications.isEmpty) {
                  return _query.trim().isEmpty
                      ? const _EmptyMedicationState()
                      : const _NoSearchResultsState();
                }

                return _MedicationCard(
                  medication: filteredMedications[index - 1],
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemCount: filteredMedications.isEmpty
                  ? 2
                  : filteredMedications.length + 1,
            ),
            Positioned(
              right: 16,
              bottom: 18,
              child: PressableScale(
                child: FloatingActionButton.extended(
                  heroTag: 'medication_add_button',
                  onPressed: _handleAddPressed,
                  extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddPressed() async {
    if (!mounted) {
      return;
    }
    _openMedicationForm(context);
  }

  void _openMedicationForm(BuildContext context, {Medication? medication}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MedicationFormSheet(medication: medication),
    );
  }
}

class _MedicationSearchBar extends StatelessWidget {
  const _MedicationSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final contentTextColor = _contentTextColor(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: contentTextColor),
      cursorColor: contentTextColor,
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search),
        hintStyle: TextStyle(
          color: contentTextColor.withValues(alpha: 0.72),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFCF6ED),
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD6CDC0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MedicineThumbnail(
              name: medication.name,
              imageBytes: medication.imageBytes,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      PopupMenuButton<_MedicationAction>(
                        tooltip: 'Medication actions',
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) {
                          switch (action) {
                            case _MedicationAction.edit:
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => MedicationFormSheet(
                                  medication: medication,
                                ),
                              );
                              break;
                            case _MedicationAction.delete:
                              _confirmDelete(context, medication);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _MedicationAction.edit,
                            child: _MenuPill(label: 'Edit'),
                          ),
                          PopupMenuItem(
                            value: _MedicationAction.delete,
                            child: _MenuPill(label: 'Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _MedicationDetail(label: 'Dosage', value: medication.dosage),
                  _MedicationDetail(
                    label: 'Quantity',
                    value: medication.quantity.isEmpty
                        ? '-'
                        : medication.quantity,
                  ),
                  _MedicationDetail(
                    label: 'Duration',
                    value: medication.duration.isEmpty
                        ? '-'
                        : medication.duration,
                  ),
                  _MedicationDetail(
                    label: 'Status',
                    value: medication.isActive ? 'Active' : 'Inactive',
                  ),
                  if (medication.instructions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      medication.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _contentTextColor(context).withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Medication medication,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete medication?'),
          content: Text('${medication.name} will be removed from your list.'),
          actions: [
            PressableScale(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            PressableScale(
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('Delete'),
              ),
            ),
          ],
        );
      },
    );

    if (!context.mounted || shouldDelete != true) {
      return;
    }

    context.read<MedicationStore>().deleteMedication(medication.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${medication.name} deleted')));
  }
}

class _MedicineThumbnail extends StatelessWidget {
  const _MedicineThumbnail({required this.name, this.imageBytes});

  final String name;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 136,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8C1B7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8E8)),
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medication_liquid,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              )
            : Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
      ),
    );
  }
}

class _MedicationDetail extends StatelessWidget {
  const _MedicationDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final contentTextColor = _contentTextColor(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
        style: TextStyle(
          fontSize: 15,
          height: 1.2,
          color: contentTextColor,
        ),
      ),
    );
  }
}

class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.button,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 126,
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

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medication_outlined, size: 64),
            const SizedBox(height: 14),
            const Text(
              'No medications yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medication so MediCare can help track your routine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _contentTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 64),
      child: Center(
        child: Text(
          'No medication found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class MedicationFormSheet extends StatefulWidget {
  const MedicationFormSheet({super.key, this.medication});

  final Medication? medication;

  @override
  State<MedicationFormSheet> createState() => _MedicationFormSheetState();
}

class _MedicationFormSheetState extends State<MedicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _quantityController;
  late final TextEditingController _durationController;
  late final TextEditingController _instructionsController;
  late MedicationTiming _timing;
  late bool _isActive;
  Uint8List? _imageBytes;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    _nameController = TextEditingController(text: medication?.name ?? '');
    _dosageController = TextEditingController(text: medication?.dosage ?? '');
    _quantityController = TextEditingController(
      text: medication?.quantity ?? '',
    );
    _durationController = TextEditingController(
      text: medication?.duration ?? '',
    );
    _instructionsController = TextEditingController(
      text: medication?.instructions ?? '',
    );
    _timing = medication?.timing ?? MedicationTiming.afterMeal;
    _isActive = medication?.isActive ?? true;
    _imageBytes = medication?.imageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
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
                _isEditing ? 'Edit Medication' : 'Add Medication',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Medication name',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dosageController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  prefixIcon: Icon(Icons.straighten),
                  hintText: 'Example: 1 tablet',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  hintText: 'Example: 30 tablets',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.date_range_outlined),
                  hintText: 'Example: 1 Jun - 30 Jun',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MedicationTiming>(
                initialValue: _timing,
                decoration: const InputDecoration(
                  labelText: 'Timing',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: MedicationTiming.values
                    .map(
                      (timing) => DropdownMenuItem(
                        value: timing,
                        child: Text(timing.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _timing = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<bool>(
                initialValue: _isActive,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.toggle_on_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Active')),
                  DropdownMenuItem(value: false, child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _isActive = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              _ImagePickerPanel(
                imageBytes: _imageBytes,
                onPickImage: _pickImage,
                onRemoveImage: _imageBytes == null
                    ? null
                    : () => setState(() => _imageBytes = null),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructionsController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'Example: Take after dinner',
                ),
              ),
              const SizedBox(height: 22),
              PressableScale(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Medication'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final store = context.read<MedicationStore>();
    final medication = widget.medication;
    if (medication == null) {
      store.addMedication(
        name: _nameController.text,
        dosage: _dosageController.text,
        quantity: _quantityController.text,
        duration: _durationController.text,
        timing: _timing,
        instructions: _instructionsController.text,
        isActive: _isActive,
        imageBytes: _imageBytes,
      );
    } else {
      store.updateMedication(
        medication.copyWith(
          name: _nameController.text,
          dosage: _dosageController.text,
          quantity: _quantityController.text,
          duration: _durationController.text,
          timing: _timing,
          instructions: _instructionsController.text,
          isActive: _isActive,
          imageBytes: _imageBytes,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() => _imageBytes = bytes);
  }
}

class _ImagePickerPanel extends StatelessWidget {
  const _ImagePickerPanel({
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E4E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8E8)),
            ),
            child: imageBytes == null
                ? const Icon(Icons.image_outlined, color: AppTheme.primary)
                : Image.memory(imageBytes!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicine image',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PressableScale(
                      child: FilledButton.icon(
                        onPressed: onPickImage,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(imageBytes == null ? 'Choose' : 'Change'),
                      ),
                    ),
                    if (onRemoveImage != null)
                      PressableScale(
                        child: OutlinedButton.icon(
                          onPressed: onRemoveImage,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MedicationAction { edit, delete }

Color _contentTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : AppTheme.ink;
}
