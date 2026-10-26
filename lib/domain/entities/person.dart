/// An actor, director or series creator, identified by their TMDB person id.
class Person {
  final String id;
  final String name;

  const Person({required this.id, required this.name});

  @override
  bool operator ==(Object other) => other is Person && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Person($id, $name)';
}

/// Converts people to and from the `[{id, name}]` lists stored with library
/// entries.
class PeopleJson {
  const PeopleJson._();

  static List<Map<String, String>> toJson(List<Person> people) => [
    for (final person in people) {'id': person.id, 'name': person.name},
  ];

  /// Skips entries without an id or name, and repeats of the same id.
  static List<Person> fromJson(Object? raw) {
    if (raw is! List) return const [];
    final seen = <String>{};
    final people = <Person>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final id = entry['id'];
      final name = entry['name'];
      final idText = id is num ? '$id' : id;
      if (idText is! String || idText.isEmpty || name is! String || name.isEmpty) continue;
      if (seen.add(idText)) people.add(Person(id: idText, name: name));
    }
    return List.unmodifiable(people);
  }
}
