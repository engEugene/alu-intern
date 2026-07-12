import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/features/auth/providers/auth_provider.dart';

final studentApplicationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreConstants.applicationsCollection)
      .where('studentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final class ApplicationListScreen extends ConsumerWidget {
  const ApplicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(studentApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: _buildBody(applications, ref),
    );
  }

  Widget _buildBody(AsyncValue<List<Map<String, dynamic>>> applications, WidgetRef ref) {
    final data = applications.asData?.value;
    if (data != null) {
      if (data.isEmpty) {
        return const EmptyState(
          icon: Icons.description_outlined,
          title: 'No applications yet',
          subtitle: 'Apply to opportunities to see them here',
        );
      }

      return ListView.builder(
        padding: AppSpacing.screenPadding,
        itemCount: data.length,
        itemBuilder: (_, i) {
          final app = data[i];
          final (bg, text) = AppColors.statusColors(app['status'] as String? ?? '');

          return Container(
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
                    (app['status'] as String? ?? 'pending').toUpperCase(),
                    style: AppTextStyles.labelXsBold.copyWith(color: text),
                  ),
                ),
              ],
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
