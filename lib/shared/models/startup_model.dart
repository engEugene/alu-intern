import 'package:cloud_firestore/cloud_firestore.dart';

enum StartupStatus { pending, approved, rejected }

final class Startup {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? logo;
  final String? website;
  final List<String> members;
  final StartupStatus status;
  final DateTime? createdAt;

  const Startup({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logo,
    this.website,
    this.members = const [],
    this.status = StartupStatus.pending,
    this.createdAt,
  });

  factory Startup.fromMap(String id, Map<String, dynamic> map) {
    return Startup(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      logo: map['logo'] as String?,
      website: map['website'] as String?,
      members: List<String>.from(map['members'] as List? ?? []),
      status: StartupStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StartupStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'logo': logo,
      'website': website,
      'members': members,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Startup copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? logo,
    String? website,
    List<String>? members,
    StartupStatus? status,
    DateTime? createdAt,
  }) {
    return Startup(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      website: website ?? this.website,
      members: members ?? this.members,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
