import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import 'admin_form_section.dart';
import 'dynamic_list_field.dart';

class HackathonForm extends StatefulWidget {
  final HackathonModel? initial;
  final String submitLabel;
  final Future<void> Function(HackathonModel draft, XFile? banner) onSubmit;

  const HackathonForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<HackathonForm> createState() => _HackathonFormState();
}

class _HackathonFormState extends State<HackathonForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _websiteController;
  late final TextEditingController _registrationFormUrlController;
  late final TextEditingController _minTeamController;
  late final TextEditingController _maxTeamController;
  late final TextEditingController _tagsController;

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _registrationDeadline;
  late HackathonStatus _status;

  late List<TextEditingController> _prizeControllers;
  late List<TextEditingController> _ruleControllers;

  XFile? _pickedBanner;

  @override
  void initState() {
    super.initState();
    final source = widget.initial;
    final now = DateTime.now();

    _titleController = TextEditingController(text: source?.title ?? '');
    _descriptionController = TextEditingController(text: source?.description ?? '');
    _venueController = TextEditingController(text: source?.venue ?? '');
    _websiteController = TextEditingController(text: source?.website ?? '');
    _registrationFormUrlController = TextEditingController(text: source?.registrationFormUrl ?? '');
    _minTeamController = TextEditingController(
      text: (source?.minTeamSize ?? 2).toString(),
    );
    _maxTeamController = TextEditingController(
      text: (source?.maxTeamSize ?? 4).toString(),
    );
    _tagsController = TextEditingController(text: (source?.tags ?? <String>[]).join(', '));

    _startDate = source?.startDate ?? now.add(const Duration(days: 7));
    _endDate = source?.endDate ?? now.add(const Duration(days: 9));
    _registrationDeadline =
        source?.registrationDeadline ?? now.add(const Duration(days: 6));
    _status = source?.status ?? HackathonStatus.draft;

    final prizes = source?.prizes ?? <String>[''];
    _prizeControllers = prizes
        .map((e) => TextEditingController(text: e))
        .toList();

    final rules = source?.rules ?? <String>[''];
    _ruleControllers = rules
        .map((e) => TextEditingController(text: e))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _websiteController.dispose();
    _registrationFormUrlController.dispose();
    _minTeamController.dispose();
    _maxTeamController.dispose();
    _tagsController.dispose();
    for (final c in _prizeControllers) {
      c.dispose();
    }
    for (final c in _ruleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminFormSection(
            title: 'Basic Info',
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 1000,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<HackathonStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: HackathonStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _status = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          AdminFormSection(
            title: 'Dates & Venue',
            child: Column(
              children: [
                _DateField(
                  label: 'Start Date & Time',
                  value: _startDate,
                  onPick: (value) => setState(() => _startDate = value),
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: 'End Date & Time',
                  value: _endDate,
                  onPick: (value) => setState(() => _endDate = value),
                ),
                const SizedBox(height: 8),
                _DateField(
                  label: 'Registration Deadline',
                  value: _registrationDeadline,
                  onPick: (value) => setState(() => _registrationDeadline = value),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Venue is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _registrationFormUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Google Form URL (Registration)',
                    hintText: 'https://forms.google.com/...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Registration form URL is required';
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          AdminFormSection(
            title: 'Team Settings',
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minTeamController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Team Size',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _maxTeamController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Team Size',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final max = int.tryParse(value ?? '');
                      final min = int.tryParse(_minTeamController.text);
                      if (max == null || max <= 0) {
                        return 'Invalid';
                      }
                      if (min != null && max < min) {
                        return 'Must be >= min';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          AdminFormSection(
            title: 'Prizes & Rules',
            child: Column(
              children: [
                DynamicListField(
                  title: 'Prizes',
                  controllers: _prizeControllers,
                  hintText: 'e.g. Rs. 50,000 + Internship',
                  addLabel: 'Add Prize',
                  required: true,
                  onAdd: () {
                    setState(() {
                      _prizeControllers.add(TextEditingController());
                    });
                  },
                  onRemove: (index) {
                    setState(() {
                      _prizeControllers[index].dispose();
                      _prizeControllers.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 8),
                DynamicListField(
                  title: 'Rules (optional)',
                  controllers: _ruleControllers,
                  hintText: 'e.g. No plagiarism',
                  addLabel: 'Add Rule',
                  onAdd: () {
                    setState(() {
                      _ruleControllers.add(TextEditingController());
                    });
                  },
                  onRemove: (index) {
                    setState(() {
                      _ruleControllers[index].dispose();
                      _ruleControllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
          AdminFormSection(
            title: 'Banner Image (optional)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pickedBanner != null)
                  Text(
                    _pickedBanner!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else if (widget.initial?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.initial!.imageUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      setState(() {
                        _pickedBanner = file;
                      });
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Pick Banner'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: provider.isSubmitting ? null : _submit,
            child: provider.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_endDate.isAfter(_startDate)) {
      context.showSnackBar('End date must be after start date.', isError: true);
      return;
    }

    if (!_registrationDeadline.isBefore(_startDate)) {
      context.showSnackBar(
        'Registration deadline must be before start date.',
        isError: true,
      );
      return;
    }

    final minTeam = int.tryParse(_minTeamController.text.trim()) ?? 2;
    final maxTeam = int.tryParse(_maxTeamController.text.trim()) ?? 4;

    final existing = widget.initial;

    final model = HackathonModel(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: existing?.imageUrl,
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _registrationDeadline,
      minTeamSize: minTeam,
      maxTeamSize: maxTeam,
      venue: _venueController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      registrationFormUrl: _registrationFormUrlController.text.trim(),
      prizes: _prizeControllers
          .map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList(),
      isActive: _status == HackathonStatus.published ||
          _status == HackathonStatus.ongoing,
      createdAt: existing?.createdAt ?? DateTime.now(),
      rules: _ruleControllers
          .map((c) => c.text.trim())
          .where((v) => v.isNotEmpty)
          .toList(),
      createdByAdminId: existing?.createdByAdminId ?? '',
      lastEditedByAdminId: existing?.lastEditedByAdminId,
      lastEditedAt: existing?.lastEditedAt,
      isDeleted: existing?.isDeleted ?? false,
      deletedAt: existing?.deletedAt,
      tags: _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
      status: _status,
    );

    await widget.onSubmit(model, _pickedBanner);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) {
          return;
        }

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) {
          return;
        }

        onPick(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value.formattedDateTime),
      ),
    );
  }
}
