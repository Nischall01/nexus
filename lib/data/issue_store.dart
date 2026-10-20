import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/issue.dart';
import '../models/person.dart';
import '../models/project.dart';
import 'database.dart';

class IssueStore extends ChangeNotifier {
  List<Project> projects = [];
  List<Person> personnel = [];
  List<Issue> issues = [];
  bool loaded = false;
  String? get storagePath => AppDatabase.dbPath;

  Database? _db;

  Future<void> load() async {
    _db = await AppDatabase.instance();
    await _reload();

    if (projects.isEmpty && issues.isEmpty) {
      await _seedExample();
      await _reload();
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> _reload() async {
    final db = _db!;
    final projectRows = await db.query(
      'projects',
      orderBy: 'name COLLATE NOCASE',
    );
    final personnelRows = await db.query(
      'personnel',
      orderBy: 'name COLLATE NOCASE',
    );
    final issueRows = await db.query('issues', orderBy: 'date_reported DESC');
    projects = projectRows.map(_projectFromRow).toList();
    personnel = personnelRows.map(_personFromRow).toList();
    issues = issueRows.map(_issueFromRow).toList();
  }

  Future<void> _seedExample() async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.insert('projects', {
        'name': 'My Mobile App',
        'code': 'APP',
        'lead': 'Project Manager',
        'start_date': DateTime(2026, 8, 13).toIso8601String(),
        'notes': 'Example project',
      });
      await txn.insert('personnel', {'name': 'QA Team', 'field': 'QA'});
      await txn.insert('personnel', {'name': 'Dev A', 'field': 'Android'});
      await txn.insert(
        'issues',
        _issueToRow(
          Issue(
            id: 'APP-001',
            project: 'My Mobile App',
            title: 'App crashes on login with Google Sign-In',
            description: 'App closes immediately after selecting a Google account on the login screen.',
            module: 'Login',
            platform: const ['Android'],
            type: 'Crash',
            severity: 'Critical',
            priority: 'P1',
            status: 'Open',
            stepsToReproduce: "1. Open app\n2. Tap 'Sign in with Google'\n3. Choose an account",
            expectedResult: 'User lands on Home screen',
            actualResult: 'App force-closes (NullPointerException)',
            appVersion: '1.2.0 (45)',
            deviceOs: 'Pixel 6 / Android 14',
            reportedBy: 'QA Team',
            assignedTo: const ['Dev A'],
            dateReported: DateTime(2026, 10, 9),
            targetDate: DateTime(2026, 10, 16),
            notes: 'Logcat attached in drive folder',
          ),
        ),
      );
    });
  }

  String nextIssueId(String projectName) {
    final project = projects.cast<Project?>().firstWhere(
      (p) => p?.name == projectName,
      orElse: () => null,
    );
    final code = (project?.code.isNotEmpty == true)
        ? project!.code.toUpperCase()
        : 'ISS';
    var maxN = 0;
    final prefix = '$code-';
    for (final issue in issues) {
      if (!issue.id.startsWith(prefix)) continue;
      final n = int.tryParse(issue.id.substring(prefix.length)) ?? 0;
      if (n > maxN) maxN = n;
    }
    return '$prefix${(maxN + 1).toString().padLeft(3, '0')}';
  }

  Future<void> upsertProject(Project project, {String? previousName}) async {
    final db = _db!;
    await db.transaction((txn) async {
      if (previousName != null && previousName != project.name) {
        await txn.delete(
          'projects',
          where: 'name = ?',
          whereArgs: [previousName],
        );
        await txn.update(
          'issues',
          {'project': project.name},
          where: 'project = ?',
          whereArgs: [previousName],
        );
        await txn.insert('projects', _projectToRow(project));
      } else {
        await txn.insert(
          'projects',
          _projectToRow(project),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    await _reload();
    notifyListeners();
  }

  Future<void> deleteProject(String name) async {
    await _db!.delete('projects', where: 'name = ?', whereArgs: [name]);
    await _reload();
    notifyListeners();
  }

  Future<void> upsertPerson(Person person, {String? previousName}) async {
    final db = _db!;
    await db.transaction((txn) async {
      if (previousName != null && previousName != person.name) {
        await txn.delete(
          'personnel',
          where: 'name = ?',
          whereArgs: [previousName],
        );
        await txn.update(
          'issues',
          {'reported_by': person.name},
          where: 'reported_by = ?',
          whereArgs: [previousName],
        );
        final issueRows = await txn.query('issues');
        for (final row in issueRows) {
          final assignees = Issue.parseAssignees(row['assigned_to'] as String?);
          if (!assignees.contains(previousName)) continue;
          final updated = assignees
              .map((n) => n == previousName ? person.name : n)
              .toList();
          await txn.update(
            'issues',
            {'assigned_to': updated.join(Issue.assigneeSeparator)},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await txn.insert('personnel', _personToRow(person));
      } else {
        await txn.insert(
          'personnel',
          _personToRow(person),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    await _reload();
    notifyListeners();
  }

  Future<void> deletePerson(String name) async {
    await _db!.delete('personnel', where: 'name = ?', whereArgs: [name]);
    await _reload();
    notifyListeners();
  }

  Future<void> upsertIssue(Issue issue, {bool isNew = false}) async {
    if (isNew || !issues.any((i) => i.id == issue.id)) {
      if (issue.id.isEmpty) {
        issue = issue.copyWith(id: nextIssueId(issue.project));
      }
    }
    await _db!.insert(
      'issues',
      _issueToRow(issue),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _reload();
    notifyListeners();
  }

  Future<void> deleteIssue(String id) async {
    await _db!.delete('issues', where: 'id = ?', whereArgs: [id]);
    await _reload();
    notifyListeners();
  }

  List<Issue> issuesFor({String? project}) {
    if (project == null || project == 'All Projects') return List.of(issues);
    return issues.where((i) => i.project == project).toList();
  }

  static Map<String, Object?> _projectToRow(Project project) => {
    'name': project.name,
    'code': project.code,
    'lead': project.lead,
    'start_date': project.startDate?.toIso8601String(),
    'notes': project.notes,
  };

  static Project _projectFromRow(Map<String, Object?> row) => Project(
    name: row['name'] as String? ?? '',
    code: row['code'] as String? ?? '',
    lead: row['lead'] as String? ?? '',
    startDate: DateTime.tryParse(row['start_date'] as String? ?? ''),
    notes: row['notes'] as String? ?? '',
  );

  static Map<String, Object?> _personToRow(Person person) => {
    'name': person.name,
    'field': person.field,
  };

  static Person _personFromRow(Map<String, Object?> row) => Person(
    name: row['name'] as String? ?? '',
    field: row['field'] as String? ?? '',
  );

  static Map<String, Object?> _issueToRow(Issue issue) => {
    'id': issue.id,
    'project': issue.project,
    'title': issue.title,
    'description': issue.description,
    'module': issue.module,
    'platform': issue.platformDisplay,
    'type': issue.type,
    'severity': issue.severity,
    'priority': issue.priority,
    'status': issue.status,
    'steps_to_reproduce': issue.stepsToReproduce,
    'expected_result': issue.expectedResult,
    'actual_result': issue.actualResult,
    'app_version': issue.appVersion,
    'device_os': issue.deviceOs,
    'reported_by': issue.reportedBy,
    'assigned_to': issue.assignedToDisplay,
    'date_reported': issue.dateReported.toIso8601String(),
    'target_date': issue.targetDate?.toIso8601String(),
    'date_resolved': issue.dateResolved?.toIso8601String(),
    'fixed_in_version': issue.fixedInVersion,
    'notes': issue.notes,
  };

  static Issue _issueFromRow(Map<String, Object?> row) => Issue(
    id: row['id'] as String? ?? '',
    project: row['project'] as String? ?? '',
    title: row['title'] as String? ?? '',
    description: row['description'] as String? ?? '',
    module: row['module'] as String? ?? '',
    platform: Issue.parseList(row['platform'] as String?),
    type: row['type'] as String? ?? '',
    severity: row['severity'] as String? ?? '',
    priority: row['priority'] as String? ?? '',
    status: row['status'] as String? ?? 'New',
    stepsToReproduce: row['steps_to_reproduce'] as String? ?? '',
    expectedResult: row['expected_result'] as String? ?? '',
    actualResult: row['actual_result'] as String? ?? '',
    appVersion: row['app_version'] as String? ?? '',
    deviceOs: row['device_os'] as String? ?? '',
    reportedBy: row['reported_by'] as String? ?? '',
    assignedTo: Issue.parseAssignees(row['assigned_to'] as String?),
    dateReported:
        DateTime.tryParse(row['date_reported'] as String? ?? '') ??
        DateTime.now(),
    targetDate: DateTime.tryParse(row['target_date'] as String? ?? ''),
    dateResolved: DateTime.tryParse(row['date_resolved'] as String? ?? ''),
    fixedInVersion: row['fixed_in_version'] as String? ?? '',
    notes: row['notes'] as String? ?? '',
  );
}
