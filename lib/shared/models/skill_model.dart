final class Skill {
  final String id;
  final String name;

  const Skill({required this.id, required this.name});

  factory Skill.fromMap(String id, Map<String, dynamic> map) {
    return Skill(id: id, name: map['name'] as String? ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
