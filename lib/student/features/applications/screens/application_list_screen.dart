import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';
import '../../../../shared/providers/pagination_provider.dart';

final applicationPageLimitProvider = NotifierProvider<PageLimitNotifier, int>(PageLimitNotifier.new);

final studentApplicationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);
  final limit = ref.watch(applicationPageLimitProvider);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('studentId', isEqualTo: user.uid)
      .limit(limit)
      .snapshots()
      .map((snap) {
        final docs = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        docs.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        return docs;
      });
});

final class ApplicationListScreen extends ConsumerWidget {
  const ApplicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(studentApplicationsProvider);
    final limit = ref.watch(applicationPageLimitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: _buildBody(applications, context, ref, limit),
    );
  }

  Widget _buildBody(AsyncValue<List<Map<String, dynamic>>> applications, BuildContext context, WidgetRef ref, int limit) {
    final data = applications.asData?.value;
    if (data != null) {
      if (data.isEmpty) {
        return const EmptyState(
          icon: Icons.description_outlined,
          title: 'No applications yet',
          subtitle: 'Apply to opportunities to see them here',
        );
      }

      final display = data.take(limit).toList();
      final hasMore = limit < data.length;

      return ListView.builder(
        padding: AppSpacing.screenPadding,
        itemCount: display.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (hasMore && i == display.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(applicationPageLimitProvider.notifier).loadMore();
                  },
                  child: const Text('Load more'),
                ),
              ),
            );
          }

          final app = display[i];
          final (bg, text) = AppColors.statusColors(app['status'] as String? ?? '');
          final oppId = app['opportunityId'] as String?;
          final status = app['status'] as String? ?? 'pending';

          return GestureDetector(
            onTap: oppId != null
                ? () => context.push('/opportunities/$oppId?status=$status')
                : null,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app['opportunityTitle'] as String? ?? 'Opportunity',
                            style: AppTextStyles.titleXs),
                        const SizedBox(height: 2),
                        Text(app['startupName'] as String? ?? '',
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Submitted ${_formatDate((app['createdAt'] as Timestamp?)?.toDate())}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
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
                      status.toUpperCase(),
                      style: AppTextStyles.labelXsBold.copyWith(color: text),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (applications.hasError) {
      return const AppErrorWidget(message: 'Failed to load applications');
    }

    return const LoadingShimmer();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
