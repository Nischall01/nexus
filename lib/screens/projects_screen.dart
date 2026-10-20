import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/issue_store.dart';
import '../models/project.dart';
import '../widgets/date_field.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.store});

  final IssueStore store;

  Future<void> _edit(BuildContext context, {Project? existing}) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => _ProjectDialog(existing: existing),
    );
    if (result == null) return;
    await store.upsertProject(
      result,
      previousName: existing?.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Projects',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Project'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Project names appear in the Issue Log. Codes become the ID prefix (e.g. APP-001).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: store.projects.isEmpty
              ? const Center(child: Text('No projects yet'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: store.projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final project = store.projects[index];
                    return Card(
                      child: ListTile(
                        title: Text('${project.name}  (${project.code})'),
                        subtitle: Text(
                          [
                            if (project.lead.isNotEmpty) 'Lead: ${project.lead}',
                            if (project.startDate != null)
                              'Start: ${fmt.format(project.startDate!)}',
                            if (project.notes.isNotEmpty) project.notes,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _edit(context, existing: project),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete project?'),
                                    content: Text(
                                      'Remove "${project.name}"? Existing issues keep the project name.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await store.deleteProject(project.name);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({this.existing});

  final Project? existing;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _lead;
  late final TextEditingController _notes;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _code = TextEditingController(text: e?.code ?? '');
    _lead = TextEditingController(text: e?.lead ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _startDate = e?.startDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _lead.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Project' : 'Edit Project'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Code (2–5 letters)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lead,
              decoration: const InputDecoration(
                labelText: 'Lead / Owner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Start Date',
              value: _startDate,
              onChanged: (d) => setState(() => _startDate = d),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            final code = _code.text.trim().toUpperCase();
            if (name.isEmpty || code.isEmpty) return;
            Navigator.pop(
              context,
              Project(
                name: name,
                code: code,
                lead: _lead.text.trim(),
                startDate: _startDate,
                notes: _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
