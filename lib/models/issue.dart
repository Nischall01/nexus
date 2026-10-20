class Issue {
  Issue({
    required this.id,
    required this.project,
    required this.title,
    this.description = '',
    this.module = '',
    List<String>? platform,
    this.type = '',
    this.severity = '',
    this.priority = '',
    this.status = 'New',
    this.stepsToReproduce = '',
    this.expectedResult = '',
    this.actualResult = '',
    this.appVersion = '',
    this.deviceOs = '',
    this.reportedBy = '',
    List<String>? assignedTo,
    DateTime? dateReported,
    this.targetDate,
    this.dateResolved,
    this.fixedInVersion = '',
    this.notes = '',
  }) : platform = platform ?? const [],
       assignedTo = assignedTo ?? const [],
       dateReported = dateReported ?? DateTime.now();

  static const listSeparator = ' | ';

  /// Kept for older call sites.
  static const assigneeSeparator = listSeparator;

  String id;
  String project;
  String title;
  String description;
  String module;
  List<String> platform;
  String type;
  String severity;
  String priority;
  String status;
  String stepsToReproduce;
  String expectedResult;
  String actualResult;
  String appVersion;
  String deviceOs;
  String reportedBy;
  List<String> assignedTo;

  String get platformDisplay => platform.join(listSeparator);
  String get assignedToDisplay => assignedTo.join(listSeparator);

  static List<String> parseList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    // Prefer explicit separator; fall back to comma for older single values.
    final parts = raw.contains(listSeparator)
        ? raw.split(listSeparator)
        : (raw.contains(',') ? raw.split(',') : [raw]);
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<String> parseAssignees(String? raw) => parseList(raw);

  static List<String> _stringListFromJson(Object? raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return parseList(raw as String?);
  }

  DateTime dateReported;
  DateTime? targetDate;
  DateTime? dateResolved;
  String fixedInVersion;
  String notes;

  static const resolvedStatuses = {'Resolved', 'Closed', "Won't Fix"};

  bool get isOpen => !resolvedStatuses.contains(status);

  int get daysOpen {
    final end = dateResolved ?? DateTime.now();
    return end.difference(dateReported).inDays;
  }

  bool get isOverdue {
    if (!isOpen || targetDate == null) return false;
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final due = DateTime(targetDate!.year, targetDate!.month, targetDate!.day);
    return t.isAfter(due);
  }

  Issue copyWith({
    String? id,
    String? project,
    String? title,
    String? description,
    String? module,
    List<String>? platform,
    String? type,
    String? severity,
    String? priority,
    String? status,
    String? stepsToReproduce,
    String? expectedResult,
    String? actualResult,
    String? appVersion,
    String? deviceOs,
    String? reportedBy,
    List<String>? assignedTo,
    DateTime? dateReported,
    DateTime? targetDate,
    DateTime? dateResolved,
    bool clearTargetDate = false,
    bool clearDateResolved = false,
    String? fixedInVersion,
    String? notes,
  }) {
    return Issue(
      id: id ?? this.id,
      project: project ?? this.project,
      title: title ?? this.title,
      description: description ?? this.description,
      module: module ?? this.module,
      platform: platform ?? this.platform,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      stepsToReproduce: stepsToReproduce ?? this.stepsToReproduce,
      expectedResult: expectedResult ?? this.expectedResult,
      actualResult: actualResult ?? this.actualResult,
      appVersion: appVersion ?? this.appVersion,
      deviceOs: deviceOs ?? this.deviceOs,
      reportedBy: reportedBy ?? this.reportedBy,
      assignedTo: assignedTo ?? this.assignedTo,
      dateReported: dateReported ?? this.dateReported,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      dateResolved: clearDateResolved
          ? null
          : (dateResolved ?? this.dateResolved),
      fixedInVersion: fixedInVersion ?? this.fixedInVersion,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project': project,
    'title': title,
    'description': description,
    'module': module,
    'platform': platform,
    'type': type,
    'severity': severity,
    'priority': priority,
    'status': status,
    'stepsToReproduce': stepsToReproduce,
    'expectedResult': expectedResult,
    'actualResult': actualResult,
    'appVersion': appVersion,
    'deviceOs': deviceOs,
    'reportedBy': reportedBy,
    'assignedTo': assignedTo,
    'dateReported': dateReported.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'dateResolved': dateResolved?.toIso8601String(),
    'fixedInVersion': fixedInVersion,
    'notes': notes,
  };

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: json['id'] as String? ?? '',
    project: json['project'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    module: json['module'] as String? ?? '',
    platform: _stringListFromJson(json['platform']),
    type: json['type'] as String? ?? '',
    severity: json['severity'] as String? ?? '',
    priority: json['priority'] as String? ?? '',
    status: json['status'] as String? ?? 'New',
    stepsToReproduce: json['stepsToReproduce'] as String? ?? '',
    expectedResult: json['expectedResult'] as String? ?? '',
    actualResult: json['actualResult'] as String? ?? '',
    appVersion: json['appVersion'] as String? ?? '',
    deviceOs: json['deviceOs'] as String? ?? '',
    reportedBy: json['reportedBy'] as String? ?? '',
    assignedTo: _stringListFromJson(json['assignedTo']),
    dateReported:
        DateTime.tryParse(json['dateReported'] as String? ?? '') ??
        DateTime.now(),
    targetDate: DateTime.tryParse(json['targetDate'] as String? ?? ''),
    dateResolved: DateTime.tryParse(json['dateResolved'] as String? ?? ''),
    fixedInVersion: json['fixedInVersion'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );

  /// Tab-separated row matching Excel column order (paste into sheets).
  String toClipboardLine({String Function(DateTime d)? dateFormat}) {
    String fmt(DateTime? d) {
      if (d == null) return '';
      if (dateFormat != null) return dateFormat(d);
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    return [
      id,
      project,
      title,
      description,
      module,
      platformDisplay,
      type,
      severity,
      priority,
      status,
      stepsToReproduce,
      expectedResult,
      actualResult,
      appVersion,
      deviceOs,
      reportedBy,
      assignedToDisplay,
      fmt(dateReported),
      fmt(targetDate),
      fmt(dateResolved),
      daysOpen.toString(),
      fixedInVersion,
      notes,
    ].join('\t');
  }

  static const excelHeaders = [
    'ID',
    'Project',
    'Title',
    'Description',
    'Module / Screen',
    'Platform',
    'Type',
    'Severity',
    'Priority',
    'Status',
    'Steps to Reproduce',
    'Expected Result',
    'Actual Result',
    'App Version / Build',
    'Device / OS',
    'Reported By',
    'Assigned To',
    'Date Reported',
    'Target Date',
    'Date Resolved',
    'Days Open',
    'Fixed in Version',
    'Notes / Link',
  ];
}
