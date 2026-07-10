import 'package:flutter_riverpod/flutter_riverpod.dart';

final availableSkillsProvider = Provider<List<String>>((ref) {
  return [
    'Flutter', 'React Native', 'React', 'Node.js', 'Python',
    'Django', 'TypeScript', 'JavaScript', 'UI/UX Design',
    'Graphic Design', 'Digital Marketing', 'Content Writing',
    'Data Analysis', 'Machine Learning', 'Project Management',
    'iOS Development', 'Android Development', 'Backend',
    'DevOps', 'Product Management', 'Sales', 'Customer Support',
    'Blockchain', 'AR/VR', 'Video Editing', 'Photography',
  ];
});
