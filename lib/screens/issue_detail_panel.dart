import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/issue.dart';

class IssueDetailPanel extends StatelessWidget {
  const IssueDetailPanel({
    super.key,
    required this.issue,
    required this.accent,
    required this.fill,
    required this.onClose,
    required this.onEdit,
    required this.onCopy,
  });

  final Issue issue;
  final Color accent;
  final Color fill;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onCopy;

  static final _dateFmt = DateFormat('EEE, MMM d, yyyy');

  String _date(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: fill,
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.id,
                        style: textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: issue.severity, color: accent, emphasized: true),
                _Badge(label: issue.priority, color: scheme.onSurfaceVariant),
                _Badge(label: issue.status, color: scheme.primary),
                if (issue.isOverdue)
                  _Badge(
                    label: 'Overdue',
                    color: scheme.error,
                    emphasized: true,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _Section(
                  title: 'What happened',
                  child: Text(
                    issue.description.isEmpty
                        ? 'No description'
                        : issue.description,
                    style: textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Quick facts',
                  child: Column(
                    children: [
                      _FactRow(label: 'Project', value: issue.project),
                      _FactRow(
                        label: 'Module',
                        value: issue.module.isEmpty ? '—' : issue.module,
                      ),
                      _FactRow(
                        label: 'Platform',
                        value: issue.platformDisplay.isEmpty
                            ? '—'
                            : issue.platformDisplay,
                      ),
                      _FactRow(
                        label: 'Type',
                        value: issue.type.isEmpty ? '—' : issue.type,
                      ),
                      _FactRow(
                        label: 'Reported by',
                        value: issue.reportedBy.isEmpty
                            ? '—'
                            : issue.reportedBy,
                      ),
                      _FactRow(
                        label: 'Assigned to',
                        value: issue.assignedToDisplay.isEmpty
                            ? '—'
                            : issue.assignedToDisplay,
                      ),
                      _FactRow(label: 'Days open', value: '${issue.daysOpen}'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'How to reproduce',
                  child: Text(
                    issue.stepsToReproduce.isEmpty
                        ? 'No steps recorded'
                        : issue.stepsToReproduce,
                    style: textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ResultBox(
                        title: 'Expected',
                        body: issue.expectedResult.isEmpty
                            ? '—'
                            : issue.expectedResult,
                        tone: scheme.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ResultBox(
                        title: 'Actual',
                        body: issue.actualResult.isEmpty
                            ? '—'
                            : issue.actualResult,
                        tone: scheme.errorContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Environment',
                  child: Column(
                    children: [
                      _FactRow(
                        label: 'App version',
                        value: issue.appVersion.isEmpty
                            ? '—'
                            : issue.appVersion,
                      ),
                      _FactRow(
                        label: 'Device / OS',
                        value: issue.deviceOs.isEmpty ? '—' : issue.deviceOs,
                      ),
                      _FactRow(
                        label: 'Fixed in',
                        value: issue.fixedInVersion.isEmpty
                            ? '—'
                            : issue.fixedInVersion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _Section(
                  title: 'Dates',
                  child: Column(
                    children: [
                      _FactRow(
                        label: 'Reported',
                        value: _date(issue.dateReported),
                      ),
                      _FactRow(label: 'Target', value: _date(issue.targetDate)),
                      _FactRow(
                        label: 'Resolved',
                        value: _date(issue.dateResolved),
                      ),
                    ],
                  ),
                ),
                if (issue.notes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _Section(
                    title: 'Notes',
                    child: Text(
                      issue.notes,
                      style: textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: const Text('Copy'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
