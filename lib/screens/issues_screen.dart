import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/issue_store.dart';
import '../data/option_lists.dart';
import '../models/issue.dart';
import 'issue_detail_panel.dart';
import 'issue_editor.dart';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key, required this.store});

  final IssueStore store;

  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen> {
  String _projectFilter = 'All Projects';
  String _statusFilter = 'All';
  String _search = '';
  Issue? _selected;

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  List<Issue> get _filtered {
    var list = widget.store.issuesFor(project: _projectFilter);
    if (_statusFilter != 'All') {
      list = list.where((i) => i.status == _statusFilter).toList();
    }
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (i) =>
                i.id.toLowerCase().contains(q) ||
                i.title.toLowerCase().contains(q) ||
                i.description.toLowerCase().contains(q) ||
                i.assignedToDisplay.toLowerCase().contains(q),
          )
          .toList();
    }
    list.sort((a, b) => b.dateReported.compareTo(a.dateReported));
    return list;
  }

  Issue? get _selectedLive {
    final id = _selected?.id;
    if (id == null) return null;
    try {
      return widget.store.issues.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addOrEdit({Issue? existing}) async {
    if (widget.store.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a project first (Projects tab)')),
      );
      return;
    }
    final result = await showIssueEditor(
      context,
      projects: widget.store.projects,
      personnel: widget.store.personnel,
      existing: existing,
      nextId: widget.store.nextIssueId,
    );
    if (result == null) return;
    await widget.store.upsertIssue(result, isNew: existing == null);
    setState(() => _selected = result);
  }

  Future<void> _copyLine(Issue issue) async {
    final header = Issue.excelHeaders.join('\t');
    final line = issue.toClipboardLine(dateFormat: _dateFmt.format);
    await Clipboard.setData(ClipboardData(text: '$header\n$line'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${issue.id} to clipboard (TSV)')),
    );
  }

  Color _severityAccent(String severity) {
    return switch (severity) {
      'Critical' => const Color(0xFFB42318),
      'High' => const Color(0xFFB54708),
      'Medium' => const Color(0xFF0874A4),
      'Low' => const Color(0xFF667085),
      _ => const Color(0xFF98A2B3),
    };
  }

  Color _severityFill(String severity, ColorScheme scheme) {
    return switch (severity) {
      'Critical' => const Color(0xFFFEE4E2),
      'High' => const Color(0xFFFFF0E6),
      'Medium' => const Color(0xFFE8F5FA),
      'Low' => scheme.surfaceContainerHighest,
      _ => scheme.surfaceContainerLow,
    };
  }

  (Color bg, Color fg) _statusColors(String status) {
    return switch (status) {
      'New' => (const Color(0xFFEFF4FF), const Color(0xFF3538CD)),
      'Open' => (const Color(0xFFFFF6ED), const Color(0xFFB54708)),
      'In Progress' => (const Color(0xFFEEF4FF), const Color(0xFF175CD3)),
      'In Review' => (const Color(0xFFF4F3FF), const Color(0xFF5925DC)),
      'Ready for QA' => (const Color(0xFFECFDF3), const Color(0xFF067647)),
      'Resolved' => (const Color(0xFFECFDF3), const Color(0xFF027A48)),
      'Closed' => (const Color(0xFFF2F4F7), const Color(0xFF344054)),
      'Reopened' => (const Color(0xFFFEF3F2), const Color(0xFFB42318)),
      "Won't Fix" => (const Color(0xFFF2F4F7), const Color(0xFF667085)),
      _ => (const Color(0xFFF2F4F7), const Color(0xFF667085)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final issues = _filtered;
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedLive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Issue Log',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _addOrEdit(),
                icon: const Icon(Icons.add),
                label: const Text('New Issue'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _projectFilter,
                  items: [
                    const DropdownMenuItem(
                      value: 'All Projects',
                      child: Text('All Projects'),
                    ),
                    ...widget.store.projects.map(
                      (p) =>
                          DropdownMenuItem(value: p.name, child: Text(p.name)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _projectFilter = v ?? 'All Projects'),
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  items: [
                    const DropdownMenuItem(value: 'All', child: Text('All')),
                    ...OptionLists.statuses.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Text(
                '${issues.length} issue${issues.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: selected == null ? 1 : 3,
                child: issues.isEmpty
                    ? const Center(child: Text('No issues match these filters'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 20),
                        itemCount: issues.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final issue = issues[index];
                          final isSelected = selected?.id == issue.id;
                          final accent = _severityAccent(issue.severity);
                          final fill = _severityFill(issue.severity, scheme);
                          final statusColors = _statusColors(issue.status);
                          return Material(
                            color: isSelected
                                ? Color.alphaBlend(
                                    scheme.primary.withValues(alpha: 0.12),
                                    fill,
                                  )
                                : fill,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _selected = issue),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(width: 5, color: accent),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  issue.id,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: accent,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    issue.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                issue.severity,
                                                issue.priority,
                                                if (issue
                                                    .platformDisplay
                                                    .isNotEmpty)
                                                  issue.platformDisplay,
                                                if (issue
                                                    .assignedToDisplay
                                                    .isNotEmpty)
                                                  issue.assignedToDisplay,
                                              ].join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColors.$1,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: statusColors.$2.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            issue.status,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: statusColors.$2,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        switch (value) {
                                          case 'copy':
                                            await _copyLine(issue);
                                          case 'edit':
                                            await _addOrEdit(existing: issue);
                                          case 'delete':
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete issue?',
                                                ),
                                                content: Text(
                                                  'Remove ${issue.id}: ${issue.title}?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await widget.store.deleteIssue(
                                                issue.id,
                                              );
                                              if (_selected?.id == issue.id) {
                                                setState(
                                                  () => _selected = null,
                                                );
                                              }
                                            }
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'copy',
                                          child: Text('Copy line'),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (selected != null) ...[
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: IssueDetailPanel(
                    issue: selected,
                    accent: _severityAccent(selected.severity),
                    fill: _severityFill(selected.severity, scheme),
                    onClose: () => setState(() => _selected = null),
                    onEdit: () => _addOrEdit(existing: selected),
                    onCopy: () => _copyLine(selected),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
