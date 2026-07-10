import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';

final startupApplicantsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('startupId', isEqualTo: user.uid)
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

final class StartupApplicantsScreen extends ConsumerWidget {
  const StartupApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(startupApplicantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: applications.when(
        loading: () => const LoadingShimmer(),
        error: (_, __) => const AppErrorWidget(message: 'Failed to load applicants'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No applicants yet',
              subtitle: 'Applicants will appear here once students apply to your opportunities',
            );
          }

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: list.length,
            itemBuilder: (_, i) {
              final app = list[i];
              final (bg, text) = AppColors.statusColors(app['status'] as String? ?? '');

              return GestureDetector(
                onTap: () => context.push('/applications/${app['id']}'),
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
                            Text(
                              app['studentName'] as String? ?? 'Applicant',
                              style: AppTextStyles.titleXs,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app['opportunityTitle'] as String? ?? 'Opportunity',
                              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted ${_formatDate((app['createdAt'] as Timestamp?)?.toDate())}',
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
                          (app['status'] as String? ?? 'pending').toUpperCase(),
                          style: AppTextStyles.labelXsBold.copyWith(color: text),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
