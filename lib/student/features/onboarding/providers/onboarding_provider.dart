import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_constants.dart';

final allSkillsProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.skillsCollection)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc['name'] as String).toList());
});

final availableSkillsProvider = Provider<List<String>>((ref) {
  final skills = ref.watch(allSkillsProvider).value ?? [];
  if (skills.isEmpty) {
    return _fallbackSkills;
  }
  return skills;
});

Future<void> addSkillToFirestore(String skillName) async {
  final trimmed = skillName.trim();
  if (trimmed.isEmpty) return;
  final existing = await FirebaseFirestore.instance
      .collection(FirestoreConstants.skillsCollection)
      .where('name', isEqualTo: trimmed)
      .limit(1)
      .get();
  if (existing.docs.isEmpty) {
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.skillsCollection)
        .add({'name': trimmed});
  }
}

const _fallbackSkills = [
  'Flutter', 'React Native', 'React', 'Node.js', 'Python',
  'Django', 'TypeScript', 'JavaScript', 'UI/UX Design',
  'Graphic Design', 'Digital Marketing', 'Content Writing',
  'Data Analysis', 'Machine Learning', 'Project Management',
  'iOS Development', 'Android Development', 'Backend',
  'DevOps', 'Product Management', 'Sales', 'Customer Support',
  'Blockchain', 'AR/VR', 'Video Editing', 'Photography',
];
