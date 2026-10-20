import 'package:flutter/material.dart';

import '../data/option_lists.dart';
import '../models/issue.dart';
import '../models/person.dart';
import '../models/project.dart';
import '../widgets/date_field.dart';

Future<Issue?> showIssueEditor(
  BuildContext context, {
  required List<Project> projects,
  required List<Person> personnel,
  Issue? existing,
  required String Function(String projectName) nextId,
}) {
  return showDialog<Issue>(
    context: context,
    barrierDismissible: false,
    builder: (context) => IssueEditorDialog(
      projects: projects,
      personnel: personnel,
      existing: existing,
      nextId: nextId,
    ),
  );
}

class IssueEditorDialog extends StatefulWidget {
  const IssueEditorDialog({
    super.key,
    required this.projects,
    required this.personnel,
    required this.nextId,
    this.existing,
  });

  final List<Project> projects;
  final List<Person> personnel;
  final Issue? existing;
  final String Function(String projectName) nextId;

  @override
  State<IssueEditorDialog> createState() => _IssueEditorDialogState();
}

class _IssueEditorDialogState extends State<IssueEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _module;
  late final TextEditingController _steps;
  late final TextEditingController _expected;
  late final TextEditingController _actual;
  late final TextEditingController _version;
  late final TextEditingController _device;
  late final TextEditingController _fixedIn;
  late final TextEditingController _notes;

  late String _id;
  late String _project;
  late Set<String> _platform;
  late String _type;
  late String _severity;
  late String _priority;
  late String _status;
  late String _reportedBy;
  late Set<String> _assignedTo;
  late DateTime _dateReported;
  DateTime? _targetDate;
  DateTime? _dateResolved;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final defaultProject = widget.projects.isNotEmpty
        ? widget.projects.first.name
        : '';
    _project = e?.project ?? defaultProject;
    _id = e?.id ?? (_project.isEmpty ? '' : widget.nextId(_project));
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _module = TextEditingController(text: e?.module ?? '');
    _steps = TextEditingController(text: e?.stepsToReproduce ?? '');
    _expected = TextEditingController(text: e?.expectedResult ?? '');
    _actual = TextEditingController(text: e?.actualResult ?? '');
    _version = TextEditingController(text: e?.appVersion ?? '');
    _device = TextEditingController(text: e?.deviceOs ?? '');
    _fixedIn = TextEditingController(text: e?.fixedInVersion ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _platform = {
      ...(e?.platform ?? [OptionLists.platforms.first]),
    };
    _type = e?.type ?? OptionLists.types.first;
    _severity = e?.severity ?? OptionLists.severities[2];
    _priority = e?.priority ?? OptionLists.priorities[2];
    _status = e?.status ?? 'New';
    _reportedBy = e?.reportedBy ?? '';
    _assignedTo = {...(e?.assignedTo ?? const <String>[])};
    _dateReported = e?.dateReported ?? DateTime.now();
    _targetDate = e?.targetDate;
    _dateResolved = e?.dateResolved;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _module.dispose();
    _steps.dispose();
    _expected.dispose();
    _actual.dispose();
    _version.dispose();
    _device.dispose();
    _fixedIn.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onProjectChanged(String? value) {
    if (value == null) return;
    setState(() {
      _project = value;
      if (widget.existing == null) {
        _id = widget.nextId(value);
      }
    });
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (_project.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add a project first')));
      return;
    }

    final issue = Issue(
      id: _id,
      project: _project,
      title: _title.text.trim(),
      description: _description.text.trim(),
      module: _module.text.trim(),
      platform: OptionLists.platforms
          .where(_platform.contains)
          .followedBy(
            _platform.where((p) => !OptionLists.platforms.contains(p)),
          )
          .toList(),
      type: _type,
      severity: _severity,
      priority: _priority,
      status: _status,
      stepsToReproduce: _steps.text.trim(),
      expectedResult: _expected.text.trim(),
      actualResult: _actual.text.trim(),
      appVersion: _version.text.trim(),
      deviceOs: _device.text.trim(),
      reportedBy: _reportedBy,
      assignedTo: _assignedTo.toList()..sort(),
      dateReported: _dateReported,
      targetDate: _targetDate,
      dateResolved: _dateResolved,
      fixedInVersion: _fixedIn.text.trim(),
      notes: _notes.text.trim(),
    );
    Navigator.of(context).pop(issue);
  }

  @override
  Widget build(BuildContext context) {
    final projectNames = widget.projects.map((p) => p.name).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'New Issue' : 'Edit Issue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            initialValue: _id,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'ID',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: projectNames.contains(_project)
                                ? _project
                                : null,
                            items: projectNames
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(n),
                                  ),
                                )
                                .toList(),
                            onChanged: _onProjectChanged,
                            decoration: const InputDecoration(
                              labelText: 'Project',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _module,
                      decoration: const InputDecoration(
                        labelText: 'Module / Screen',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _multiChipPicker(
                      label: 'Platform (multiple)',
                      options: OptionLists.platforms,
                      selected: _platform,
                      emptyHint: 'Tap platforms to select',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            'Type',
                            OptionLists.types,
                            _type,
                            (v) => setState(() => _type = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown(
                            'Severity',
                            OptionLists.severities,
                            _severity,
                            (v) => setState(() => _severity = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown(
                            'Priority',
                            OptionLists.priorities,
                            _priority,
                            (v) => setState(() => _priority = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown(
                            'Status',
                            OptionLists.statuses,
                            _status,
                            (v) => setState(() => _status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _steps,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Steps to Reproduce',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expected,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Expected Result',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _actual,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Actual Result',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _version,
                            decoration: const InputDecoration(
                              labelText: 'App Version / Build',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _device,
                            decoration: const InputDecoration(
                              labelText: 'Device / OS',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _personDropdown(
                      label: 'Reported By',
                      value: _reportedBy,
                      onChanged: (v) => setState(() => _reportedBy = v ?? ''),
                    ),
                    const SizedBox(height: 12),
                    _assigneesPicker(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DateField(
                            label: 'Date Reported',
                            value: _dateReported,
                            allowClear: false,
                            onChanged: (d) {
                              if (d != null) {
                                setState(() => _dateReported = d);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DateField(
                            label: 'Target Date',
                            value: _targetDate,
                            onChanged: (d) => setState(() => _targetDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DateField(
                            label: 'Date Resolved',
                            value: _dateResolved,
                            onChanged: (d) => setState(() => _dateResolved = d),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fixedIn,
                            decoration: const InputDecoration(
                              labelText: 'Fixed in Version',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _notes,
                            decoration: const InputDecoration(
                              labelText: 'Notes / Link',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final selected = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      initialValue: selected,
      items: items
          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _personDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final known = widget.personnel.any((p) => p.name == value);

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        ...widget.personnel.map(
          (p) => DropdownMenuItem(
            value: p.name,
            child: Text(p.field.isEmpty ? p.name : '${p.name} (${p.field})'),
          ),
        ),
        if (value.isNotEmpty && !known)
          DropdownMenuItem(value: value, child: Text(value)),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: widget.personnel.isEmpty
            ? 'Add people in the Personnel tab'
            : null,
      ),
    );
  }

  Widget _multiChipPicker({
    required String label,
    required List<String> options,
    required Set<String> selected,
    required String emptyHint,
  }) {
    final orphans = selected.where((v) => !options.contains(v)).toList();
    final all = [...options, ...orphans];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: selected.isEmpty
            ? emptyHint
            : '${selected.length} selected',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in all)
              FilterChip(
                label: Text(option),
                selected: selected.contains(option),
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      selected.add(option);
                    } else {
                      selected.remove(option);
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _assigneesPicker() {
    final orphanNames = _assignedTo
        .where((n) => !widget.personnel.any((p) => p.name == n))
        .toList();
    final people = [
      ...widget.personnel,
      ...orphanNames.map((n) => Person(name: n, field: '')),
    ];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Assigned To (multiple)',
        border: const OutlineInputBorder(),
        isDense: true,
        helperText: widget.personnel.isEmpty
            ? 'Add people in the Personnel tab'
            : _assignedTo.isEmpty
            ? 'Tap names to assign'
            : '${_assignedTo.length} selected',
      ),
      child: people.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('—'),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final person in people)
                    FilterChip(
                      label: Text(
                        person.field.isEmpty
                            ? person.name
                            : '${person.name} (${person.field})',
                      ),
                      selected: _assignedTo.contains(person.name),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _assignedTo.add(person.name);
                          } else {
                            _assignedTo.remove(person.name);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
