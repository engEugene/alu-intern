import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../shared/models/opportunity_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../auth/providers/auth_provider.dart';

final startupOpportunitiesProvider = StreamProvider<List<Opportunity>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .where('startupId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Opportunity.fromMap(doc.id, doc.data()))
          .toList());
});

final startupApplicationCountProvider = StreamProvider<int>((ref) {
  final oppsAsync = ref.watch(startupOpportunitiesProvider);
  final opps = oppsAsync.value ?? [];
  if (opps.isEmpty) return Stream.value(0);

  return Stream.fromFuture(() async {
    int total = 0;
    for (final o in opps) {
      final r = await FirebaseFirestore.instance
          .collection(FirestoreConstants.applicationsCollection)
          .where('opportunityId', isEqualTo: o.id)
          .count()
          .get();
      total += r.count ?? 0;
    }
    return total;
  }());
});

final class StartupDashboardScreen extends ConsumerWidget {
  const StartupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final opportunities = ref.watch(startupOpportunitiesProvider);
    final appCount = ref.watch(startupApplicationCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${user?.displayName ?? 'Startup'}', style: AppTextStyles.headingSm),
              const SizedBox(height: 8),
              Text('Manage your opportunities and applicants',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.work_outline,
                      label: 'Opportunities',
                      value: opportunities.value?.length.toString() ?? '-',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person_outline,
                      label: 'Applicants',
                      value: appCount.value?.toString() ?? '-',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Your Opportunities', style: AppTextStyles.titleXs),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push('/opportunities/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Post New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              opportunities.when(
                loading: () => const LoadingShimmer(itemCount: 2, height: 80),
                error: (e, _) => const AppErrorWidget(message: 'Failed to load'),
                data: (list) {
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.borderCard,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.work_off_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('No opportunities yet', style: AppTextStyles.titleXs),
                          const SizedBox(height: 4),
                          Text('Post your first opportunity to find talent',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.push('/opportunities/create'),
                            child: const Text('Post Opportunity'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: list.map((o) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.borderCard,
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.title, style: AppTextStyles.titleXs),
                                const SizedBox(height: 4),
                                Text('${o.type.name.replaceAll('_', ' ')} ${o.status.name}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: o.status == OpportunityStatus.open
                                  ? AppColors.successBg
                                  : AppColors.failedBg,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              o.status.name.toUpperCase(),
                              style: AppTextStyles.labelXsBold.copyWith(
                                color: o.status == OpportunityStatus.open
                                    ? AppColors.successText
                                    : AppColors.failedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
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
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 28),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.headingSm.copyWith(color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
