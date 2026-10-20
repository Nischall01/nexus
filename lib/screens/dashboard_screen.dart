import 'package:flutter/material.dart';

import '../data/issue_store.dart';
import '../data/option_lists.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store});

  final IssueStore store;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'All Projects';

  @override
  Widget build(BuildContext context) {
    final issues = widget.store.issuesFor(project: _filter);
    final projects = widget.store.projects;
    final scheme = Theme.of(context).colorScheme;

    final open = issues.where((i) => i.isOpen).length;
    final critHigh = issues
        .where(
          (i) => i.isOpen && (i.severity == 'Critical' || i.severity == 'High'),
        )
        .length;
    final overdue = issues.where((i) => i.isOverdue).length;
    final reopened = issues.where((i) => i.status == 'Reopened').length;
    final resolved = issues.where((i) => !i.isOpen).length;
    final avgDays = () {
      final done = issues
          .where((i) => i.dateResolved != null)
          .map((i) => i.dateResolved!.difference(i.dateReported).inDays)
          .toList();
      if (done.isEmpty) return 0.0;
      return done.reduce((a, b) => a + b) / done.length;
    }();
    final rate = issues.isEmpty ? 0.0 : resolved / issues.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _filter,
                items: [
                  const DropdownMenuItem(
                    value: 'All Projects',
                    child: Text('All Projects'),
                  ),
                  ...projects.map(
                    (p) => DropdownMenuItem(value: p.name, child: Text(p.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'All Projects'),
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'Total issues',
              value: '${issues.length}',
              color: scheme.primaryContainer,
            ),
            _StatCard(
              label: 'Open',
              value: '$open',
              color: scheme.secondaryContainer,
            ),
            _StatCard(
              label: 'Crit / High open',
              value: '$critHigh',
              color: scheme.errorContainer,
            ),
            _StatCard(
              label: 'Overdue',
              value: '$overdue',
              color: scheme.tertiaryContainer,
            ),
            _StatCard(
              label: 'Reopened',
              value: '$reopened',
              color: scheme.surfaceContainerHighest,
            ),
            _StatCard(
              label: 'Avg days to resolve',
              value: avgDays.toStringAsFixed(1),
              color: scheme.surfaceContainerHighest,
            ),
            _StatCard(
              label: 'Resolution rate',
              value: '${(rate * 100).toStringAsFixed(0)}%',
              color: scheme.primaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CountTable(
                title: 'By Status',
                rows: {
                  for (final s in OptionLists.statuses)
                    s: issues.where((i) => i.status == s).length,
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _CountTable(
                title: 'By Severity',
                rows: {
                  for (final s in OptionLists.severities)
                    s: issues.where((i) => i.severity == s).length,
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _CountTable(
                title: 'By Platform',
                rows: {
                  for (final s in OptionLists.platforms)
                    s: issues.where((i) => i.platform.contains(s)).length,
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _CountTable(
                title: 'By Priority',
                rows: {
                  for (final s in OptionLists.priorities)
                    s: issues.where((i) => i.priority == s).length,
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'All Projects Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Total'), numeric: true),
                DataColumn(label: Text('Open'), numeric: true),
                DataColumn(label: Text('Crit/High Open'), numeric: true),
                DataColumn(label: Text('Overdue'), numeric: true),
                DataColumn(label: Text('Resolved %'), numeric: true),
              ],
              rows: [
                for (final project in projects)
                  () {
                    final subset = widget.store.issues
                        .where((i) => i.project == project.name)
                        .toList();
                    final openN = subset.where((i) => i.isOpen).length;
                    final critN = subset
                        .where(
                          (i) =>
                              i.isOpen &&
                              (i.severity == 'Critical' ||
                                  i.severity == 'High'),
                        )
                        .length;
                    final overdueN = subset.where((i) => i.isOverdue).length;
                    final resolvedPct = subset.isEmpty
                        ? 0
                        : ((subset.where((i) => !i.isOpen).length /
                                      subset.length) *
                                  100)
                              .round();
                    return DataRow(
                      cells: [
                        DataCell(Text(project.name)),
                        DataCell(Text('${subset.length}')),
                        DataCell(Text('$openN')),
                        DataCell(Text('$critN')),
                        DataCell(Text('$overdueN')),
                        DataCell(Text('$resolvedPct%')),
                      ],
                    );
                  }(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CountTable extends StatelessWidget {
  const _CountTable({required this.title, required this.rows});

  final String title;
  final Map<String, int> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final entry in rows.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
