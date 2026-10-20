import 'package:flutter/material.dart';

import '../data/issue_store.dart';
import '../models/person.dart';

class PersonnelScreen extends StatelessWidget {
  const PersonnelScreen({super.key, required this.store});

  final IssueStore store;

  Future<void> _edit(BuildContext context, {Person? existing}) async {
    final result = await showDialog<Person>(
      context: context,
      builder: (context) => _PersonDialog(existing: existing),
    );
    if (result == null) return;
    await store.upsertPerson(result, previousName: existing?.name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Personnel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Dev'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Devs appear in Reported By and Assigned To dropdowns on issues.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: store.personnel.isEmpty
              ? const Center(child: Text('No personnel yet'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: store.personnel.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final person = store.personnel[index];
                    return Card(
                      child: ListTile(
                        title: Text(person.name),
                        subtitle: Text(
                          person.field.isEmpty ? 'No field set' : person.field,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(context, existing: person),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete person?'),
                                    content: Text(
                                      'Remove "${person.name}"? Existing issues keep the name on Reported By / Assigned To.',
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
                                  await store.deletePerson(person.name);
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

class _PersonDialog extends StatefulWidget {
  const _PersonDialog({this.existing});

  final Person? existing;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  late final TextEditingController _name;
  late final TextEditingController _field;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _field = TextEditingController(text: e?.field ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Dev' : 'Edit Dev'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _field,
              decoration: const InputDecoration(
                labelText: 'Field (e.g. Android, QA, Backend)',
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
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              Person(name: name, field: _field.text.trim()),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
