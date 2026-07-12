import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../shared/providers/pagination_provider.dart';
import '../../startups/providers/startup_providers.dart';

final applicantPageLimitProvider = NotifierProvider<PageLimitNotifier, int>(PageLimitNotifier.new);

final startupApplicantsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);
  return startupApplicationsStream(user.uid, startupDocId: user.startupId);
});

final class StartupApplicantsScreen extends ConsumerWidget {
  const StartupApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(startupApplicantsProvider);
    final limit = ref.watch(applicantPageLimitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: applications.when(
        loading: () => const LoadingShimmer(),
        error: (_, __) => const AppErrorWidget(message: 'Failed to load applicants'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No applicants found',
              subtitle: 'Nobody has applied for any position at your organization yet',
            );
          }

          final grouped = _groupByOpportunity(list);
          final display = grouped.take(limit).toList();
          final hasMore = limit < grouped.length;

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: _totalItemCount(display, hasMore),
            itemBuilder: (_, i) {
              if (hasMore && _isLastIndex(i, display)) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(applicantPageLimitProvider.notifier).loadMore();
                      },
                      child: const Text('Load more'),
                    ),
                  ),
                );
              }

              final section = display[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OpportunityHeader(title: section.title),
                  const SizedBox(height: 8),
                  ...section.applications.map((app) => _ApplicantCard(application: app)),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }

  int _totalItemCount(List<_OpportunitySection> display, bool hasMore) {
    return display.length + (hasMore ? 1 : 0);
  }

  bool _isLastIndex(int index, List<_OpportunitySection> display) {
    return index == display.length;
  }

  List<_OpportunitySection> _groupByOpportunity(List<Map<String, dynamic>> list) {
    final map = <String, _OpportunitySection>{};
    for (final app in list) {
      final id = app['opportunityId'] as String? ?? '';
      final title = app['opportunityTitle'] as String? ?? 'Opportunity';
      map.putIfAbsent(id, () => _OpportunitySection(title: title, applications: []))
          .applications
          .add(app);
    }
    return map.values.toList();
  }
}

final class _OpportunitySection {
  final String title;
  final List<Map<String, dynamic>> applications;

  _OpportunitySection({required this.title, required this.applications});
}

final class _OpportunityHeader extends StatelessWidget {
  final String title;

  const _OpportunityHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.work_outline, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleSm.copyWith(color: AppColors.accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

final class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicantCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final (bg, text) = AppColors.statusColors(application['status'] as String? ?? '');

    return GestureDetector(
      onTap: () => context.push('/applications/${application['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accent.withAlpha(30),
              child: Text(
                (application['studentName'] as String? ?? 'A')[0].toUpperCase(),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application['studentName'] as String? ?? 'Applicant',
                    style: AppTextStyles.titleXs,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${_formatDate((application['createdAt'] as Timestamp?)?.toDate())}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                (application['status'] as String? ?? 'pending').toUpperCase(),
                style: AppTextStyles.labelXsBold.copyWith(color: text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
