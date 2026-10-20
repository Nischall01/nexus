import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../data/option_lists.dart';
import '../models/issue.dart';
import '../models/project.dart';

class ExcelExportService {
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  static Future<String?> export({
    required List<Issue> issues,
    required List<Project> projects,
  }) async {
    final excel = Excel.createExcel();

    _writeIssueLog(excel, issues);
    _writeProjects(excel, projects);
    _writeLists(excel, projects);
    _writeDashboard(excel, issues, projects);

    // Remove default Sheet1 if present and unused.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook');
    }

    final location = await getSaveLocation(
      suggestedName: 'mobile_app_issue_tracker.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (location == null) return null;

    final path = location.path.endsWith('.xlsx')
        ? location.path
        : '${location.path}.xlsx';
    await File(path).writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return path;
  }

  static void _writeIssueLog(Excel excel, List<Issue> issues) {
    final sheet = excel['Issue Log'];
    sheet.appendRow([TextCellValue('Mobile App Issue Tracker')]);
    sheet.appendRow([
      TextCellValue(
        "Exported from Test Record. ID and Days Open are calculated automatically.",
      ),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow(Issue.excelHeaders.map(TextCellValue.new).toList());

    for (final issue in issues) {
      sheet.appendRow([
        TextCellValue(issue.id),
        TextCellValue(issue.project),
        TextCellValue(issue.title),
        TextCellValue(issue.description),
        TextCellValue(issue.module),
        TextCellValue(issue.platformDisplay),
        TextCellValue(issue.type),
        TextCellValue(issue.severity),
        TextCellValue(issue.priority),
        TextCellValue(issue.status),
        TextCellValue(issue.stepsToReproduce),
        TextCellValue(issue.expectedResult),
        TextCellValue(issue.actualResult),
        TextCellValue(issue.appVersion),
        TextCellValue(issue.deviceOs),
        TextCellValue(issue.reportedBy),
        TextCellValue(issue.assignedToDisplay),
        TextCellValue(_dateFmt.format(issue.dateReported)),
        TextCellValue(
          issue.targetDate == null ? '' : _dateFmt.format(issue.targetDate!),
        ),
        TextCellValue(
          issue.dateResolved == null
              ? ''
              : _dateFmt.format(issue.dateResolved!),
        ),
        IntCellValue(issue.daysOpen),
        TextCellValue(issue.fixedInVersion),
        TextCellValue(issue.notes),
      ]);
    }
  }

  static void _writeProjects(Excel excel, List<Project> projects) {
    final sheet = excel['Projects'];
    sheet.appendRow([TextCellValue('Projects')]);
    sheet.appendRow([
      TextCellValue(
        'Add each project here. Its name appears in the Issue Log; Code is the issue ID prefix.',
      ),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Project Name'),
      TextCellValue('Code'),
      TextCellValue('Lead / Owner'),
      TextCellValue('Start Date'),
      TextCellValue('Notes'),
    ]);
    for (final project in projects) {
      sheet.appendRow([
        TextCellValue(project.name),
        TextCellValue(project.code),
        TextCellValue(project.lead),
        TextCellValue(
          project.startDate == null ? '' : _dateFmt.format(project.startDate!),
        ),
        TextCellValue(project.notes),
      ]);
    }
  }

  static void _writeLists(Excel excel, List<Project> projects) {
    final sheet = excel['Lists'];
    sheet.appendRow([
      TextCellValue('Platform'),
      TextCellValue('Type'),
      TextCellValue('Severity'),
      TextCellValue('Priority'),
      TextCellValue('Status'),
      TextCellValue(''),
      TextCellValue('Dashboard selector'),
    ]);

    final maxLen = [
      OptionLists.platforms.length,
      OptionLists.types.length,
      OptionLists.severities.length,
      OptionLists.priorities.length,
      OptionLists.statuses.length,
      projects.length + 1,
    ].reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < maxLen; i++) {
      sheet.appendRow([
        TextCellValue(
          i < OptionLists.platforms.length ? OptionLists.platforms[i] : '',
        ),
        TextCellValue(i < OptionLists.types.length ? OptionLists.types[i] : ''),
        TextCellValue(
          i < OptionLists.severities.length ? OptionLists.severities[i] : '',
        ),
        TextCellValue(
          i < OptionLists.priorities.length ? OptionLists.priorities[i] : '',
        ),
        TextCellValue(
          i < OptionLists.statuses.length ? OptionLists.statuses[i] : '',
        ),
        TextCellValue(''),
        TextCellValue(
          i == 0
              ? 'All Projects'
              : (i - 1 < projects.length ? projects[i - 1].name : ''),
        ),
      ]);
    }
  }

  static void _writeDashboard(
    Excel excel,
    List<Issue> issues,
    List<Project> projects,
  ) {
    final sheet = excel['Dashboard'];
    final open = issues.where((i) => i.isOpen).length;
    final critHigh = issues
        .where(
          (i) => i.isOpen && (i.severity == 'Critical' || i.severity == 'High'),
        )
        .length;
    final overdue = issues.where((i) => i.isOverdue).length;
    final reopened = issues.where((i) => i.status == 'Reopened').length;
    final resolved = issues.where((i) => !i.isOpen).length;
    final rate = issues.isEmpty ? 0.0 : resolved / issues.length;

    sheet.appendRow([TextCellValue('Issue Dashboard')]);
    sheet.appendRow([TextCellValue('Summary snapshot at export time.')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('Key Numbers'), TextCellValue('Count')]);
    sheet.appendRow([
      TextCellValue('Total issues'),
      IntCellValue(issues.length),
    ]);
    sheet.appendRow([
      TextCellValue("Open (not Resolved / Closed / Won't Fix)"),
      IntCellValue(open),
    ]);
    sheet.appendRow([
      TextCellValue('Critical & High still open'),
      IntCellValue(critHigh),
    ]);
    sheet.appendRow([
      TextCellValue('Overdue (past Target Date, unresolved)'),
      IntCellValue(overdue),
    ]);
    sheet.appendRow([TextCellValue('Reopened issues'), IntCellValue(reopened)]);
    sheet.appendRow([TextCellValue('Resolution rate'), DoubleCellValue(rate)]);

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('All Projects Summary'),
      TextCellValue('Total'),
      TextCellValue('Open'),
      TextCellValue('Crit/High Open'),
      TextCellValue('Overdue'),
    ]);
    for (final project in projects) {
      final subset = issues.where((i) => i.project == project.name).toList();
      sheet.appendRow([
        TextCellValue(project.name),
        IntCellValue(subset.length),
        IntCellValue(subset.where((i) => i.isOpen).length),
        IntCellValue(
          subset
              .where(
                (i) =>
                    i.isOpen &&
                    (i.severity == 'Critical' || i.severity == 'High'),
              )
              .length,
        ),
        IntCellValue(subset.where((i) => i.isOverdue).length),
      ]);
    }
  }
}
