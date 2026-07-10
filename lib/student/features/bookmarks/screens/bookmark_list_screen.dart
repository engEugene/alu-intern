import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/opportunity_card.dart';
import '../providers/bookmark_provider.dart';

final class BookmarkListScreen extends ConsumerWidget {
  const BookmarkListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkedOpportunitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarks.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => const AppErrorWidget(message: 'Failed to load bookmarks'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No bookmarks yet',
              subtitle: 'Save opportunities to review them later',
            );
          }

          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: list.length,
            itemBuilder: (_, i) => OpportunityCard(opportunity: list[i]),
          );
        },
      ),
    );
  }
}
