import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/models/opportunity_model.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../bookmarks/providers/bookmark_provider.dart';

final opportunityDetailProvider = FutureProvider.family<Opportunity?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance
      .collection(FirestoreConstants.opportunitiesCollection)
      .doc(id)
      .get();
  if (!doc.exists) return null;
  return Opportunity.fromMap(doc.id, doc.data()!);
});

final class OpportunityDetailScreen extends ConsumerWidget {
  final String id;
  final String? applicationStatus;
  const OpportunityDetailScreen({super.key, required this.id, this.applicationStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunity = ref.watch(opportunityDetailProvider(id));
    final user = ref.watch(authProvider).user;
    final isBookmarked = ref.watch(isBookmarkedProvider(id));

    return Scaffold(
      appBar: AppBarWidget(title: 'Opportunity'),
      body: opportunity.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => AppErrorWidget(message: 'Failed to load opportunity'),
        data: (opp) {
          if (opp == null) {
            return const AppErrorWidget(message: 'Opportunity not found');
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderLg,
                        ),
                        child: Center(
                          child: Text(
                            opp.startupName.isNotEmpty ? opp.startupName[0].toUpperCase() : '?',
                            style: AppTextStyles.headingSm.copyWith(color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opp.startupName, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(opp.title, style: AppTextStyles.titleLg),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _DetailChip(Icons.work_outline, opp.type.name.replaceAll('_', ' ')),
                      if (opp.location != null) ...[
                        const SizedBox(width: 8),
                        _DetailChip(Icons.location_on_outlined, opp.location!),
                      ],
                      if (opp.remote) ...[
                        const SizedBox(width: 8),
                        _DetailChip(Icons.wifi, 'Remote'),
                      ],
                    ],
                  ),
                  if (opp.duration != null) ...[
                    const SizedBox(height: 8),
                    _DetailChip(Icons.timer_outlined, opp.duration!),
                  ],
                  const SizedBox(height: 24),
                  Text('Description', style: AppTextStyles.titleXs),
                  const SizedBox(height: 8),
                  Text(opp.description, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  if (opp.skills.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Skills', style: AppTextStyles.titleXs),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: opp.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentSubtle,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(s, style: AppTextStyles.labelSm.copyWith(color: AppColors.accent)),
                      )).toList(),
                    ),
                  ],
                  if (opp.deadline != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.event, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Text('Deadline: ${_formatDate(opp.deadline!)}', style: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: opportunity.when(
        loading: () => null,
        error: (_, __) => null,
        data: (opp) {
          if (opp == null) return const SizedBox.shrink();
          if (user?.role != UserRole.student) return null;
          return Container(
            padding: AppSpacing.screenPadding.copyWith(top: 12, bottom: 32),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: applicationStatus != null
                ? _buildApplicationStatusBar(applicationStatus!)
                : Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => ref.read(bookmarkProvider.notifier).toggle(opp.id),
                        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                        style: IconButton.styleFrom(
                          backgroundColor: isBookmarked ? AppColors.accent.withAlpha(30) : AppColors.card,
                          foregroundColor: isBookmarked ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/opportunities/${opp.id}/apply'),
                          child: const Text('Apply Now'),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationStatusBar(String status) {
    final (bg, text) = AppColors.statusColors(status);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.borderSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == 'accepted'
                    ? Icons.check_circle_outline
                    : status == 'rejected'
                        ? Icons.cancel_outlined
                        : Icons.access_time,
                size: 18,
                color: text,
              ),
              const SizedBox(width: 8),
              Text(
                status == 'accepted'
                    ? 'Application Accepted'
                    : status == 'rejected'
                        ? 'Application Rejected'
                        : 'Application Pending',
                style: AppTextStyles.labelSm.copyWith(color: text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

final class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
