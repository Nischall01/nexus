class Person {
  Person({required this.name, required this.field});

  String name;
  String field;

  Map<String, dynamic> toJson() => {'name': name, 'field': field};

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    name: json['name'] as String? ?? '',
    field: json['field'] as String? ?? '',
  );
}
