import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../opportunities/widgets/opportunity_card.dart';
import '../../bookmarks/providers/bookmark_provider.dart';

final homeOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList());
});

final applicationCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('studentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.length);
});

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final opportunities = ref.watch(homeOpportunitiesProvider);
    final bookmarks = ref.watch(bookmarkIdsProvider);
    final applications = ref.watch(applicationCountProvider);

    final bookmarkCount = bookmarks.asData?.value.length ?? 0;
    final appCount = applications.asData?.value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Hello,', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              Text(user?.displayName?.split(' ').first ?? 'there', style: AppTextStyles.headingXl),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.description_outlined,
                    label: 'Applications',
                    count: appCount,
                    onTap: () => context.go('/applications'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    icon: Icons.bookmark_outline,
                    label: 'Bookmarks',
                    count: bookmarkCount,
                    onTap: () => context.go('/bookmarks'),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              Text('Quick Actions', style: AppTextStyles.titleXs),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.explore_outlined,
                    label: 'Browse\nOpportunities',
                    color: AppColors.accent,
                    onTap: () => context.go('/opportunities'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(
                    icon: Icons.person_outline,
                    label: 'My\nProfile',
                    color: AppColors.info,
                    onTap: () => context.go('/profile'),
                  )),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Opportunities', style: AppTextStyles.titleXs),
                  GestureDetector(
                    onTap: () => context.go('/opportunities'),
                    child: Text('See all', style: AppTextStyles.labelSm.copyWith(color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              opportunities.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _ShimmerPlaceholder(),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text('Could not load opportunities', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.work_off_outlined, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No opportunities yet', style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: list.take(3).map((o) => OpportunityCard(opportunity: o)).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _StatCard({required this.icon, required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text('$count', style: AppTextStyles.displaySm),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

final class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: color.withAlpha(40), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textPrimary, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

final class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ShimmerBlock(),
        SizedBox(height: 12),
        _ShimmerBlock(),
        SizedBox(height: 12),
        _ShimmerBlock(),
      ],
    );
  }
}

final class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accent.withAlpha(60),
        ),
      ),
    );
  }
}
