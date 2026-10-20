class Project {
  Project({
    required this.name,
    required this.code,
    this.lead = '',
    this.startDate,
    this.notes = '',
  });

  String name;
  String code;
  String lead;
  DateTime? startDate;
  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'lead': lead,
        'startDate': startDate?.toIso8601String(),
        'notes': notes,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        lead: json['lead'] as String? ?? '',
        startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
      );
}
