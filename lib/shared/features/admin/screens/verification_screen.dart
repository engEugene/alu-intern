import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../models/startup_model.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';

final pendingStartupsProvider = StreamProvider<List<Startup>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreConstants.startupsCollection)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Startup.fromMap(doc.id, doc.data()))
          .toList());
});

final class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startups = ref.watch(pendingStartupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: startups.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => const AppErrorWidget(message: 'Failed to load pending startups'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_outlined,
              title: 'All caught up',
              subtitle: 'No startups pending verification',
            );
          }

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: list.length,
            itemBuilder: (_, i) => _StartupVerificationCard(startup: list[i]),
          );
        },
      ),
    );
  }
}

final class _StartupVerificationCard extends ConsumerWidget {
  final Startup startup;
  const _StartupVerificationCard({required this.startup});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Center(
                  child: Text(
                    startup.name.isNotEmpty ? startup.name[0].toUpperCase() : '?',
                    style: AppTextStyles.titleSm.copyWith(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(startup.name, style: AppTextStyles.titleXs),
                    if (startup.website != null)
                      Text(startup.website!, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pendingBg,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text('PENDING', style: AppTextStyles.labelXsBold.copyWith(color: AppColors.pendingText)),
              ),
            ],
          ),
          if (startup.description != null && startup.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(startup.description!, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmLighter.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'rejected'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'approved'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.startupsCollection)
        .doc(startup.id)
        .update({'status': status});

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${startup.name} $status'),
          backgroundColor: status == 'approved' ? AppColors.success : AppColors.error,
        ));
    }
  }
}
