import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

final class SelectedSkillsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggle(String skill) {
    if (state.contains(skill)) {
      state = state.where((s) => s != skill).toList();
    } else if (state.length < 10) {
      state = [...state, skill];
    }
  }
}

final selectedSkillsProvider = NotifierProvider<SelectedSkillsNotifier, List<String>>(SelectedSkillsNotifier.new);

final class SkillSelectionScreen extends ConsumerStatefulWidget {
  final bool isStartup;
  const SkillSelectionScreen({super.key, this.isStartup = false});

  @override
  ConsumerState<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

final class _SkillSelectionScreenState extends ConsumerState<SkillSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(availableSkillsProvider);
    final selected = ref.watch(selectedSkillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStartup ? 'Startup Skills' : 'Your Skills'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isStartup ? 'What skills are you looking for?' : 'What are your skills?',
                    style: AppTextStyles.headingSm,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isStartup
                        ? 'Select the skills you need in your team'
                        : 'Select your top skills to get matched with opportunities',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${selected.length} selected',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenH,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) {
                    final isSelected = selected.contains(skill);
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (_) => ref.read(selectedSkillsProvider.notifier).toggle(skill),
                      selectedColor: AppColors.accent.withAlpha(30),
                      checkmarkColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : AppColors.divider,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding.copyWith(top: 16, bottom: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: selected.isEmpty ? null : () => _saveSkills(context),
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSkills(BuildContext context) async {
    final skills = ref.read(selectedSkillsProvider);
    await ref.read(authProvider.notifier).updateUserInFirestore({
      'skills': skills,
      'onboardingComplete': true,
    });
    if (context.mounted) context.go('/');
  }
}
