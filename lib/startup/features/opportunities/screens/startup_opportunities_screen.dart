import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/opportunity_providers.dart';
import '../../../../shared/widgets/opportunity_card.dart';
import '../widgets/opportunity_create_form.dart';

final class StartupOpportunitiesScreen extends ConsumerWidget {
  const StartupOpportunitiesScreen({super.key});

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.sheetSurface,
                borderRadius: AppRadius.sheetRadius,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: AppSpacing.screenPadding.copyWith(
                        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                      ),
                      child: OpportunityCreateForm(
                        onCreated: () {
                          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(startupOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: AppSpacing.screenPadding.copyWith(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your job postings',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Job'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: AppTextStyles.buttonSm,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: opportunities.when(
                loading: () => const LoadingShimmer(),
                error: (e, _) => AppErrorWidget(
                  message: 'Failed to load opportunities',
                  onRetry: () => ref.invalidate(startupOpportunitiesProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.work_off_outlined,
                      title: 'No opportunities yet',
                      subtitle: 'Tap "Create Job" to post your first opportunity',
                      action: FilledButton.icon(
                        onPressed: () => _showCreateSheet(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Job'),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: AppSpacing.screenH,
                    itemCount: list.length,
                    itemBuilder: (_, i) => OpportunityCard(opportunity: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
