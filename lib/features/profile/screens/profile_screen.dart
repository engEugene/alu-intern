import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

final class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.accent.withAlpha(30),
                child: Icon(Icons.person, size: 48, color: AppColors.accent),
              ),
              const SizedBox(height: 16),
              Text(user?.displayName ?? 'User', style: AppTextStyles.headingSm),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(20),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  (user?.role.name ?? 'student').toUpperCase(),
                  style: AppTextStyles.labelXsBold.copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 32),
              if (user?.skills.isNotEmpty == true) ...[
                Align(alignment: Alignment.centerLeft, child: Text('Skills', style: AppTextStyles.titleXs)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: (user?.skills ?? []).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(s, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
