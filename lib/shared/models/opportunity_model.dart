import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityType { fullTime, partTime, internship, contract, project }
enum OpportunityStatus { open, closed }

final class Opportunity {
  final String id;
  final String startupId;
  final String startupName;
  final String startupLogo;
  final String title;
  final String description;
  final String category;
  final List<String> skills;
  final OpportunityType type;
  final String? duration;
  final String? location;
  final bool remote;
  final OpportunityStatus status;
  final DateTime? deadline;
  final DateTime? createdAt;

  const Opportunity({
    required this.id,
    required this.startupId,
    this.startupName = '',
    this.startupLogo = '',
    required this.title,
    required this.description,
    this.category = '',
    this.skills = const [],
    this.type = OpportunityType.internship,
    this.duration,
    this.location,
    this.remote = false,
    this.status = OpportunityStatus.open,
    this.deadline,
    this.createdAt,
  });

  factory Opportunity.fromMap(String id, Map<String, dynamic> map) {
    return Opportunity(
      id: id,
      startupId: map['startupId'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      startupLogo: map['startupLogo'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      skills: List<String>.from(map['skills'] as List? ?? []),
      type: OpportunityType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => OpportunityType.internship,
      ),
      duration: map['duration'] as String?,
      location: map['location'] as String?,
      remote: map['remote'] as bool? ?? false,
      status: OpportunityStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => OpportunityStatus.open,
      ),
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'startupLogo': startupLogo,
      'title': title,
      'description': description,
      'category': category,
      'skills': skills,
      'type': type.name,
      'duration': duration,
      'location': location,
      'remote': remote,
      'status': status.name,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
